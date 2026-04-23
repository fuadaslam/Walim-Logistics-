import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/core/localization/locale_provider.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/attendance/presentation/attendance_notifier.dart';
import 'package:last_mile_fleet/features/inspections/presentation/inspection_screen.dart';
import 'package:last_mile_fleet/features/incidents/presentation/incident_report_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/leave_request_screen.dart';
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class RiderDashboard extends ConsumerWidget {
  const RiderDashboard({super.key});

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  Future<void> _handleAttendance(BuildContext context, WidgetRef ref) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    await ref.read(attendanceProvider.notifier).toggleShift(
      centerLat: 24.7136,
      centerLong: 46.6753,
      radiusMeters: 500,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final attendanceState = ref.watch(attendanceProvider);
    final currentLocale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.profile?.fullName ?? 'Rider';

    return DashboardScaffold(
      title: l10n.riderDashboard,
      subtitle: 'Hello, $userName! Ready for your shift?',
      actions: [
        IconButton(
          onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          icon: const Icon(Icons.language),
          tooltip: currentLocale.languageCode == 'en' ? 'Switch to Arabic' : 'Switch to English',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
        ),
        IconButton(
          onPressed: () => _handleLogout(context, ref),
          icon: const Icon(Icons.logout),
        ),
      ],
      children: [
        // Duty Status Card
        _buildDutyStatusCard(context, ref, attendanceState, l10n),
        
        const SizedBox(height: 32),
        
        Text(
          'Daily Operations',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        
        ResponsiveGrid(
          mobileCrossAxisCount: 1,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 3,
          childAspectRatio: 2.5,
          children: [
            DashboardActionCard(
              title: l10n.vehicleInspection,
              subtitle: 'Daily pre-shift check',
              icon: Icons.directions_bike,
              color: AppColors.accent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InspectionScreen()),
                );
              },
            ),
            DashboardActionCard(
              title: 'Report COD',
              subtitle: 'Reconcile collected cash',
              icon: Icons.payments_outlined,
              color: Colors.green,
              onTap: () {},
            ),
            DashboardActionCard(
              title: l10n.myAssets,
              subtitle: 'Uniforms & equipment',
              icon: Icons.inventory_2_outlined,
              color: Colors.purple,
              onTap: () {},
            ),
            DashboardActionCard(
              title: 'Leave Request',
              subtitle: 'Apply for time off',
              icon: Icons.time_to_leave_outlined,
              color: Colors.orange,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
                );
              },
            ),
            DashboardActionCard(
              title: l10n.support,
              subtitle: 'Report an incident',
              icon: Icons.help_outline,
              color: AppColors.error,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 32),
        
        // Document & Compliance Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compliance Alert',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Your Iqama expires in 45 days. Please update soon.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Vault'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDutyStatusCard(BuildContext context, WidgetRef ref, AttendanceState attendanceState, AppLocalizations l10n) {
    final isActive = attendanceState.hasActiveShift;
    
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [AppColors.primary, AppColors.primaryDark] 
              : [const Color(0xFF475569), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.primary : Colors.black).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'ON DUTY' : 'OFF DUTY',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Shift in progress' : 'Ready to start?',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.timer_outlined : Icons.timer_off_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: attendanceState.isCheckingIn ? null : () => _handleAttendance(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: isActive ? AppColors.primary : const Color(0xFF1E293B),
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: attendanceState.isCheckingIn
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isActive ? l10n.checkOut : l10n.checkIn,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

