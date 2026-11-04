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
        JSON.stringify({ error: "Missing Supabase server credentials." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const body = await req.json().catch(() => null);
    if (!body || !body.restaurant_id || !body.category || !body.base64_data) {
      return new Response(
        JSON.stringify({ error: "Required fields: restaurant_id, category ('ambience' | 'menu'), base64_data." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const { restaurant_id, category, filename, base64_data, content_type } = body;

    if (category !== "ambience" && category !== "menu") {
      return new Response(
        JSON.stringify({ error: "Category must be either 'ambience' (hotel photos, max 3) or 'menu' (menu cards)." }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    // Decode base64 to binary
    const cleanBase64 = base64_data.replace(/^data:image\/\w+;base64,/, "");
    const binaryBytes = Uint8Array.from(atob(cleanBase64), (c) => c.charCodeAt(0));
    const mime = content_type || "image/jpeg";
    const extension = mime.includes("png") ? "png" : mime.includes("webp") ? "webp" : "jpg";
    const cleanFilename = filename || `${category}_${Date.now()}.${extension}`;
    const storagePath = `${restaurant_id}/${category}/${cleanFilename}`;

    // Upload to Supabase Storage bucket 'restaurant-media'
    const { data: uploadData, error: uploadError } = await supabaseAdmin.storage
      .from("restaurant-media")
      .upload(storagePath, binaryBytes, {
        contentType: mime,
        upsert: true,
      });

    if (uploadError) {
      return new Response(
        JSON.stringify({ error: `Storage upload failed: ${uploadError.message}` }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
      );
    }

    // Get public URL
    const { data: urlData } = supabaseAdmin.storage
      .from("restaurant-media")
      .getPublicUrl(storagePath);
    const publicUrl = urlData.publicUrl;

    // Fetch existing restaurant visuals
    const { data: rest, error: fetchErr } = await supabaseAdmin
      .from("restaurants")
      .select("restaurant_id, visuals")
      .eq("restaurant_id", restaurant_id)
      .maybeSingle();

    let updatedVisuals: any = rest?.visuals || { hero_image: "", ambience: [], menu_images: [] };
    if (!Array.isArray(updatedVisuals.ambience)) updatedVisuals.ambience = [];
    if (!Array.isArray(updatedVisuals.menu_images)) updatedVisuals.menu_images = [];

    if (category === "ambience") {
      // Hotel / Ambience photos: Maximum 3
      if (!updatedVisuals.ambience.includes(publicUrl)) {
        updatedVisuals.ambience.push(publicUrl);
        if (updatedVisuals.ambience.length > 3) {
          // Keep the latest 3
          updatedVisuals.ambience = updatedVisuals.ambience.slice(-3);
        }
      }
      if (!updatedVisuals.hero_image || updatedVisuals.hero_image === "") {
        updatedVisuals.hero_image = publicUrl;
      }
    } else if (category === "menu") {
      // Menu card photos: Unlimited pages
      if (!updatedVisuals.menu_images.includes(publicUrl)) {
        updatedVisuals.menu_images.push(publicUrl);
      }
    }

    // Update restaurant record in Supabase
    const { data: updatedRest, error: updateErr } = await supabaseAdmin
      .from("restaurants")
      .update({ visuals: updatedVisuals })
      .eq("restaurant_id", restaurant_id)
      .select("restaurant_id, visuals")
      .single();

    return new Response(
      JSON.stringify({
        success: true,
        publicUrl,
        storagePath,
        visuals: updatedRest?.visuals || updatedVisuals,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "An unexpected error occurred during media upload." }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
