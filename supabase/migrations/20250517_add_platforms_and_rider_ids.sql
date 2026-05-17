-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add missing platforms: Keeta, Amazon, Ninja
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO platforms (id, name, description)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Keeta',   'Keeta last-mile delivery platform')
 ,('c0000000-0000-0000-0000-000000000002', 'Amazon',  'Amazon delivery partner (DSP WALM)')
 ,('c0000000-0000-0000-0000-000000000003', 'Ninja',   'Ninja Xpress grocery delivery')
ON CONFLICT (id) DO NOTHING;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Add platform courier ID columns to profiles
--    keeta_id  → numeric Captain ID from Keeta exports  (e.g. 249609)
--    amazon_id → TID from Amazon payment sheets         (e.g. A17MID9I0RLHC6)
--    ninja_id  → DA ID from Ninja shift sheets          (e.g. 229201)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS keeta_id  TEXT,
  ADD COLUMN IF NOT EXISTS amazon_id TEXT,
  ADD COLUMN IF NOT EXISTS ninja_id  TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_keeta_id  ON public.profiles (keeta_id)  WHERE keeta_id  IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_amazon_id ON public.profiles (amazon_id) WHERE amazon_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_ninja_id  ON public.profiles (ninja_id)  WHERE ninja_id  IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Also use employee_id as the canonical "internal staff number"
--    (was already added but never populated — leave it for HR use)
-- ─────────────────────────────────────────────────────────────────────────────
