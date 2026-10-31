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
    const onesignalAppId = Deno.env.get("ONESIGNAL_APP_ID") || "ONESIGNAL_APP_ID_PLACEHOLDER";
    const onesignalApiKey = Deno.env.get("ONESIGNAL_REST_API_KEY") || "ONESIGNAL_REST_API_KEY_PLACEHOLDER";

    const body = await req.json();

    // Support both direct invocation payload and Supabase Database Webhook payload
    const record = body.record || body;
    const bookingId = record.booking_id || "";
    const restaurantId = record.restaurant_id || "";
    const partySize = record.party_size || 2;
    const timeSlot = record.time_slot || "20:00";
    const bookingDate = record.booking_date || record.date || "";
    const appliedOffer = record.applied_offer || "";
    const status = record.status || "PENDING";

    // Only notify if status is PENDING (new reservation waiting for restaurant confirmation)
    if (status !== "PENDING") {
      return new Response(
        JSON.stringify({ message: "Skipping notification; status is not PENDING.", status }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    if (!restaurantId) {
      return new Response(
        JSON.stringify({ error: "Missing restaurant_id in booking payload." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Resolve customer details from database if available
    let customerName = record.customer_name || "Guest Diner";
    let customerPhone = record.customer_phone || "";

    if (supabaseUrl && supabaseServiceKey && record.user_id && (!customerName || customerName === "Guest Diner")) {
      try {
        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
          auth: { autoRefreshToken: false, persistSession: false },
        });
        const { data: user } = await supabaseAdmin
          .from("users")
          .select("name, phone_number")
          .eq("user_id", record.user_id)
          .maybeSingle();

        if (user) {
          customerName = user.name || customerName;
          customerPhone = user.phone_number || customerPhone;
        }
      } catch (err) {
        console.warn("Could not enrich diner profile:", err);
      }
    }

    // If OneSignal is not yet configured, return informative response
    if (onesignalAppId === "ONESIGNAL_APP_ID_PLACEHOLDER" || !onesignalApiKey) {
      console.log(`[notify-onesignal] Mock mode for restaurant ${restaurantId}. Booking #${bookingId}`);
      return new Response(
        JSON.stringify({
          success: true,
          mock: true,
          message: "OneSignal placeholder active. Configured for restaurant: " + restaurantId,
          booking: { bookingId, restaurantId, customerName, partySize, timeSlot },
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    // Dispatch to OneSignal REST API v1
    const oneSignalPayload = {
      app_id: onesignalAppId,
      include_aliases: {
        external_id: [restaurantId],
      },
      target_channel: "push",
      headings: {
        en: "🔔 New Table Reservation!",
      },
      contents: {
        en: `${customerName} · ${partySize} guests at ${timeSlot}`,
      },
      data: {
        type: "NEW_BOOKING",
        booking_id: bookingId,
        restaurant_id: restaurantId,
        party_size: String(partySize),
        time_slot: timeSlot,
        booking_date: bookingDate,
        customer_name: customerName,
        customer_phone: customerPhone,
        applied_offer: appliedOffer,
        status: "PENDING",
        created_at: new Date().toISOString(),
      },
      priority: 10, // Maximum delivery priority
      ios_sound: "alert_tone.wav",
      android_sound: "alert_tone",
      android_channel_id: "booking_alerts",
      content_available: true, // Wakes iOS app in background
    };

    const osResponse = await fetch("https://onesignal.com/api/v1/notifications", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${onesignalApiKey}`,
      },
      body: JSON.stringify(oneSignalPayload),
    });

    const osResult = await osResponse.json();

    return new Response(
      JSON.stringify({
        success: osResponse.ok,
        onesignal: osResult,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: osResponse.status,
      }
    );
  } catch (error) {
    console.error("Error dispatching OneSignal notification:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal server error" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
