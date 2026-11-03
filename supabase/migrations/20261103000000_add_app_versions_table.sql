-- Migration: Add app_versions table for dynamic in-app optional and mandatory updates
CREATE TABLE IF NOT EXISTS public.app_versions (
  app_name TEXT PRIMARY KEY,
  latest_version TEXT NOT NULL DEFAULT '1.0.0',
  min_required_version TEXT NOT NULL DEFAULT '1.0.0',
  release_notes TEXT DEFAULT 'Bug fixes and performance enhancements.',
  play_store_url TEXT DEFAULT 'https://play.google.com/store/apps/details?id=com.booknbite.hotel',
  app_store_url TEXT DEFAULT 'https://apps.apple.com/app/id67383606',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Allow public read access to version information
DROP POLICY IF EXISTS "Public read app_versions" ON public.app_versions;
CREATE POLICY "Public read app_versions"
  ON public.app_versions FOR SELECT
  TO anon, authenticated
  USING (true);

-- Insert initial records for hotel_app and customer_app
INSERT INTO public.app_versions (app_name, latest_version, min_required_version, release_notes, play_store_url, app_store_url)
VALUES 
  (
    'hotel_app',
    '1.0.0',
    '1.0.0',
    'Initial release of Book & Bite Partner with real-time reservation management.',
    'https://play.google.com/store/apps/details?id=com.booknbite.hotel',
    'https://apps.apple.com/app/id67383606'
  ),
  (
    'customer_app',
    '1.0.0',
    '1.0.0',
    'Initial release of Book & Bite Diner with live table booking & dynamic discounts.',
    'https://play.google.com/store/apps/details?id=com.booknbite.customer',
    'https://apps.apple.com/app/id67383607'
  )
ON CONFLICT (app_name) DO NOTHING;
