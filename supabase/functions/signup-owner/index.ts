import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed. Use POST." }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 405,
      }
    );
  }

  try {
    const body = await req.json().catch(() => null);
    if (!body) {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body provided." }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 400,
        }
      );
    }

    const { email, password, name, owner_name, phone } = body;

    const resolvedName = (owner_name || name || "").trim();
    const resolvedEmail = (email || "").trim().toLowerCase();
    const resolvedPhone = phone ? String(phone).trim() : null;

    // 1. Validation
    if (!resolvedEmail || !resolvedEmail.includes("@")) {
      return new Response(
        JSON.stringify({ error: "A valid email is required." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    if (!password || typeof password !== "string" || password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Password is required and must be at least 6 characters." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    if (!resolvedName) {
      return new Response(
        JSON.stringify({ error: "Name is required." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration error: missing Supabase credentials." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 2. Create Auth user with role 'restaurant_owner' in app_metadata
    const { data: authData, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email: resolvedEmail,
        password,
        email_confirm: true,
        phone: resolvedPhone ?? undefined,
        phone_confirm: resolvedPhone ? true : false,
        user_metadata: {
          name: resolvedName,
          phone: resolvedPhone ?? "",
        },
        app_metadata: {
          role: "restaurant_owner",
        },
      });

    if (authError) {
      return new Response(
        JSON.stringify({ error: authError.message }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const userId = authData.user.id;

    // 3. Ensure profile in public.users is synced
    const { error: profileError } = await supabaseAdmin
      .from("users")
      .upsert({
        user_id: userId,
        name: resolvedName,
        phone_number: resolvedPhone,
        email: resolvedEmail,
        total_bookings: 0,
      });

    if (profileError) {
      console.warn("Notice: public.users upsert warning:", profileError.message);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Restaurant owner account created successfully",
        user: {
          id: userId,
          email: resolvedEmail,
          name: resolvedName,
          phone: resolvedPhone,
          role: "restaurant_owner",
        },
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 201,
      }
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : "Internal server error";
    return new Response(
      JSON.stringify({ error: message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
