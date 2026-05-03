import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/finance/presentation/finance_notifier.dart';

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
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    platforms.isEmpty
                        ? 'No platforms configured yet.\nAdd platforms in the Finance module.'
                        : 'Select a platform to view reconciliation data.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 15),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Rider')),
            DataColumn(label: Text('Collected (SAR)')),
            DataColumn(label: Text('Expected (SAR)')),
            DataColumn(label: Text('HR Status')),
            DataColumn(label: Text('Match')),
          ],
          rows: rows.map((r) {
            final name =
                r['profiles']?['full_name'] as String? ?? 'Unknown';
            final hrStatus =
                r['profiles']?['status'] as String? ?? '—';
            final collected =
                (r['collected_amount'] as num?)?.toStringAsFixed(0) ?? '—';
            final expected =
                (r['expected_amount'] as num?)?.toStringAsFixed(0) ?? '—';
            final status = r['status'] as String? ?? 'pending';

            IconData matchIcon;
            Color matchColor;
            switch (status) {
              case 'matched':
                matchIcon = Icons.check_circle;
                matchColor = Colors.green;
                break;
              case 'flagged':
                matchIcon = Icons.warning;
                matchColor = Colors.orange;
                break;
              case 'resolved':
                matchIcon = Icons.task_alt;
                matchColor = Colors.blue;
                break;
              default:
                matchIcon = Icons.hourglass_top;
                matchColor = Colors.grey;
            }

            return DataRow(cells: [
              DataCell(Text(name)),
              DataCell(Text(collected)),
              DataCell(Text(expected)),
              DataCell(_buildHRStatusChip(hrStatus)),
              DataCell(Icon(matchIcon, color: matchColor)),
            ]);
          }).toList(),
        ),
      ),
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
