-- Migration: Link bookings to daily_slots and add admin access
-- 1. Add slot_id foreign key column to public.bookings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'bookings' AND column_name = 'slot_id'
  ) THEN
    ALTER TABLE public.bookings 
    ADD COLUMN slot_id uuid REFERENCES public.daily_slots(slot_id) ON DELETE SET NULL;
  END IF;
END $$;

-- 2. Add RLS policy for admin management of bookings
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'bookings' AND policyname = 'Admins full access to bookings'
  ) THEN
    CREATE POLICY "Admins full access to bookings"
    ON public.bookings
    FOR ALL
    TO authenticated
    USING (((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'admin')
    WITH CHECK (((auth.jwt() -> 'app_metadata'::text) ->> 'role'::text) = 'admin');
  END IF;
END $$;
