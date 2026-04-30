import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/hr/presentation/asset_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/document_vault_screen.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_report_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/shift_assignment_screen.dart';
import 'package:walim_logistics/features/finance/presentation/cod_reconciliation_screen.dart';

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
        SizedBox(height: isMobile ? 16 : 32),
        _buildStatsGrid(context, isMobile),
        SizedBox(height: isMobile ? 16 : 32),
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
          child: _buildIdentityDetails(context),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Asset Assignments',
          icon: Icons.motorcycle_outlined,
          child: _buildAssetDetails(context),
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
          child: _buildComplianceList(context),
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
          child: _buildFinancialSummary(context),
        ),
      ],
    );
  }
  Widget _buildHeader(BuildContext context, String name, String id, bool isMobile) {
    final avatar = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: isMobile ? 64 : 110,
          height: isMobile ? 64 : 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
        ),
        Container(
          width: isMobile ? 52 : 94,
          height: isMobile ? 52 : 94,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: -2,
              )
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "R",
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 22 : 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: isMobile ? 2 : 10,
          right: isMobile ? 2 : 10,
          child: Container(
            width: isMobile ? 14 : 18,
            height: isMobile ? 14 : 18,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF0F172A), width: isMobile ? 2 : 3),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        ),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 18 : 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Color(0xFF10B981), 
                      fontSize: 8, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.0
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'ID: $id • Joined Oct 2023',
          textAlign: TextAlign.start,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: isMobile ? 12 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 20),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: isMobile ? 6 : 10,
          runSpacing: isMobile ? 6 : 10,
          children: [
            _buildHeaderTag(Icons.location_on_rounded, 'Riyadh'),
            _buildHeaderTag(Icons.star_rounded, '4.9'),
            _buildHeaderTag(Icons.verified_user_rounded, 'Verified'),
          ],
        ),
      ],
    );

    final buttons = isMobile 
      ? Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon')));
                },
                icon: Icon(Icons.edit_outlined, size: 14),
                label: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon')));
                },
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 14),
                label: Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        )
      : Column(
          children: [
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit Profile coming soon')));
              },
              icon: Icon(Icons.edit_outlined, size: 18),
              label: Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon')));
              },
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                minimumSize: Size(0, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          isMobile 
            ? Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      avatar,
                      SizedBox(width: 16),
                      Expanded(child: info),
                    ],
                  ),
                  SizedBox(height: 16),
                  buttons,
                ],
              )
            : Row(
                children: [
                  avatar,
                  SizedBox(width: 32),
                  Expanded(child: info),
                  SizedBox(width: 32),
                  buttons,
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildHeaderTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 12),
          const SizedBox(width: 6),
          Text(
            label, 
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7), 
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )
          ),
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
              _buildStatCard(context, 'Total Working Days', '214', Icons.calendar_today_rounded, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard(context, 'Working Hours', '1,640h', Icons.access_time_rounded, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard(context, 'Leave', '14 Days', Icons.beach_access_rounded, Colors.orange),
              const SizedBox(width: 12),
              _buildStatCard(context, 'Requests', '3 Pending', Icons.history_edu_rounded, Colors.purple),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        _buildStatCard(context, 'Total Working Days', '214', Icons.calendar_today_rounded, Colors.blue),
        const SizedBox(width: 20),
        _buildStatCard(context, 'Working Hours', '1,640h', Icons.access_time_rounded, Colors.green),
        const SizedBox(width: 20),
        _buildStatCard(context, 'Leave', '14 Days', Icons.beach_access_rounded, Colors.orange),
        const SizedBox(width: 20),
        _buildStatCard(context, 'Requests', '3 Pending', Icons.history_edu_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 18 : 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up_rounded, color: Colors.green, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        '12%', 
                        style: TextStyle(
                          color: Colors.green, 
                          fontSize: isMobile ? 9 : 10, 
                          fontWeight: FontWeight.w900
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12 : 24),
            Text(
              value, 
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 20 : 28, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              )
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white54 : AppColors.textSecondary, 
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: isMobile ? 16 : 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityDetails(BuildContext context) {
    return Column(
      children: [
        _buildDetailRow(context, 'Iqama Number', '2410389210', isCopyable: true),
        _buildDetailRow(context, 'Passport Number', 'K9281726', isCopyable: true),
        _buildDetailRow(context, 'Driving License', 'Saudi Private (Valid)'),
        _buildDetailRow(context, 'Sponsorship', 'Walim Logistics Co.'),
        _buildDetailRow(context, 'Mobile Number', '+966 50 123 4567', isCopyable: true),
        _buildDetailRow(context, 'Emergency Contact', 'Khalid (Brother) - +966 55 987 6543'),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isCopyable = false}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(), 
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary.withValues(alpha: 0.6), 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              )
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value, 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, 
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )
                  ),
                ),
                if (isCopyable)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.copy_all_rounded, size: 16, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

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
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetDetails(BuildContext context) {
    return Column(
      children: [
        _buildAssetItem(
          context,
          'Vehicle',
          'Yamaha TMAX #402',
          'Plate: 1234 ABC',
          Icons.motorcycle,
          Colors.blue,
        ),
        const SizedBox(height: 16),
        _buildAssetItem(
          context,
          'Delivery Bag',
          'Keeta Thermal Bag',
          'Serial: TK-8892',
          Icons.shopping_bag_outlined,
          Colors.orange,
        ),
        const SizedBox(height: 16),
        _buildAssetItem(
          context,
          'Uniform',
          'Standard Kit (3 Sets)',
          'Assigned: 12 Oct 2023',
          Icons.checkroom_outlined,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAssetItem(BuildContext context, String category, String title, String subtitle, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(), 
                  style: GoogleFonts.outfit(
                    color: color.withValues(alpha: 0.7), 
                    fontSize: 8, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  )
                ),
                const SizedBox(height: 2),
                Text(
                  title, 
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: isMobile ? 14 : 16,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )
                ),
                Text(
                  subtitle, 
                  style: GoogleFonts.outfit(
                    color: AppColors.textSecondary.withValues(alpha: 0.6), 
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  )
                ),
              ],
            ),
          ),
          if (!isMobile)
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
              },
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildComplianceList(BuildContext context) {
    return Column(
      children: [
        _buildComplianceItem(context, 'Iqama Expiry', 'Expires in 42 days', 0.8, Colors.green),
        _buildComplianceItem(context, 'Health Insurance', 'Expires in 12 days', 0.15, Colors.red),
        _buildComplianceItem(context, 'Driving License', 'Expires in 280 days', 0.95, Colors.green),
        _buildComplianceItem(context, 'Balady Card', 'Expires in 150 days', 0.7, Colors.orange),
      ],
    );
  }

  Widget _buildComplianceItem(BuildContext context, String title, String status, double progress, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentVaultScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title, 
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  letterSpacing: -0.2,
                )
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status, 
                  style: GoogleFonts.outfit(
                    color: color, 
                    fontSize: 11, 
                    fontWeight: FontWeight.w900
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: 300 * progress, // Simplified for demonstration
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = isMobile ? 2 : 3;
        final spacing = isMobile ? 8.0 : 12.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final buttonWidth = (constraints.maxWidth - totalSpacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildActionButton(context, Icons.file_upload_outlined, 'Upload Document', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentVaultScreen()));
            }, width: buttonWidth),
            _buildActionButton(context, Icons.assignment_ind_outlined, 'Reassign Asset', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssetManagementScreen()));
            }, width: buttonWidth),
            _buildActionButton(context, Icons.warning_amber_rounded, 'Log Incident', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IncidentReportScreen()));
            }, width: buttonWidth),
            _buildActionButton(context, Icons.history_rounded, 'Shift History', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftAssignmentScreen()));
            }, width: buttonWidth),
            _buildActionButton(context, Icons.payment_rounded, 'Issue Payout', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout Processing coming soon')));
            }, width: buttonWidth),
            _buildActionButton(context, Icons.block_flipped, 'Suspend Rider', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suspend action initiated')));
            }, isDestructive: true, width: buttonWidth),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {bool isDestructive = false, required double width}) {

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withValues(alpha: 0.05) 
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.1) 
                : Theme.of(context).dividerColor.withValues(alpha: 0.5)
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDestructive ? Colors.red : AppColors.primary, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDestructive ? Colors.red : AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    return Column(
      children: [
        _buildFinanceRow('Current COD Balance', '﷼ 450.00', Colors.orange),
        _buildFinanceRow('Pending Deposits', '﷼ 120.00', Colors.blue),
        _buildFinanceRow('Total Earnings (MTD)', '﷼ 3,850.00', Colors.green),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CODReconciliationScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              'View Full Financial Ledger', 
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 0.5)
            ),
          ),
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
