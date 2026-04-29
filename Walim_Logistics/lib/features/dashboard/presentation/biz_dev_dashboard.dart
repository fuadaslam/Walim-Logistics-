import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:last_mile_fleet/features/biz_dev/presentation/partner_portals_screen.dart';

class BizDevDashboard extends ConsumerWidget {
  final bool showScaffold;
  const BizDevDashboard({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showScaffold) {
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
      title: 'GROWTH ENGINE',
      subtitle: 'Partner relations and profitability analysis',
      children: [
        _buildContent(context),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Growth Stats
        _buildSectionHeader('Revenue & Partnerships'),
        const SizedBox(height: 24),
        ResponsiveGrid(
          children: const [
            DashboardStatCard(
              label: 'Active Partners',
              value: '6',
              icon: Icons.handshake_outlined,
              color: Colors.purple,
              trend: 'Amazon, Noon, Keeta...',
            ),
            DashboardStatCard(
              label: 'Avg. Margin/Del',
              value: '﷼ 4.2',
              icon: Icons.analytics_outlined,
              color: Colors.green,
              trend: '+5% this week',
              sparklineData: [3.8, 3.9, 4.0, 4.1, 4.2, 4.2],
            ),
            DashboardStatCard(
              label: 'New Prospects',
              value: '3',
              icon: Icons.add_chart_outlined,
              color: Colors.blue,
              trend: 'Negotiation phase',
            ),
            DashboardStatCard(
              label: 'Projected Growth',
              value: '+15%',
              icon: Icons.trending_up_outlined,
              color: Colors.teal,
              trend: 'Next Quarter',
            ),
          ],
        ),

        const SizedBox(height: 48),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Strategic Partnerships'),
                  const SizedBox(height: 24),
                  ResponsiveGrid(
                    mobileCrossAxisCount: 1,
                    tabletCrossAxisCount: 2,
                    desktopCrossAxisCount: 2,
                    childAspectRatio: 2.2,
                    children: [
                      DashboardActionCard(
                        title: 'Partner Portals',
                        subtitle: 'Manage client relationship dashboards',
                        icon: Icons.business_outlined,
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartnerPortalsScreen()));
                        },
                      ),
                      DashboardActionCard(
                        title: 'Profitability Analysis',
                        subtitle: 'Margin calculation per platform',
                        icon: Icons.payments_outlined,
                        color: Colors.green,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Client Reporting',
                        subtitle: 'Generate high-level performance decks',
                        icon: Icons.description_outlined,
                        color: Colors.blue,
                        onTap: () {},
                      ),
                      DashboardActionCard(
                        title: 'Expansion Planning',
                        subtitle: 'Analyze new zones and city entries',
                        icon: Icons.explore_outlined,
                        color: Colors.indigo,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Partner Performance'),
                  const SizedBox(height: 24),
                  _buildPartnerPerformanceCard('Amazon SA', 0.85, Colors.orange),
                  const SizedBox(height: 12),
                  _buildPartnerPerformanceCard('Noon Logistics', 0.78, Colors.amber),
                  const SizedBox(height: 12),
                  _buildPartnerPerformanceCard('Keeta Food', 0.92, Colors.teal),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartnerPerformanceCard(String name, double marginScore, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('Profit Margin', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: marginScore,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
