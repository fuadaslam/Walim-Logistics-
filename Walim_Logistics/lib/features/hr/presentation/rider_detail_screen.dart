import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/shared/models/profile.dart';
import 'package:last_mile_fleet/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class RiderDetailScreen extends ConsumerWidget {
  final UserProfile? profile;
  
  const RiderDetailScreen({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final name = profile?.fullName ?? "Ahmed Ali";
    final riderId = profile?.id.substring(0, 8).toUpperCase() ?? "WAL-78921";
    
    return DashboardScaffold(
      title: 'Rider Profile',
      subtitle: 'Managing details and performance for $name',
      showBackButton: true,
      children: [
        _buildHeader(context, name, riderId, isMobile),
        const SizedBox(height: 32),
        _buildStatsGrid(context, isMobile),
        const SizedBox(height: 32),
        if (isMobile)
          Column(
            children: [
              _buildMainContent(context),
              const SizedBox(height: 24),
              _buildSecondaryContent(context),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildMainContent(context),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSecondaryContent(context),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        _buildSectionCard(
          context: context,
          title: 'Personal & Legal Identity',
          icon: Icons.badge_outlined,
          child: _buildIdentityDetails(),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Asset Assignments',
          icon: Icons.motorcycle_outlined,
          child: _buildAssetDetails(),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Performance Analytics',
          icon: Icons.insights_rounded,
          child: _buildPerformanceChart(context),
        ),
      ],
    );
  }

  Widget _buildSecondaryContent(BuildContext context) {
    return Column(
      children: [
        _buildSectionCard(
          context: context,
          title: 'Compliance & Docs',
          icon: Icons.folder_shared_outlined,
          child: _buildComplianceList(),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Quick Actions',
          icon: Icons.bolt_rounded,
          child: _buildQuickActions(context),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Financial Summary',
          icon: Icons.account_balance_wallet_outlined,
          child: _buildFinancialSummary(),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String name, String id, bool isMobile) {
    final headerContent = [
      Stack(
        children: [
          Container(
            width: isMobile ? 80 : 100,
            height: isMobile ? 80 : 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: isMobile ? 3 : 4),
            ),
            child: Center(
              child: Text(
                name.substring(0, 1).toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 32 : 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 3),
              ),
            ),
          ),
        ],
      ),
      SizedBox(width: isMobile ? 0 : 32, height: isMobile ? 24 : 0),
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: isMobile ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Employee ID: $id • Joined Oct 2023',
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.6),
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildHeaderTag(Icons.location_on_outlined, 'Riyadh Central'),
                _buildHeaderTag(Icons.star_rounded, '4.9 Rating'),
                _buildHeaderTag(Icons.verified_user_outlined, 'Verified'),
              ],
            ),
          ],
        ),
      ),
      SizedBox(width: isMobile ? 0 : 32, height: isMobile ? 24 : 0),
      SizedBox(
        width: isMobile ? double.infinity : null,
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: const Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile 
        ? Column(children: headerContent)
        : Row(children: headerContent),
    );
  }

  Widget _buildHeaderTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildStatCard(context, 'Deliveries', '1,422', Icons.delivery_dining, Colors.blue),
              const SizedBox(width: 16),
              _buildStatCard(context, 'Success Rate', '99.2%', Icons.check_circle_outline, Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(context, 'Avg. Delivery', '24m', Icons.timer_outlined, Colors.orange),
              const SizedBox(width: 16),
              _buildStatCard(context, 'COD Balance', '﷼ 450', Icons.payments_outlined, Colors.purple),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        _buildStatCard(context, 'Total Deliveries', '1,422', Icons.delivery_dining, Colors.blue),
        const SizedBox(width: 20),
        _buildStatCard(context, 'Success Rate', '99.2%', Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 20),
        _buildStatCard(context, 'Avg. Delivery', '24m', Icons.timer_outlined, Colors.orange),
        const SizedBox(width: 20),
        _buildStatCard(context, 'COD Balance', '﷼ 450', Icons.payments_outlined, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                const Icon(Icons.trending_up, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                const Text('+12%', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityDetails() {
    return Column(
      children: [
        _buildDetailRow('Iqama Number', '2410389210', isCopyable: true),
        _buildDetailRow('Passport Number', 'K9281726', isCopyable: true),
        _buildDetailRow('Driving License', 'Saudi Private (Valid)'),
        _buildDetailRow('Sponsorship', 'Walim Logistics Co.'),
        _buildDetailRow('Mobile Number', '+966 50 123 4567', isCopyable: true),
        _buildDetailRow('Emergency Contact', 'Khalid (Brother) - +966 55 987 6543'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetDetails() {
    return Column(
      children: [
        _buildAssetItem(
          'Vehicle',
          'Yamaha TMAX #402',
          'Plate: 1234 ABC',
          Icons.motorcycle,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAssetItem(
          'Delivery Bag',
          'Keeta Thermal Bag',
          'Serial: TK-8892',
          Icons.shopping_bag_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildAssetItem(
          'Uniform',
          'Standard Kit (3 Sets)',
          'Assigned: 12 Oct 2023',
          Icons.checkroom_outlined,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAssetItem(String category, String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Manage', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildComplianceList() {
    return Column(
      children: [
        _buildComplianceItem('Iqama Expiry', 'Expires in 42 days', 0.8, Colors.green),
        _buildComplianceItem('Health Insurance', 'Expires in 12 days', 0.15, Colors.red),
        _buildComplianceItem('Driving License', 'Expires in 280 days', 0.95, Colors.green),
        _buildComplianceItem('Balady Card', 'Expires in 150 days', 0.7, Colors.orange),
      ],
    );
  }

  Widget _buildComplianceItem(String title, String status, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildActionButton(Icons.file_upload_outlined, 'Upload Document', () {}),
        _buildActionButton(Icons.assignment_ind_outlined, 'Reassign Asset', () {}),
        _buildActionButton(Icons.warning_amber_rounded, 'Log Incident', () {}),
        _buildActionButton(Icons.history_rounded, 'Shift History', () {}),
        _buildActionButton(Icons.payment_rounded, 'Issue Payout', () {}),
        _buildActionButton(Icons.block_flipped, 'Suspend Rider', () {}, isDestructive: true),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.05) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDestructive ? Colors.red.withOpacity(0.1) : AppColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Column(
      children: [
        _buildFinanceRow('Current COD Balance', '﷼ 450.00', Colors.orange),
        _buildFinanceRow('Pending Deposits', '﷼ 120.00', Colors.blue),
        _buildFinanceRow('Total Earnings (MTD)', '﷼ 3,850.00', Colors.green),
        const Divider(height: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('View Full Financial Ledger'),
        ),
      ],
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'Weekly Performance Visualization',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const Text(
              '(Integrating with Live Telemetry Data)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
