---
name: Walim Logistics App — Project State
description: Flutter multi-role logistics app (Supabase backend); active Supabase project, Phase 1 supervisor workflow completion status
type: project
---

Supabase project: **Walim App** (`yotkztmstrhrdqffcciz`, ap-southeast-1). The second project "walim-delivery" (`bcxkkvucbfqbinevvayp`) is unused/staging.

**Why:** All production schema lives in `yotkztmstrhrdqffcciz`.

**How to apply:** Always use project ID `yotkztmstrhrdqffcciz` for schema migrations and SQL queries.

## Phase 1 — Supervisor Shift Control (completed 2026-05-02)

New tables applied via migrations 001 + 002:
- `audit_logs`, `leave_requests`, `documents` (migration 001)
- `groups`, `system_settings` (seed: riders_per_supervisor=30), `rider_shift_plans`, `supervisor_schedules`, `attendance_reports`, `attendance_report_items`, `platform_report_uploads`, `validation_flags` (migration 002)

New Flutter files:
- `lib/features/supervisor/data/supervisor_repository.dart`
- `lib/features/supervisor/presentation/supervisor_notifier.dart` — `shiftControlProvider` (StateNotifier)
- `lib/features/supervisor/presentation/daily_shift_control_screen.dart` — full SOS→EOS→Upload→Validation→Approved workflow
- `lib/features/dashboard/presentation/supervisor_dashboard.dart` — updated with hero card linking to Daily Shift Control

## Status flow (attendance_reports)
DRAFT → SOS_SUBMITTED → EOS_SUBMITTED → PENDING_ANALYSIS → NEEDS_CORRECTION | APPROVED

EOS is gated: blocked until next supervisor submits SOS for same group+platform.
