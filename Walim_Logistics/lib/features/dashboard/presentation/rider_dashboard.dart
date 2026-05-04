import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/core/localization/locale_provider.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/attendance/presentation/attendance_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/document_vault_screen.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/rider_data_provider.dart';
import 'package:walim_logistics/core/services/location_service.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/location_permission_alert.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/office_request_alert.dart';
import 'package:walim_logistics/features/tracking/services/location_providers.dart';
import 'package:walim_logistics/features/performance/presentation/screens/my_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/leaderboard_screen.dart';
import 'package:walim_logistics/shared/models/assigned_asset.dart';
import 'package:intl/intl.dart';

class RiderDashboard extends ConsumerWidget {
  final bool showScaffold;
  const RiderDashboard({super.key, this.showScaffold = true});

  Future<void> _handleAttendance(BuildContext context, WidgetRef ref) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final zone = await ref.read(riderZoneProvider.future);
    await ref.read(attendanceProvider.notifier).toggleShift(
          centerLat: (zone?['geofence_center_lat'] as num?)?.toDouble() ?? 24.7136,
          centerLong: (zone?['geofence_center_long'] as num?)?.toDouble() ?? 46.6753,
          radiusMeters: (zone?['geofence_radius_meters'] as num?)?.toDouble() ?? 500,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AttendanceState>(attendanceProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Start/Stop tracking based on shift status
      if (next.hasActiveShift && !(previous?.hasActiveShift ?? false)) {
        ref.read(locationServiceProvider).startTracking();
      } else if (!next.hasActiveShift && (previous?.hasActiveShift ?? false)) {
        ref.read(locationServiceProvider).stopTracking();
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final attendanceState = ref.watch(attendanceProvider);
    final currentLocale = ref.watch(localeProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.profile?.fullName ?? 'Rider';
    final greeting = _getGreeting();
    
    final zoneAsync = ref.watch(riderZoneProvider);
    final currentZone = zoneAsync.value?['name'] ?? 'Riyadh';
    final weatherStatus = "$currentZone: 32°C • Clear";

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 900 ? 0 : 40,
              vertical: 0,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(
                  context,
                  ref,
                  attendanceState,
                  l10n,
                  userName,
                  authState,
                  greeting,
                  weatherStatus,
                ),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'MISSION CONTROL',
      subtitle: '$greeting, $userName! Ready for your shift?',
      actions: [
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  weatherStatus,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        if (!isMobile) const SizedBox(width: 12),
        IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          icon: const Icon(Icons.language, size: 22),
          tooltip: currentLocale.languageCode == 'en'
              ? 'Switch to Arabic'
              : 'Switch to English',
        ),
      ],
      children: [
        _buildContent(
          context,
          ref,
          attendanceState,
          l10n,
          userName,
          authState,
          greeting,
          weatherStatus,
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AttendanceState attendanceState,
    AppLocalizations l10n,
    String userName,
    AuthState authState,
    String greeting,
    String weather,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final hasPermission = ref.watch(permissionStatusProvider).value ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (authState.profile != null)
          OfficeRequestAlert(profileId: authState.profile!.id),
        if (attendanceState.hasActiveShift && !hasPermission)
          LocationPermissionAlert(onRetry: () {
            ref.invalidate(permissionStatusProvider);
          }),
        if (attendanceState.todayCheckIns < 3 &&
            !attendanceState.hasActiveShift)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildCheckInAlert(context, ref, attendanceState),
          ),
        if (attendanceState.hasActiveShift)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildLiveStatusIndicator(),
          ),
        _buildShiftControlCard(context, ref, attendanceState, l10n, isMobile),

        const SizedBox(height: 20),

        if (isMobile) ...[
          _buildMainContent(context, ref, attendanceState, l10n, isMobile),
          const SizedBox(height: 20),
          _buildSidebarContent(context, ref),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildMainContent(
                  context,
                  ref,
                  attendanceState,
                  l10n,
                  isMobile,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(flex: 3, child: _buildSidebarContent(context, ref)),
            ],
          ),
      ],
    );
  }

  Widget _buildCheckInAlert(
    BuildContext context,
    WidgetRef ref,
    AttendanceState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CHECK-IN REQUIRED (${state.todayCheckIns}/3)',
                  style: GoogleFonts.outfit(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have not completed the required 3 check-ins today. Please check in, or report if you have an issue.',
            style: GoogleFonts.outfit(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(navigationProvider.notifier)
                        .setTab(DashboardTab.requests);
                    // Could pre-fill a leave request
                  },
                  icon: const Icon(Icons.event_busy, size: 18),
                  label: const Text('Mark Leave'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(navigationProvider.notifier)
                        .setTab(DashboardTab.support);
                  },
                  icon: const Icon(Icons.report_problem, size: 18),
                  label: const Text('Report Issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    WidgetRef ref,
    AttendanceState attendanceState,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Attendance & Shift',
          Icons.fact_check_outlined,
        ),
        const SizedBox(height: 10),
        ResponsiveGrid(
          mobileCrossAxisCount: 3,
          tabletCrossAxisCount: 3,
          desktopCrossAxisCount: 3,
          spacing: 8,
          childAspectRatio: isMobile ? 0.8 : 1.5,

          children: [
            DashboardStatCard(
              label: 'Check-ins',
              value: '${attendanceState.todayCheckIns} / 3',
              icon: Icons.fact_check_outlined,
              color: const Color(0xFF3B82F6),
              trend: 'Today',
              sparklineData: const [0, 1, 1, 2, 2, 3],
            ),
            DashboardStatCard(
              label: 'Compliance',
              value: attendanceState.todayCheckIns >= 3 ? '100%' : '${(attendanceState.todayCheckIns / 3 * 100).toInt()}%',
              icon: Icons.health_and_safety_outlined,
              color: const Color(0xFF10B981),
              trend: 'Status',
              isPositive: attendanceState.todayCheckIns >= 3,
              sparklineData: const [80, 85, 90, 95, 100, 100],
            ),
            DashboardStatCard(
              label: 'Active Time',
              value: attendanceState.hasActiveShift ? 'Active' : 'Offline',
              icon: Icons.timer_outlined,
              color: const Color(0xFFF59E0B),
              trend: 'Shift',
              sparklineData: const [0, 2, 4, 6, 8, 8],
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSectionHeader(
          context,
          'Required Actions',
          Icons.pending_actions_rounded,
        ),
        const SizedBox(height: 12),
        ResponsiveGrid(
          mobileCrossAxisCount: 2,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 2,
          spacing: 12,
          childAspectRatio: isMobile ? 1.1 : 2.5,
          children: [
            DashboardActionCard(
              title: 'Support Center',
              subtitle: 'Help with fuel, accidents, or app',
              icon: Icons.contact_support_outlined,
              color: const Color(0xFFEF4444),
              onTap: () {
                ref
                    .read(navigationProvider.notifier)
                    .setTab(DashboardTab.support);
              },
            ),
            DashboardActionCard(
              title: 'HR Requests',
              subtitle: 'Leaves, advances, or documents',
              icon: Icons.description_outlined,
              color: const Color(0xFF14B8A6),
              onTap: () {
                ref
                    .read(navigationProvider.notifier)
                    .setTab(DashboardTab.requests);
              },
            ),
            DashboardActionCard(
              title: 'Asset Handover',
              subtitle: 'Return vehicle, uniform, or gear',
              icon: Icons.handshake_outlined,
              color: const Color(0xFF64748B),
              onTap: () {
                ref
                    .read(navigationProvider.notifier)
                    .setTab(DashboardTab.requests);
              },
            ),
            DashboardActionCard(
              title: 'My Performance',
              subtitle: 'Your score, targets and this month\'s adjustments',
              icon: Icons.bar_chart_rounded,
              color: Colors.indigo,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyPerformanceScreen()));
              },
            ),
            DashboardActionCard(
              title: 'Leaderboard',
              subtitle: 'See how you rank among all riders',
              icon: Icons.leaderboard_rounded,
              color: Colors.amber,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LeaderboardScreen()));
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildRequestStatusSection(context, ref),
      ],
    );
  }

  Widget _buildRequestStatusSection(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(riderLeaveRequestsProvider);

    Color _statusColor(String status) {
      switch (status) {
        case 'Approved':
          return Colors.green;
        case 'Rejected':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Request Status', Icons.history_rounded),
        const SizedBox(height: 16),
        requestsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const SizedBox.shrink(),
          data: (requests) {
            if (requests.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.history_rounded,
                title: 'No requests yet',
                subtitle: 'Your leave and HR requests will appear here once submitted.',
                color: Colors.blueGrey,
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 20,
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                ),
                itemBuilder: (context, index) {
                  final r = requests[index];
                  final status = r['status'] as String? ?? 'Pending';
                  final color = _statusColor(status);
                  final startDate = r['start_date'] != null
                      ? DateFormat('MMM d')
                          .format(DateTime.parse(r['start_date']))
                      : '—';
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.event_note_outlined,
                              color: color, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r['type'] as String? ?? 'Request',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                startDate,
                                style: GoogleFonts.outfit(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusBadge(status, color),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),

      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSidebarContent(BuildContext context, WidgetRef ref) {
    final assetsAsync = ref.watch(riderAssetsProvider);
    final iqamaAsync = ref.watch(riderIqamaExpiryProvider);
    final activityAsync = ref.watch(riderRecentAttendanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'My Responsibility', Icons.inventory_2_rounded),
        const SizedBox(height: 12),
        assetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (assets) {
            if (assets.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.inventory_2_outlined,
                title: 'No assets assigned',
                subtitle: 'You don\'t have any company equipment assigned to you yet.',
                color: Colors.blueGrey,
              );
            }
            return Column(
              children: [
                for (int i = 0; i < assets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _buildAssetCard(
                    context,
                    assets[i].assetName,
                    assets[i].assetCategory ?? '',
                    Icons.inventory_2_outlined,
                    Colors.blue,
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Recent Activity', Icons.notifications_active_rounded),
        const SizedBox(height: 12),
        activityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
          data: (records) {
            if (records.isEmpty) {
              return ActivityFeed(items: const []);
            }
            return ActivityFeed(
              items: records.map((r) {
                final isCheckout = r['check_out_time'] != null;
                final dt = r['check_in_time'] != null
                    ? DateTime.tryParse(r['check_in_time'].toString())?.toLocal()
                    : null;
                final diff = dt != null ? DateTime.now().difference(dt) : null;
                final timeStr = diff != null
                    ? diff.inMinutes < 60
                        ? '${diff.inMinutes} mins ago'
                        : '${diff.inHours}h ago'
                    : '';
                return ActivityItem(
                  title: isCheckout ? 'Checked Out' : 'Checked In',
                  subtitle: isCheckout ? 'Shift ended' : 'Shift started',
                  time: timeStr,
                  icon: isCheckout ? Icons.logout_rounded : Icons.login_rounded,
                  color: isCheckout ? Colors.orange : Colors.green,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        iqamaAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (expiry) => expiry != null
              ? _buildComplianceAlert(context, expiry)
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        _buildMapPreview(context, ref),
      ],
    );
  }

  Widget _buildLiveStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.track_changes_rounded,
            color: Colors.green,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            'MISSION ACTIVE',
            style: GoogleFonts.outfit(
              color: Colors.green,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context, WidgetRef ref) {
    final zoneAsync = ref.watch(riderZoneProvider);
    return Container(
      height: 220,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(24.7136, 46.6753),
                initialZoom: 14.0,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.walim.walim_logistics',
                  retinaMode: true,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: const LatLng(24.7136, 46.6753),
                      width: 50,
                      height: 50,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 60), // Push below the center marker
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    zoneAsync.value?['name'] ?? 'Riyadh Central Zone',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fullscreen_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftControlCard(
    BuildContext context,
    WidgetRef ref,
    AttendanceState attendanceState,
    AppLocalizations l10n,
    bool isMobile,
  ) {
    final isActive = attendanceState.hasActiveShift;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF334155), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.primary : Colors.black).withOpacity(
              0.3,
            ),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
      ),

      child: isMobile
          ? Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.track_changes_rounded
                            : Icons.location_searching_rounded,
                        color: isActive ? Colors.greenAccent : Colors.white70,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive
                                ? 'MISSION STATUS: ACTIVE'
                                : 'SYSTEM STATUS: STANDBY',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),

                          Text(
                            isActive
                                ? '${ref.watch(riderZoneProvider).value?['name'] ?? 'Riyadh Central'} • 04h 22m'
                                : 'Within Geo-fence Area',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: attendanceState.isCheckingIn
                        ? null
                        : () => _handleAttendance(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? Colors.redAccent.withOpacity(0.1)
                          : Colors.white,
                      foregroundColor: isActive
                          ? Colors.redAccent
                          : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isActive
                              ? Colors.redAccent.withOpacity(0.5)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),

                      elevation: 0,
                    ),
                    child: attendanceState.isCheckingIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.power_settings_new_rounded
                                    : Icons.bolt_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                isActive ? 'END MISSION' : 'START MISSION',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    isActive
                        ? Icons.location_on
                        : Icons.location_searching_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'ZONE: ${(ref.watch(riderZoneProvider).value?['name'] as String?)?.toUpperCase() ?? 'RIYADH CENTRAL'}' : 'NOT ON DUTY',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'Active Shift • 04h 22m'
                            : 'Within Geo-fence Area',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: ElevatedButton(
                    onPressed: attendanceState.isCheckingIn
                        ? null
                        : () => _handleAttendance(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isActive
                          ? AppColors.primary
                          : const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      minimumSize: const Size(120, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: attendanceState.isCheckingIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.logout_rounded
                                    : Icons.login_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive ? 'CHECK OUT' : 'CHECK IN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),

          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceAlert(BuildContext context, DateTime expiryDate) {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    final isExpired = daysLeft < 0;
    final color = isExpired ? AppColors.error : AppColors.warning;
    final label = isExpired ? 'IQAMA EXPIRED' : 'IQAMA ALERT';
    final message = isExpired
        ? 'Your IQAMA has expired. Immediate renewal required.'
        : 'Expires in $daysLeft day${daysLeft == 1 ? '' : 's'}. Renewal required soon.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentVaultScreen()),
              ),
              style: TextButton.styleFrom(
                backgroundColor: color.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text(
                'View Document Vault',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, [
    IconData? icon,
  ]) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
