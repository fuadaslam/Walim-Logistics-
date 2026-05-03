-- Migration: Phase 1 Supervisor Shift Control tables

-- 1. Groups (delivery groups assigned to a platform/zone)
CREATE TABLE IF NOT EXISTS public.groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    platform_id UUID REFERENCES public.platforms(id) ON DELETE SET NULL,
    zone_id UUID REFERENCES public.zones(id) ON DELETE SET NULL,
    leader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Groups viewable by authenticated" ON public.groups
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Groups manageable by admin and ops" ON public.groups
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'Operations Manager', 'Supervisor')
        )
    );

-- 2. System Settings (admin-configurable key-value pairs)
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    updated_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "System settings viewable by authenticated" ON public.system_settings
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "System settings manageable by admin" ON public.system_settings
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid() AND r.name = 'Admin'
        )
    );

INSERT INTO public.system_settings (key, value, description) VALUES
    ('riders_per_supervisor', '30', 'Maximum number of riders one supervisor can cover per shift')
ON CONFLICT (key) DO NOTHING;

-- 3. Rider Shift Plans (planned riders imported from platform for a given date/shift)
CREATE TABLE IF NOT EXISTS public.rider_shift_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    shift_date DATE NOT NULL,
    shift_start TIMESTAMPTZ NOT NULL,
    shift_end TIMESTAMPTZ NOT NULL,
    import_source TEXT DEFAULT 'manual',
    imported_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.rider_shift_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Rider shift plans viewable by authenticated" ON public.rider_shift_plans
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Rider shift plans manageable by supervisor and above" ON public.rider_shift_plans
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'Operations Manager', 'Supervisor', 'HR')
        )
    );

-- 4. Supervisor Schedules (generated schedule: which supervisor covers which group/shift)
CREATE TABLE IF NOT EXISTS public.supervisor_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    platform_id UUID REFERENCES public.platforms(id) ON DELETE CASCADE,
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    schedule_date DATE NOT NULL,
    shift_start TIMESTAMPTZ NOT NULL,
    shift_end TIMESTAMPTZ NOT NULL,
    required_supervisors INT DEFAULT 1,
    generated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.supervisor_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Supervisor schedules viewable by authenticated" ON public.supervisor_schedules
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Supervisor schedules manageable by admin and ops" ON public.supervisor_schedules
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'Operations Manager')
        )
    );

-- 5. Attendance Reports (one per supervisor per shift per group)
CREATE TABLE IF NOT EXISTS public.attendance_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    supervisor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    platform_id UUID REFERENCES public.platforms(id) ON DELETE SET NULL,
    group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
    report_date DATE NOT NULL,
    shift_start TIMESTAMPTZ,
    shift_end TIMESTAMPTZ,
    status TEXT DEFAULT 'DRAFT' CHECK (
        status IN ('DRAFT', 'SOS_SUBMITTED', 'EOS_SUBMITTED', 'PENDING_ANALYSIS', 'NEEDS_CORRECTION', 'APPROVED')
    ),
    sos_submitted_at TIMESTAMPTZ,
    eos_submitted_at TIMESTAMPTZ,
    report_generated BOOLEAN DEFAULT FALSE,
    correction_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.attendance_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Attendance reports viewable by owner supervisor" ON public.attendance_reports
    FOR SELECT USING (auth.uid() = supervisor_id);

CREATE POLICY "Attendance reports viewable by admin and ops" ON public.attendance_reports
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'Operations Manager', 'HR')
        )
    );

CREATE POLICY "Attendance reports insertable by supervisor" ON public.attendance_reports
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = supervisor_id);

CREATE POLICY "Attendance reports updatable by owner" ON public.attendance_reports
    FOR UPDATE USING (auth.uid() = supervisor_id);

-- 6. Attendance Report Items (per-rider attendance line within a report)
CREATE TABLE IF NOT EXISTS public.attendance_report_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_report_id UUID REFERENCES public.attendance_reports(id) ON DELETE CASCADE,
    rider_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    rider_name TEXT,
    rider_iqama TEXT,
    attendance_status TEXT CHECK (
        attendance_status IN ('present', 'absent', 'leave', 'suspended', 'carry_over')
    ),
    absence_reason TEXT,
    is_carry_over BOOLEAN DEFAULT FALSE,
    is_manual_addition BOOLEAN DEFAULT FALSE,
    manual_addition_reason TEXT,
    marked_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    marked_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.attendance_report_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Attendance items accessible via report owner" ON public.attendance_report_items
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.attendance_reports ar
            WHERE ar.id = attendance_report_id
              AND (ar.supervisor_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.profiles p
                JOIN public.roles r ON p.role_id = r.id
                WHERE p.id = auth.uid()
                  AND r.name IN ('Admin', 'Operations Manager', 'HR')
              ))
        )
    );

-- 7. Platform Report Uploads (Excel/CSV files uploaded by supervisor)
CREATE TABLE IF NOT EXISTS public.platform_report_uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_report_id UUID REFERENCES public.attendance_reports(id) ON DELETE CASCADE,
    supervisor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    platform_id UUID REFERENCES public.platforms(id) ON DELETE SET NULL,
    upload_date DATE NOT NULL,
    file_url TEXT,
    file_name TEXT,
    file_type TEXT CHECK (file_type IN ('excel', 'csv', 'pdf', 'other')),
    status TEXT DEFAULT 'uploaded' CHECK (status IN ('uploaded', 'validated', 'failed')),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.platform_report_uploads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Platform uploads accessible by owner and admin" ON public.platform_report_uploads
    FOR ALL TO authenticated USING (
        auth.uid() = supervisor_id OR EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'Operations Manager')
        )
    );

-- 8. Validation Flags (issues flagged during report validation)
CREATE TABLE IF NOT EXISTS public.validation_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attendance_report_id UUID REFERENCES public.attendance_reports(id) ON DELETE CASCADE,
    flag_type TEXT CHECK (
        flag_type IN (
            'MISSING_REASON',
            'MISSING_SOS',
            'MISSING_EOS',
            'MISSING_PLATFORM_REPORT',
            'INCOMPLETE_DATA',
            'DUPLICATE_ATTENDANCE_ATTEMPT',
            'MANUAL_ADDED_RIDER'
        )
    ),
    description TEXT,
    rider_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.validation_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Validation flags accessible by report owner and admin" ON public.validation_flags
    FOR ALL TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.attendance_reports ar
            WHERE ar.id = attendance_report_id
              AND (ar.supervisor_id = auth.uid() OR EXISTS (
                SELECT 1 FROM public.profiles p
                JOIN public.roles r ON p.role_id = r.id
                WHERE p.id = auth.uid()
                  AND r.name IN ('Admin', 'Operations Manager')
              ))
        )
    );

-- Enable real-time for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_reports;
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_report_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.validation_flags;
