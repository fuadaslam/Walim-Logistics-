import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/admin/presentation/admin_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/it_dev_dashboard.dart';
import 'package:walim_logistics/features/admin/presentation/rbac_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/audit_logs_screen.dart';
import 'package:walim_logistics/features/hr/presentation/staff_management_screen.dart';
import 'package:walim_logistics/features/admin/presentation/group_setup_screen.dart';
import 'package:walim_logistics/features/admin/presentation/shift_planner_screen.dart';
import 'package:walim_logistics/features/admin/presentation/supervisor_schedule_screen.dart';
import 'package:walim_logistics/features/tracking/screens/rider_tracking_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/admin_performance_screen.dart';
import 'package:walim_logistics/features/performance/presentation/screens/leaderboard_screen.dart';
import 'package:walim_logistics/features/admin/presentation/attendance_reports_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  final bool showScaffold;
  const AdminDashboard({super.key, this.showScaffold = true});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'CONTROL TOWER',
      subtitle: 'Real-time metrics across all zones and platforms',
      actions: [],
      children: [
        _buildContent(context),
      ],
    );
  }

  List<ActionCardData> _getActionCards(BuildContext context) {
    return [
      ActionCardData(
        title: 'Shift Planner',
        subtitle: 'Generate rider shift plans by group and date',
        icon: Icons.event_note_rounded,
        color: Colors.indigo,
        category: 'Operations',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const ShiftPlannerScreen(),
        )),
      ),
      ActionCardData(
        title: 'SOS/EOS Monitoring',
        subtitle: 'View daily supervisor shift reports',
        icon: Icons.assignment_turned_in_rounded,
        color: Colors.deepPurple,
        category: 'Operations',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const AttendanceReportsScreen(),
        )),
      ),
      ActionCardData(
        title: 'Group Management',
        subtitle: 'Create groups and assign riders to supervisors',
        icon: Icons.groups_rounded,
        color: Colors.teal,
        category: 'Personnel',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const GroupSetupScreen(),
        )),
      ),
      ActionCardData(
        title: 'Supervisor Schedule',
        subtitle: 'Assign supervisors to groups and shifts',
        icon: Icons.assignment_ind_rounded,
        color: Colors.orange,
        category: 'Personnel',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const SupervisorScheduleScreen(),
        )),
      ),
      ActionCardData(
        title: 'Leaderboard',
        subtitle: 'Top performers — riders and supervisors',
        icon: Icons.leaderboard_rounded,
        color: Colors.amber,
        category: 'Assets',
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const LeaderboardScreen(),
        )),
      ),
    ];
  }

  Widget _buildContent(BuildContext context) {
    final stats = ref.watch(adminStatsProvider);
    final dashboardData = ref.watch(dashboardDataProvider);

    final allCards = _getActionCards(context);
    final filteredCards = allCards.where((card) {
      final matchesCategory = _selectedCategory == 'All' || card.category == _selectedCategory;
      final matchesSearch = card.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          card.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting & Status Section
        _buildGreeting(context),
        const SizedBox(height: 16),

        DashboardRefreshBar(
          lastUpdated: dashboardData.lastUpdated,
          isLoading: stats.isLoading || dashboardData.isLoading,
          onRefresh: () {
            ref.read(adminStatsProvider.notifier).loadStats();
            ref.read(dashboardDataProvider.notifier).refresh();
          },
        ),
        const SizedBox(height: 8),

        // KPI Section
        if (stats.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          ResponsiveGrid(
            mobileCrossAxisCount: 2,
            tabletCrossAxisCount: 3,
            desktopCrossAxisCount: 5,
            childAspectRatio: 1.8,
            spacing: 12,
            children: [
              DashboardStatCard(
                label: 'Active Riders',
                value: stats.activeRiders.toString(),
                icon: Icons.motorcycle,
                color: Colors.blue,
                trend: 'Live',
                isPositive: true,
                sparklineData: const [10, 15, 8, 20, 12, 25, 22],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const StaffManagementScreen(initialRole: 'Rider', initialStatus: 'Active_Completed'),
                )),
              ),
              DashboardStatCard(
                label: 'On Duty Now',
                value: stats.liveOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
                trend: 'Open shifts',
                isPositive: true,
                sparklineData: const [50, 45, 60, 55, 70, 65, 80],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const AttendanceReportsScreen(),
                )),
              ),
              DashboardStatCard(
                label: 'On Leave',
                value: stats.onLeave.toString(),
                icon: Icons.person_off_outlined,
                color: Colors.green,
                trend: 'Current',
                isPositive: stats.onLeave < 5,
                sparklineData: const [2, 3, 2, 4, 3, 2, 2],
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const StaffManagementScreen(initialRole: 'Rider', initialStatus: 'on leave'),
                )),
              ),
              DashboardStatCard(
                label: 'Requests',
                value: stats.pendingRequests.toString(),
                icon: Icons.assignment_late_outlined,
                color: Colors.purple,
                trend: 'Pending',
                isPositive: stats.pendingRequests == 0,
                sparklineData: const [5, 8, 6, 10, 12, 11, 8],
                onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.hr),
              ),
              DashboardStatCard(
                label: 'Fleet Health',
                value: '${stats.fleetHealth > 0 ? stats.fleetHealth : (dashboardData.assetHealth > 0 ? dashboardData.assetHealth : 98)}%',
                icon: Icons.build_circle_outlined,
                color: Colors.teal,
                trend: 'Optimal',
                isPositive: true,
                sparklineData: const [95, 96, 95, 97, 98, 97, 98],
                onTap: () => ref.read(navigationProvider.notifier).setTab(DashboardTab.assets),
              ),
            ],
          ),
        
        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Management Tools
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Management Tools'),
                  const SizedBox(height: 20),
                  
                  // Search & Filter Row
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        // Search bar
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.outfit(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search management tools...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category pills
                        ...['All', 'Operations', 'Personnel', 'Assets'].map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  filteredCards.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No management tools match your filter',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your search query or switching categories.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 1;
                            if (constraints.maxWidth > 1100) {
                              crossAxisCount = 3;
                            } else if (constraints.maxWidth > 600) {
                              crossAxisCount = 2;
                            }
                            
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: crossAxisCount == 3 ? 2.5 : (crossAxisCount == 2 ? 3.2 : 4.5),
                              ),
                              itemCount: filteredCards.length,
                              itemBuilder: (context, index) {
                                final card = filteredCards[index];
                                return DashboardActionCard(
                                  title: card.title,
                                  subtitle: card.subtitle,
                                  icon: card.icon,
                                  color: card.color,
                                  onTap: card.onTap,
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Right Column: Live Activity & Overview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'System Overview'),
                  const SizedBox(height: 20),
                  _buildOperationsTelemetry(context),
                  const SizedBox(height: 24),
                  ActivityFeed(
                    items: dashboardData.recentActivity.map((a) {
                      final type = a['type'] as String? ?? '';
                      IconData icon;
                      Color color;
                      switch (type) {
                        case 'incident':
                          icon = Icons.warning_rounded;
                          color = Colors.red;
                          break;
                        case 'leave':
                          icon = Icons.person_off_outlined;
                          color = Colors.orange;
                          break;
                        case 'inspection':
                          icon = Icons.checklist_rounded;
                          color = Colors.green;
                          break;
                        default:
                          icon = Icons.info_outline;
                          color = Colors.blue;
                      }
                      return ActivityItem(
                        title: a['title'] as String? ?? '',
                        subtitle: a['subtitle'] as String? ?? '',
                        time: a['time'] as String? ?? '',
                        icon: icon,
                        color: color,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildAdminTools(context),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    final displayName = profile?.fullName ?? 'Admin';
    final role = profile?.role ?? 'Admin';

    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[now.month - 1]} ${now.day}, ${now.year}';

    final stats = ref.watch(adminStatsProvider);
    final dashboardData = ref.watch(dashboardDataProvider);

    final dynamicEfficiency = (100 - (stats.pendingRequests * 3) - (dashboardData.activeIncidents * 5)).clamp(75, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $displayName',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your $role dashboard is operating at $dynamicEfficiency% efficiency today with ${stats.pendingRequests} pending requests and ${dashboardData.activeIncidents} active incidents.',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.headlineMedium?.color,
      ),
    );
  }

  Widget _buildOperationsTelemetry(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardData = ref.watch(dashboardDataProvider);

    final totalRiders = dashboardData.activeRiders + dashboardData.ridersOnLeave + dashboardData.inactiveRiders;
    final activePct = totalRiders > 0 ? (dashboardData.activeRiders / totalRiders) : 0.7;
    final leavePct = totalRiders > 0 ? (dashboardData.ridersOnLeave / totalRiders) : 0.15;
    final inactivePct = totalRiders > 0 ? (dashboardData.inactiveRiders / totalRiders) : 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.divider.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'OPERATIONS TELEMETRY',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE PULSE',
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (activePct > 0)
                    Expanded(
                      flex: (activePct * 100).toInt().clamp(1, 100),
                      child: Container(color: Colors.blue),
                    ),
                  if (leavePct > 0)
                    Expanded(
                      flex: (leavePct * 100).toInt().clamp(1, 100),
                      child: Container(color: Colors.green),
                    ),
                  if (inactivePct > 0)
                    Expanded(
                      flex: (inactivePct * 100).toInt().clamp(1, 100),
                      child: Container(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Details Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTelemetryIndicator(
                'Active',
                dashboardData.activeRiders > 0 ? dashboardData.activeRiders.toString() : '24',
                Colors.blue,
              ),
              _buildTelemetryIndicator(
                'On Leave',
                dashboardData.ridersOnLeave > 0 ? dashboardData.ridersOnLeave.toString() : '3',
                Colors.green,
              ),
              _buildTelemetryIndicator(
                'Idle',
                dashboardData.inactiveRiders > 0 ? dashboardData.inactiveRiders.toString() : '5',
                Colors.grey,
              ),
            ],
          ),
          const Divider(height: 24),
          // Shift Compliance
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.login_rounded, color: Colors.orange, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checked In (SOS)',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dashboardData.checkedInToday > 0 ? dashboardData.checkedInToday.toString() : '18',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.purple, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checked Out (EOS)',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dashboardData.checkedOutToday > 0 ? dashboardData.checkedOutToday.toString() : '12',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryIndicator(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Administration',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminToolItem(
            context,
            'Audit Logs',
            Icons.history_rounded,
            Colors.blueGrey,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditLogsScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminToolItem(
            context,
            'Access Control (RBAC)',
            Icons.admin_panel_settings_outlined,
            AppColors.primary,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RBACManagementScreen())),
          ),
          const SizedBox(height: 12),
          _buildAdminToolItem(
            context,
            'IT & API Management',
            Icons.terminal,
            Colors.blueGrey,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevDashboard())),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Theme.of(context).textTheme.bodyMedium?.color, size: 16),
          ],
        ),
      ),
    );
  }
}

class ActionCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String category;
  final VoidCallback onTap;

  ActionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
    required this.onTap,
  });
}


