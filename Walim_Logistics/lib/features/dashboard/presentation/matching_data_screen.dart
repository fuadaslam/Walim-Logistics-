import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/finance/presentation/finance_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/finance_dashboard.dart';

class MatchingDataScreen extends ConsumerStatefulWidget {
  const MatchingDataScreen({super.key});

  @override
  ConsumerState<MatchingDataScreen> createState() => _MatchingDataScreenState();
}

class _MatchingDataScreenState extends ConsumerState<MatchingDataScreen> {
  String? _selectedPlatformId;
  String? _selectedPlatformName;

  @override
  Widget build(BuildContext context) {
    final platformsAsync = ref.watch(platformsProvider);

    return platformsAsync.when(
      loading: () => DashboardScaffold(
        title: 'DATA RECONCILIATION',
        subtitle: 'Match platform performance with internal records',
        showBackButton: true,
        children: const [Center(child: CircularProgressIndicator())],
      ),
      error: (e, _) => DashboardScaffold(
        title: 'DATA RECONCILIATION',
        subtitle: 'Match platform performance with internal records',
        showBackButton: true,
        children: [
          Center(
            child: Text('Failed to load platforms',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
      data: (platforms) {
        if (_selectedPlatformId == null && platforms.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedPlatformId = platforms.first['id'] as String?;
              _selectedPlatformName = platforms.first['name'] as String?;
            });
          });
        }

        return DashboardScaffold(
          title: 'DATA RECONCILIATION',
          subtitle: 'Match platform performance with internal records',
          showBackButton: true,
          actions: [
            if (platforms.isNotEmpty)
              DropdownButton<String>(
                value: _selectedPlatformId,
                hint: Text('Select Platform',
                    style: GoogleFonts.outfit(fontSize: 14)),
                items: platforms
                    .map((p) => DropdownMenuItem(
                          value: p['id'] as String,
                          child: Text(p['name'] as String? ?? ''),
                        ))
                    .toList(),
                onChanged: (val) {
                  final platform =
                      platforms.firstWhere((p) => p['id'] == val);
                  setState(() {
                    _selectedPlatformId = val;
                    _selectedPlatformName = platform['name'] as String?;
                  });
                },
              ),
          ],
          children: [
            if (_selectedPlatformId != null)
              _buildReconciliationSection(_selectedPlatformId!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_tree_outlined,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        platforms.isEmpty
                            ? 'No Platforms Configured'
                            : 'Select a Platform',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        platforms.isEmpty
                            ? 'You need to configure at least one external platform (e.g., Talabat, Jahez) in the Finance module to start reconciliation.'
                            : 'Select a platform from the dropdown above to view performance reconciliation data.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      if (platforms.isEmpty) ...[
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to Finance module while preserving history
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (_) => const FinanceDashboard())
                            );
                          },
                          icon: const Icon(Icons.settings_suggest_rounded),
                          label: const Text('Configure Platforms Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildReconciliationSection(String platformId) {
    final reconAsync = ref.watch(reconciliationByPlatformProvider(platformId));

    return reconAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Failed to load reconciliation data',
              style: TextStyle(color: AppColors.error)),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No reconciliation data for $_selectedPlatformName yet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        final flagged = rows.where((r) => r['status'] == 'flagged').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildComparisonTable(rows),
            if (flagged.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildDiscrepancyCard(flagged),
            ],
          ],
        );
      },
    );
  }

  Widget _buildComparisonTable(List<Map<String, dynamic>> rows) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final r = rows[index];
        final name = r['profiles']?['full_name'] as String? ?? 'Unknown';
        final role = r['profiles']?['role'] as String? ?? 'Rider';
        final hrStatus = r['profiles']?['status'] as String? ?? 'active';
        final collected = (r['collected_amount'] as num?)?.toDouble() ?? 0.0;
        final expected = (r['expected_amount'] as num?)?.toDouble() ?? 0.0;
        final status = r['status'] as String? ?? 'pending';
        final discrepancy = collected - expected;
        final hasDiscrepancy = discrepancy.abs() > 0.1;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasDiscrepancy ? Colors.orange.withOpacity(0.3) : AppColors.divider.withOpacity(0.5),
              width: hasDiscrepancy ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(role, style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    _buildHRStatusChip(hrStatus),
                    const SizedBox(width: 12),
                    _buildMatchIcon(status),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildAmountColumn('COLLECTED', collected, Colors.blue),
                    _buildAmountColumn('EXPECTED', expected, Colors.indigo),
                    _buildAmountColumn(
                      'DISCREPANCY', 
                      discrepancy, 
                      hasDiscrepancy ? Colors.red : Colors.green,
                      isDiscrepancy: true,
                    ),
                  ],
                ),
                if (hasDiscrepancy) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Platform report shows higher collection than internal record.',
                            style: GoogleFonts.outfit(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('RECONCILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMatchIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'matched':
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case 'flagged':
        icon = Icons.warning_rounded;
        color = Colors.orange;
        break;
      case 'resolved':
        icon = Icons.task_alt_rounded;
        color = Colors.blue;
        break;
      default:
        icon = Icons.hourglass_top_rounded;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color, {bool isDiscrepancy = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'SAR ${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: isDiscrepancy && amount != 0 ? (amount > 0 ? Colors.red : Colors.green) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHRStatusChip(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'on_leave':
        color = Colors.blue;
        break;
      case 'suspended':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDiscrepancyCard(List<Map<String, dynamic>> flagged) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem, color: AppColors.error),
              SizedBox(width: 8),
              Text('Action Required',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          ...flagged.map((r) {
            final name =
                r['profiles']?['full_name'] as String? ?? 'Unknown';
            final discrepancy =
                (r['discrepancy'] as num?)?.toStringAsFixed(2) ?? '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$name has a discrepancy of SAR $discrepancy on $_selectedPlatformName. Please verify.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            child: const Text('Resolve Discrepancies'),
          ),
        ],
      ),
    );
  }
}
