-- Platform performance records parsed from uploaded files
CREATE TABLE IF NOT EXISTS platform_performance_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id UUID REFERENCES platform_report_uploads(id) ON DELETE CASCADE,
  platform_id UUID REFERENCES platforms(id),

  record_date DATE NOT NULL,
  external_rider_id TEXT,
  rider_name TEXT,
  rider_id UUID REFERENCES profiles(id),

  -- Normalised metrics (common across platforms)
  total_orders INT,
  delivered_orders INT,
  delivery_ontime_pct NUMERIC(6,2),
  shift_compliance_pct NUMERIC(6,2),
  attendance_ontime_pct NUMERIC(6,2),
  working_hours NUMERIC(8,4),
  pickup_ontime_pct NUMERIC(6,2),
  return_ontime_pct NUMERIC(6,2),
  avg_delay_min NUMERIC(8,2),
  avg_roaming_min NUMERIC(8,2),
  avg_offline_min NUMERIC(8,2),

  -- Platform-specific overflow
  raw_metrics JSONB DEFAULT '{}'::JSONB,
  report_type TEXT DEFAULT 'unknown',

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_perf_platform ON platform_performance_records(platform_id);
CREATE INDEX IF NOT EXISTS idx_perf_date ON platform_performance_records(record_date);
CREATE INDEX IF NOT EXISTS idx_perf_rider ON platform_performance_records(rider_id);
CREATE INDEX IF NOT EXISTS idx_perf_upload ON platform_performance_records(upload_id);
CREATE INDEX IF NOT EXISTS idx_perf_ext_rider ON platform_performance_records(external_rider_id);

-- Shift schedule records (from Ninja/Keeta shift docs)
CREATE TABLE IF NOT EXISTS platform_shift_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  upload_id UUID REFERENCES platform_report_uploads(id) ON DELETE CASCADE,
  platform_id UUID REFERENCES platforms(id),

  record_date DATE NOT NULL,
  shift_slot TEXT,
  area TEXT,
  target_count INT DEFAULT 0,
  max_count INT,
  actual_count INT,

  external_rider_id TEXT,
  rider_name TEXT,
  rider_id UUID REFERENCES profiles(id),

  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_shift_platform ON platform_shift_records(platform_id);
CREATE INDEX IF NOT EXISTS idx_shift_date ON platform_shift_records(record_date);
CREATE INDEX IF NOT EXISTS idx_shift_upload ON platform_shift_records(upload_id);

-- RLS policies
ALTER TABLE platform_performance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_shift_records ENABLE ROW LEVEL SECURITY;

-- Admins and ops can see all; supervisors see their platform records
CREATE POLICY "read_performance" ON platform_performance_records
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON p.role_id = r.id
      WHERE p.id = auth.uid()
        AND r.name IN ('Admin', 'Operations Manager', 'Supervisor', 'Finance Manager', 'Business Development')
    )
  );

CREATE POLICY "insert_performance" ON platform_performance_records
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON p.role_id = r.id
      WHERE p.id = auth.uid()
        AND r.name IN ('Admin', 'Operations Manager', 'Supervisor')
    )
  );

CREATE POLICY "read_shifts" ON platform_shift_records
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON p.role_id = r.id
      WHERE p.id = auth.uid()
        AND r.name IN ('Admin', 'Operations Manager', 'Supervisor', 'Finance Manager', 'Business Development')
    )
  );

CREATE POLICY "insert_shifts" ON platform_shift_records
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM profiles p
      JOIN roles r ON p.role_id = r.id
      WHERE p.id = auth.uid()
        AND r.name IN ('Admin', 'Operations Manager', 'Supervisor')
    )
  );
