-- Migration: Add audit_logs, leave_requests, and documents tables

-- 1. Audit Logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    entity_type TEXT CHECK (entity_type IN ('Security', 'Finance', 'Ops', 'Fleet', 'HR', 'System')),
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Audit logs viewable by admin" ON public.audit_logs
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid() AND r.name = 'Admin'
        )
    );

CREATE POLICY "Audit logs insertable by authenticated" ON public.audit_logs
    FOR INSERT TO authenticated WITH CHECK (true);

-- 2. Leave Requests
CREATE TABLE IF NOT EXISTS public.leave_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status TEXT DEFAULT 'Pending' CHECK (status IN ('Pending', 'Approved', 'Rejected')),
    reviewed_by UUID REFERENCES public.profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Leave requests viewable by owner" ON public.leave_requests
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Leave requests viewable by HR Admin" ON public.leave_requests
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid() AND r.name IN ('HR', 'Admin', 'Supervisor', 'Operations Manager')
        )
    );

CREATE POLICY "Leave requests insertable by owner" ON public.leave_requests
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Leave requests updatable by HR" ON public.leave_requests
    FOR UPDATE TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid() AND r.name IN ('HR', 'Admin')
        )
    );

-- 3. Documents
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    type TEXT NOT NULL,
    status TEXT DEFAULT 'Valid',
    expiry_date DATE,
    file_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Documents viewable by owner" ON public.documents
    FOR SELECT USING (auth.uid() = profile_id);

CREATE POLICY "Documents viewable by HR Admin" ON public.documents
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid() AND r.name IN ('HR', 'Admin')
        )
    );

CREATE POLICY "Documents insertable by owner" ON public.documents
    FOR INSERT WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Documents updatable by owner" ON public.documents
    FOR UPDATE USING (auth.uid() = profile_id);

CREATE POLICY "Documents deletable by owner" ON public.documents
    FOR DELETE USING (auth.uid() = profile_id);

-- 4. Allow admin/HR to view all profiles
CREATE POLICY "Profiles viewable by admin and HR roles" ON public.profiles
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            JOIN public.roles r ON p.role_id = r.id
            WHERE p.id = auth.uid()
              AND r.name IN ('Admin', 'HR', 'Supervisor', 'Operations Manager', 'Finance Manager')
        )
    );

-- Enable real-time
ALTER PUBLICATION supabase_realtime ADD TABLE public.leave_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.documents;
