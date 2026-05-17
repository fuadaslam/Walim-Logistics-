import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/performance/presentation/performance_notifier.dart';
import 'package:intl/intl.dart';

class MyPerformanceScreen extends ConsumerWidget {
  final bool showScaffold;
  const MyPerformanceScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showScaffold) {
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildContent(context, ref),
              ]),
            ),
          ),
        ],
      );
    }

    return DashboardScaffold(
      title: 'MY PERFORMANCE',
      subtitle: 'Your score, targets, and this month\'s adjustments',
      showBackButton: true,
      activeItem: 'Performance',
      children: [
        _buildContent(context, ref),
      ],
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(myPerformanceProvider);
    final targetsAsync = ref.watch(myTargetsProvider);
    final adjAsync = ref.watch(myAdjustmentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        perfAsync.when(
          data: (perf) => _buildScoreCard(context, perf),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('My Targets This Month'),
        const SizedBox(height: 16),
        targetsAsync.when(
          data: (targets) => targets.isEmpty
              ? _buildEmptyState('No targets set yet')
              : Column(children: targets.map((t) => _buildTargetRow(context, t)).toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('Adjustments This Month'),
        const SizedBox(height: 16),
        adjAsync.when(
          data: (adj) => adj.isEmpty
              ? _buildEmptyState('No penalties or bonuses this month')
              : Column(children: adj.map((a) => _buildAdjustmentRow(context, a)).toList()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, Map<String, dynamic> perf) {
    final baseScore = (perf['baseScore'] as double? ?? 0).round();
    final attScore = (perf['attendanceScore'] as double? ?? 0);
    final incScore = (perf['incidentScore'] as double? ?? 0);
    final bonus = perf['bonusTotal'] as double? ?? 0;
    final penalty = perf['penaltyTotal'] as double? ?? 0;
    final net = perf['netAdjustment'] as double? ?? 0;
    final currencyFmt = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 0);

    Color scoreColor;
    String scoreLabel;
    if (baseScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (baseScore >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Improvement';
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Score',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$baseScore',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, left: 4),
                          child: Text(
                            '/${(perf['maxScore'] as num?)?.toInt() ?? 90}',
                            style: GoogleFonts.outfit(
                              color: Colors.white60,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        scoreLabel,
                        style: GoogleFonts.outfit(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bonus > 0)
                    _buildAdjBadge('+${currencyFmt.format(bonus)}', Colors.green),
                  if (penalty > 0) ...[
                    const SizedBox(height: 8),
                    _buildAdjBadge('-${currencyFmt.format(penalty)}', Colors.red),
                  ],
                  if (net != 0) ...[
                    const SizedBox(height: 8),
                    _buildAdjBadge(
                      'Net: ${net > 0 ? '+' : ''}${currencyFmt.format(net)}',
                      net > 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildScoreBreakdown('Attendance', attScore, (perf['weightAtt'] as num?)?.toDouble() ?? 40, Colors.blue),
              const SizedBox(width: 12),
              _buildScoreBreakdown('Incidents', incScore, (perf['weightInc'] as num?)?.toDouble() ?? 20, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdjBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildScoreBreakdown(String label, double score, double max, Color color) {
    final pct = (score / max).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11),
              ),
              Text(
                '${score.round()}/${max.toInt()}',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(BuildContext context, Map<String, dynamic> target) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final metric = target['metric'] as String? ?? '';
    final targetVal = (target['target_value'] as num?)?.toDouble() ?? 0;

    final metricLabel = {
      'attendance_rate': 'Attendance Rate',
      'delivery_count': 'Deliveries',
      'incident_free_days': 'Incident-Free Days',
    }[metric] ?? metric;

    final metricIcon = {
      'attendance_rate': Icons.fact_check_outlined,
      'delivery_count': Icons.local_shipping_outlined,
      'incident_free_days': Icons.shield_outlined,
    }[metric] ?? Icons.flag_outlined;

    final metricColor = {
      'attendance_rate': Colors.blue,
      'delivery_count': Colors.orange,
      'incident_free_days': Colors.purple,
    }[metric] ?? AppColors.primary;

    final suffix = metric == 'attendance_rate' ? '%' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white10 : AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: metricColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metricIcon, color: metricColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              metricLabel,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: metricColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Target: ${targetVal % 1 == 0 ? targetVal.toInt() : targetVal}$suffix',
              style: GoogleFonts.outfit(
                color: metricColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentRow(BuildContext context, Map<String, dynamic> adj) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isBonus = adj['type'] == 'bonus';
    final color = isBonus ? Colors.green : Colors.red;
    final amount = (adj['amount'] as num?)?.toDouble() ?? 0;
    final currencyFmt = NumberFormat.compactCurrency(symbol: '﷼ ', decimalDigits: 0);
    final date = adj['created_at'] != null
        ? DateFormat('MMM d').format(DateTime.parse(adj['created_at']).toLocal())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isDarkMode ? 0.2 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isBonus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  adj['reason'] as String? ?? '',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  '${adj['category'] ?? ''} • $date',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isBonus ? '+' : '-'}${currencyFmt.format(amount)}',
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
