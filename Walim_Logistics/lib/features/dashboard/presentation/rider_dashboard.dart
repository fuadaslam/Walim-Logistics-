import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/core/localization/locale_provider.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/attendance/presentation/attendance_notifier.dart';
import 'package:last_mile_fleet/features/inspections/presentation/inspection_screen.dart';
import 'package:last_mile_fleet/features/hr/presentation/document_vault_screen.dart';
import 'package:last_mile_fleet/features/support/presentation/support_tickets_screen.dart';
import 'package:last_mile_fleet/features/requests/presentation/leave_request_screen.dart' as rider_requests;
import 'package:last_mile_fleet/features/auth/presentation/auth_notifier.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/hr/presentation/rider_detail_screen.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/providers/navigation_provider.dart';

class RiderDashboard extends ConsumerWidget {
  final bool showScaffold;
  const RiderDashboard({super.key, this.showScaffold = true});

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
    final greeting = _getGreeting();
    final weatherStatus = "Riyadh: 32°C • Clear";

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 900 ? 20 : 40,
              vertical: 30,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref, attendanceState, l10n, userName, authState, greeting, weatherStatus),
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
                const Icon(Icons.wb_sunny_outlined, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(weatherStatus, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        if (!isMobile) const SizedBox(width: 12),
        IconButton(
          onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          icon: const Icon(Icons.language),
          tooltip: currentLocale.languageCode == 'en' ? 'Switch to Arabic' : 'Switch to English',
        ),
      ],
      children: [
        _buildContent(context, ref, attendanceState, l10n, userName, authState, greeting, weatherStatus),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, AttendanceState attendanceState, AppLocalizations l10n, String userName, AuthState authState, String greeting, String weather) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Shift Control & Attendance
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'Current Mission', Icons.track_changes_rounded),

            if (attendanceState.hasActiveShift)
              _buildLiveStatusIndicator(),
          ],
        ),
        const SizedBox(height: 16),
        _buildShiftControlCard(context, ref, attendanceState, l10n, isMobile),
        
        const SizedBox(height: 32),

        if (isMobile) ...[
          _buildMainContent(context, ref, attendanceState, l10n, isMobile),
          const SizedBox(height: 32),
          _buildSidebarContent(context),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildMainContent(context, ref, attendanceState, l10n, isMobile),
              ),
              const SizedBox(width: 32),
              Expanded(
                flex: 3,
                child: _buildSidebarContent(context),
              ),
            ],
          ),
      ],
    );
  }


  Widget _buildMainContent(BuildContext context, WidgetRef ref, AttendanceState attendanceState, AppLocalizations l10n, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Performance Insights', Icons.auto_graph_rounded),
        const SizedBox(height: 16),
        ResponsiveGrid(
          mobileCrossAxisCount: 3,
          tabletCrossAxisCount: 3,
          desktopCrossAxisCount: 3,
          spacing: 8,
          childAspectRatio: isMobile ? 0.8 : 1.5,

          children: const [
            DashboardStatCard(
              label: 'Deliveries',
              value: '24',
              icon: Icons.local_shipping_outlined,
              color: Color(0xFF3B82F6),
              trend: 'Target: 30',
              sparklineData: [15, 18, 12, 22, 20, 24],
            ),
            DashboardStatCard(
              label: 'Success',
              value: '98%',
              icon: Icons.verified_user_outlined,
              color: Color(0xFF10B981),
              trend: 'Excellent',
              isPositive: true,
              sparklineData: [90, 92, 88, 95, 97, 98],
            ),
            DashboardStatCard(
              label: 'Earnings',
              value: '﷼ 1,240',
              icon: Icons.account_balance_wallet_outlined,
              color: Color(0xFFF59E0B),
              trend: 'To be deposited',
              sparklineData: [800, 1000, 950, 1100, 1200, 1240],
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildSectionHeader(context, 'Required Actions', Icons.pending_actions_rounded),
        const SizedBox(height: 20),
        ResponsiveGrid(
          mobileCrossAxisCount: 2,
          tabletCrossAxisCount: 2,
          desktopCrossAxisCount: 2,
          spacing: 12,
          childAspectRatio: isMobile ? 1.1 : 2.5,
          children: [
            DashboardActionCard(
              title: 'Vehicle Inspection',
              subtitle: 'Upload photos of your bike/van',
              icon: Icons.camera_enhance_outlined,
              color: const Color(0xFF6366F1),
              badge: 'MANDATORY',
              onTap: () {
                ref.read(navigationProvider.notifier).setTab(DashboardTab.inspections);
              },
            ),
            DashboardActionCard(
              title: 'Safety Gear Check',
              subtitle: 'Verify helmet and protectors',
              icon: Icons.shield_outlined,
              color: const Color(0xFFF59E0B),
              badge: 'DUE NOW',
              onTap: () {
                ref.read(navigationProvider.notifier).setTab(DashboardTab.inspections);
              },
            ),
            DashboardActionCard(
              title: 'Support Center',
              subtitle: 'Help with fuel, accidents, or app',
              icon: Icons.contact_support_outlined,
              color: const Color(0xFFEF4444),
              onTap: () {
                ref.read(navigationProvider.notifier).setTab(DashboardTab.support);
              },
            ),
            DashboardActionCard(
              title: 'HR Requests',
              subtitle: 'Leaves, advances, or documents',
              icon: Icons.description_outlined,
              color: const Color(0xFF14B8A6),
              onTap: () {
                ref.read(navigationProvider.notifier).setTab(DashboardTab.requests);
              },
            ),
            DashboardActionCard(
              title: 'Asset Handover',
              subtitle: 'Return vehicle, uniform, or gear',
              icon: Icons.handshake_outlined,
              color: const Color(0xFF64748B),
              onTap: () {
                ref.read(navigationProvider.notifier).setTab(DashboardTab.requests);
              },
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildRequestStatusSection(context),
      ],
    );
  }

  Widget _buildRequestStatusSection(BuildContext context) {
    final requests = [
      {'type': 'Asset Handover', 'date': 'Today', 'status': 'Pending', 'icon': Icons.handshake_outlined, 'color': Colors.blueGrey},
      {'type': 'Weekly Off', 'date': '02 May', 'status': 'Approved', 'icon': Icons.calendar_month_outlined, 'color': Colors.green},
      {'type': 'Sick Leave', 'date': '28 Apr', 'status': 'Pending', 'icon': Icons.medical_services_outlined, 'color': Colors.orange},
      {'type': 'Uniform Issue', 'date': '25 Apr', 'status': 'Resolved', 'icon': Icons.checkroom_outlined, 'color': Colors.blue},
    ];


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Request Status', Icons.history_rounded),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
              color: Theme.of(context).dividerColor.withOpacity(0.3)
            ),
            itemBuilder: (context, index) {
              final r = requests[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: (r['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(r['icon'] as IconData, color: r['color'] as Color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['type'] as String,
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: -0.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r['date'] as String,
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), 
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                        ],
                      ),
                    ),
                    _buildStatusBadge(r['status'] as String, r['color'] as Color),
                  ],
                ),
              );
            },
          ),
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

  Widget _buildSidebarContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'My Responsibility', Icons.inventory_2_rounded),
        const SizedBox(height: 20),
        _buildAssetCard(context, 'Yamaha TMAX #402', 'Plate: 1234 ABC', Icons.motorcycle, Colors.blue),
        const SizedBox(height: 12),
        _buildAssetCard(context, 'Company Uniform', 'Set of 3 (New)', Icons.person_outline, Colors.purple),
        const SizedBox(height: 12),
        _buildAssetCard(context, 'Thermal Delivery Bag', 'Keeta Branded', Icons.shopping_bag_outlined, Colors.orange),
        const SizedBox(height: 32),
        _buildSectionHeader(context, 'Recent Activity', Icons.notifications_active_rounded),
        const SizedBox(height: 20),
        ActivityFeed(
          items: [
            ActivityItem(
              title: 'Delivery Successful',
              subtitle: 'Order #8821 delivered to Malaz',
              time: '12 mins ago',
              icon: Icons.check_circle_outline,
              color: Colors.green,
            ),
            ActivityItem(
              title: 'New Broadcast',
              subtitle: 'Rider safety meeting at 4 PM',
              time: '1 hour ago',
              icon: Icons.campaign,
              color: Colors.orange,
            ),
            ActivityItem(
              title: 'Check-in Confirmed',
              subtitle: 'Shift started at Riyadh Central',
              time: '4 hours ago',
              icon: Icons.login,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildComplianceAlert(context),
        const SizedBox(height: 24),
        _buildMapPreview(context),
      ],
    );
  }

  Widget _buildLiveStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.track_changes_rounded, color: Colors.green, size: 14),
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

  Widget _buildMapPreview(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        image: DecorationImage(

          image: const NetworkImage('https://maps.googleapis.com/maps/api/staticmap?center=24.7136,46.6753&zoom=14&size=600x400&scale=2&style=feature:all|element:labels|visibility:off&style=feature:road|element:geometry|color:0xeeeeee&style=feature:water|element:geometry|color:0xcceeff'),
          fit: BoxFit.cover,
          opacity: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.7,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
                  ),

                  child: Text(
                    'Riyadh Central Zone',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).textTheme.bodyLarge?.color),
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

  Widget _buildShiftControlCard(BuildContext context, WidgetRef ref, AttendanceState attendanceState, AppLocalizations l10n, bool isMobile) {
    final isActive = attendanceState.hasActiveShift;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF334155), const Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppColors.primary : Colors.black).withOpacity(0.3),
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
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(
                      isActive ? Icons.track_changes_rounded : Icons.location_searching_rounded, 
                      color: isActive ? Colors.greenAccent : Colors.white70, 
                      size: 24
                    ),
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isActive ? 'MISSION STATUS: ACTIVE' : 'SYSTEM STATUS: STANDBY',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),

                        Text(
                          isActive ? 'Riyadh Central • 04h 22m' : 'Within Geo-fence Area',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
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
                  onPressed: attendanceState.isCheckingIn ? null : () => _handleAttendance(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.redAccent.withOpacity(0.1) : Colors.white,
                    foregroundColor: isActive ? Colors.redAccent : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isActive ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),

                    elevation: 0,
                  ),
                  child: attendanceState.isCheckingIn
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isActive ? Icons.power_settings_new_rounded : Icons.bolt_rounded, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              isActive ? 'END MISSION' : 'START MISSION', 
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
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
                  boxShadow: isActive ? [
                    BoxShadow(color: Colors.white.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)
                  ] : [],
                ),
                child: Icon(
                  isActive ? Icons.location_on : Icons.location_searching_rounded, 
                  color: Colors.white, 
                  size: 32
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'ZONE: RIYADH CENTRAL' : 'NOT ON DUTY',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive ? 'Active Shift • 04h 22m' : 'Within Geo-fence Area',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: ElevatedButton(
                  onPressed: attendanceState.isCheckingIn ? null : () => _handleAttendance(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: isActive ? AppColors.primary : const Color(0xFF1E293B),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    minimumSize: const Size(120, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: attendanceState.isCheckingIn
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isActive ? Icons.logout_rounded : Icons.login_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(isActive ? 'CHECK OUT' : 'CHECK IN', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),

                ),
              ),
            ],
          ),
    );
  }

  Widget _buildAssetCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
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
                  )
                ),
                Text(
                  subtitle, 
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), 
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  )
                ),

              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: Theme.of(context).dividerColor),
        ],
      ),
    );

  }

  Widget _buildComplianceAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Text('IQAMA ALERT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.warning, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Expires in 45 days. Renewal required soon.', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodyMedium?.color)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentVaultScreen())),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.warning.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: const Text('View Document Vault', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, [IconData? icon]) {
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Theme.of(context).textTheme.headlineMedium?.color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
