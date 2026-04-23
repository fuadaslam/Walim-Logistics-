-- Fleet & Last-Mile Delivery Management System Schema

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Roles Definition
CREATE TABLE public.roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.roles (name, description) VALUES
('Rider', 'Frontline delivery personnel'),
('Leader', 'Field Captain managing clusters'),
('Supervisor', 'Performance driver managing zones'),
('Operations Manager', 'Strategist for fleet allocation'),
('HR', 'Compliance and personnel guard'),
('Finance Manager', 'Cash controller and payroll'),
('Business Development', 'Growth engine and partner relations'),
('IT_Dev', 'System maintenance and deployment'),
('Admin', 'Super user with full access');

-- 2. Profiles (Extends Auth Users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role_id UUID REFERENCES public.roles(id),
    full_name TEXT NOT NULL,
    phone_number TEXT UNIQUE,
    iqama_number TEXT UNIQUE,
    license_number TEXT UNIQUE,
    avatar_url TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'on_leave', 'suspended')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Fleet Asset Registry
CREATE TABLE public.vehicles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plate_number TEXT UNIQUE NOT NULL,
    vin_number TEXT UNIQUE,
    make TEXT,
    model TEXT,
    year INT,
    type TEXT CHECK (type IN ('bike', 'van', 'car')),
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'in_use', 'maintenance', 'stolen', 'retired')),
    istimara_expiry DATE,
    mvpi_expiry DATE,
    insurance_expiry DATE,
    insurance_policy_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Inventory Assets
CREATE TABLE public.assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL, -- e.g., 'Thermal Bag', 'Uniform', 'Fuel Card'
    category TEXT,
    serial_number TEXT UNIQUE,
    status TEXT DEFAULT 'in_stock' CHECK (status IN ('in_stock', 'assigned', 'damaged', 'lost')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.asset_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id UUID REFERENCES public.assets(id),
    profile_id UUID REFERENCES public.profiles(id),
    assigned_by UUID REFERENCES public.profiles(id),
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    returned_at TIMESTAMPTZ,
    condition_on_assign TEXT,
    condition_on_return TEXT
);

-- 5. Attendance & Geofencing
CREATE TABLE public.attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id),
    check_in_time TIMESTAMPTZ DEFAULT NOW(),
    check_out_time TIMESTAMPTZ,
    check_in_lat DOUBLE PRECISION,
    check_in_long DOUBLE PRECISION,
    check_out_lat DOUBLE PRECISION,
    check_out_long DOUBLE PRECISION,
    is_geofenced_valid BOOLEAN DEFAULT TRUE,
    attendance_type TEXT CHECK (attendance_type IN ('shift', 'break')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Inspections
CREATE TABLE public.inspections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id),
    vehicle_id UUID REFERENCES public.vehicles(id),
    inspection_type TEXT CHECK (inspection_type IN ('pre_shift', 'post_shift', 'random')),
    is_safe_to_drive BOOLEAN NOT NULL,
    checklist_data JSONB, -- Stores dynamic checklist results
    photo_urls TEXT[], -- Array of links to Supabase Storage
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Shifts & Zones
CREATE TABLE public.zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    geofence_center_lat DOUBLE PRECISION,
    geofence_center_long DOUBLE PRECISION,
    geofence_radius_meters INT
);

CREATE TABLE public.shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id),
    zone_id UUID REFERENCES public.zones(id),
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Incidents
CREATE TABLE public.incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reported_by UUID REFERENCES public.profiles(id),
    type TEXT CHECK (type IN ('accident', 'fuel_issue', 'app_glitch', 'other')),
    description TEXT,
    photo_urls TEXT[],
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'rejected')),
    resolved_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Finance & Platforms
CREATE TABLE public.platforms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL, -- e.g., 'Noon', 'Keeta', 'Amazon'
    description TEXT
);

CREATE TABLE public.platform_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    platform_id UUID REFERENCES public.platforms(id),
    report_date DATE NOT NULL,
    delivery_count INT,
    total_cod_amount DECIMAL(10, 2),
    raw_data JSONB, -- Stores the full row for traceability
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.cod_reconciliation (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id),
    platform_id UUID REFERENCES public.platforms(id),
    expected_amount DECIMAL(10, 2),
    collected_amount DECIMAL(10, 2),
    discrepancy DECIMAL(10, 2),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'matched', 'flagged', 'resolved')),
    reconciled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Automated Profile Creation on Signup
-- This function will run every time a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role_id)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    (SELECT id FROM public.roles WHERE name = 'Rider') -- Default to Rider
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. Real-time Setup
-- Enable real-time for critical tracking tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incidents;
ALTER PUBLICATION supabase_realtime ADD TABLE public.cod_reconciliation;

-- 12. RLS & Security (Enhanced)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can view own, Admins view all
CREATE POLICY "Profiles are viewable by owner" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Attendance: Users can view/insert own, Supervisors view all
CREATE POLICY "Attendance viewable by owner" ON public.attendance
  FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Attendance insertable by owner" ON public.attendance
  FOR INSERT WITH CHECK (auth.uid() = profile_id);

-- Vehicles: Everyone can view available vehicles
CREATE POLICY "Vehicles are viewable by all authenticated users" ON public.vehicles
  FOR SELECT TO authenticated USING (true);
