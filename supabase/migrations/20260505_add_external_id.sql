-- Migration: Add external_id and expand constraints for Walim API integration

-- 1. Add external_id tracking columns
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE;

ALTER TABLE public.vehicles
  ADD COLUMN IF NOT EXISTS external_id TEXT UNIQUE;

-- 2. Index for fast dedup lookups
CREATE INDEX IF NOT EXISTS idx_profiles_external_id ON public.profiles(external_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_external_id ON public.vehicles(external_id);

-- 3. Expand vehicles.type check constraint
-- First, drop the existing constraint if it exists (need to know its name, usually 'vehicles_type_check')
DO $$
BEGIN
    ALTER TABLE public.vehicles DROP CONSTRAINT IF EXISTS vehicles_type_check;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

ALTER TABLE public.vehicles 
  ADD CONSTRAINT vehicles_type_check 
  CHECK (type IN ('bike', 'van', 'car', 'truck', 'bus', 'pickup', 'scooter', 'electric_bike', 'other'));

-- 4. Expand vehicles.status check constraint
DO $$
BEGIN
    ALTER TABLE public.vehicles DROP CONSTRAINT IF EXISTS vehicles_status_check;
EXCEPTION
    WHEN undefined_object THEN
        NULL;
END $$;

ALTER TABLE public.vehicles 
  ADD CONSTRAINT vehicles_status_check 
  CHECK (status IN ('available', 'in_use', 'maintenance', 'stolen', 'retired', 'active'));
