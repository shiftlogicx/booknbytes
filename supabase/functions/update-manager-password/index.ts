import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 405 }
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase server configuration." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
      );
    }

    const token = authHeader.replace("Bearer ", "").trim();
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Verify JWT of the caller
    const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
    if (userError || !userData?.user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired authorization token." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
      );
    }

    const caller = userData.user;
    const callerRole = caller.app_metadata?.role;
    const callerRestId = caller.app_metadata?.restaurant_id;

    const body = await req.json().catch(() => null);
    if (!body || !body.new_password) {
      return new Response(
        JSON.stringify({ error: "Missing required field: new_password" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const { new_password, target_manager_id } = body;

    if (typeof new_password !== "string" || new_password.length < 8) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 8 characters long." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    let targetUserId = caller.id;

    // If caller is admin or owner resetting a manager's password
    if (target_manager_id && target_manager_id !== caller.id) {
      if (callerRole !== "admin" && callerRole !== "restaurant_owner") {
        return new Response(
          JSON.stringify({ error: "Forbidden: You are not authorized to reset another user's password." }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 403 }
        );
      }
      targetUserId = target_manager_id;
    }

    // Update password using Supabase Admin Auth
    const { data: updateData, error: updateErr } = await supabaseAdmin.auth.admin.updateUserById(
      targetUserId,
      { password: new_password }
    );

    if (updateErr) {
      return new Response(
        JSON.stringify({ error: `Failed to update password: ${updateErr.message}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    // Explicitly ensure the restaurant's owners_details reflects the updated status
    const restIdToUpdate = callerRestId || updateData.user.app_metadata?.restaurant_id;
    if (restIdToUpdate) {
      const { data: restData } = await supabaseAdmin
        .from("restaurants")
        .select("owners_details")
        .eq("restaurant_id", restIdToUpdate)
        .maybeSingle();

      if (restData && restData.owners_details?.manager_credentials) {
        const updatedDetails = {
          ...restData.owners_details,
          manager_credentials: {
            ...restData.owners_details.manager_credentials,
            default_password: "[PASSWORD_UPDATED]",
            password_updated: true,
            updated_at: new Date().toISOString(),
          },
        };

        await supabaseAdmin
          .from("restaurants")
          .update({ owners_details: updatedDetails })
          .eq("restaurant_id", restIdToUpdate);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Password updated successfully.",
        user_id: targetUserId,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "An unexpected error occurred." }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
