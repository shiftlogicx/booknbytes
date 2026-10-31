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

    // Check caller permission
    // 1. If caller is using the service_role key directly
    const isServiceKey = token === supabaseServiceKey;
    let isAdmin = isServiceKey;

    if (!isAdmin) {
      // 2. Verify JWT user role
      const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(token);
      if (userError || !userData?.user) {
        return new Response(
          JSON.stringify({ error: "Invalid or expired authorization token." }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
        );
      }

      const role = userData.user.app_metadata?.role;
      if (role === "admin") {
        isAdmin = true;
      }
    }

    if (!isAdmin) {
      return new Response(
        JSON.stringify({ error: "Forbidden: Only admin users have permission to activate restaurants." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 403 }
      );
    }

    const body = await req.json().catch(() => null);
    if (!body || !body.restaurant_id) {
      return new Response(
        JSON.stringify({ error: "Missing required parameter: restaurant_id" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const { restaurant_id } = body;

    // Check if restaurant exists
    const { data: existingRest, error: fetchErr } = await supabaseAdmin
      .from("restaurants")
      .select("restaurant_id, name, status, owners_details")
      .eq("restaurant_id", restaurant_id)
      .maybeSingle();

    if (fetchErr || !existingRest) {
      return new Response(
        JSON.stringify({ error: `Restaurant with id '${restaurant_id}' not found.` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 404 }
      );
    }

    // Activate the restaurant - the Postgres trigger handle_restaurant_activation
    // automatically creates the manager user and attaches manager_credentials to owners_details
    const { data: updatedRest, error: updateErr } = await supabaseAdmin
      .from("restaurants")
      .update({ status: "ACTIVE" })
      .eq("restaurant_id", restaurant_id)
      .select("restaurant_id, name, status, owners_details")
      .single();

    if (updateErr) {
      return new Response(
        JSON.stringify({ error: `Failed to activate restaurant: ${updateErr.message}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    const managerCreds = updatedRest.owners_details?.manager_credentials || null;
    const ownerEmail = updatedRest.owners_details?.email || null;

    return new Response(
      JSON.stringify({
        success: true,
        message: "Restaurant activated successfully and manager credentials generated.",
        restaurant: {
          restaurant_id: updatedRest.restaurant_id,
          name: updatedRest.name,
          status: updatedRest.status,
          owner_email: ownerEmail,
          manager_credentials: managerCreds,
        },
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
