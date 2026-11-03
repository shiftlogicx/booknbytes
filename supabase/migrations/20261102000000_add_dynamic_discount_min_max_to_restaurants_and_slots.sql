-- Align schema for min/max dynamic discounts on restaurants and daily_slots
ALTER TABLE public.restaurants 
ADD COLUMN IF NOT EXISTS dynamic_discount_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS min_discount INTEGER DEFAULT 10,
ADD COLUMN IF NOT EXISTS max_discount INTEGER DEFAULT 30;

-- Backfill any existing restaurants from attributes JSONB if available
UPDATE public.restaurants
SET 
  dynamic_discount_enabled = COALESCE((attributes->>'dynamic_discount_enabled')::boolean, (attributes->'dynamic_discount'->>'enabled')::boolean, false),
  min_discount = COALESCE((attributes->>'min_discount')::integer, (attributes->'dynamic_discount'->>'min_discount')::integer, 10),
  max_discount = COALESCE((attributes->>'max_discount')::integer, (attributes->'dynamic_discount'->>'max_discount')::integer, 30)
WHERE attributes IS NOT NULL;

-- Optionally support min/max on daily_slots if slots use differential dynamic ranges
ALTER TABLE public.daily_slots
ADD COLUMN IF NOT EXISTS min_discount NUMERIC DEFAULT NULL,
ADD COLUMN IF NOT EXISTS max_discount NUMERIC DEFAULT NULL;
