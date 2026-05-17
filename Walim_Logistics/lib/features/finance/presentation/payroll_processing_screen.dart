import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class _StaffPayroll {
  final String id;
  final String name;
  final String role;
  final int shiftDays;
  final double bonusTotal;
  final double penaltyTotal;

  const _StaffPayroll({
    required this.id,
    required this.name,
    required this.role,
    required this.shiftDays,
    required this.bonusTotal,
    required this.penaltyTotal,
  });

  double get netAdjustment => bonusTotal - penaltyTotal;
}

final payrollDataProvider =
    FutureProvider.autoDispose<List<_StaffPayroll>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1).toIso8601String();

  final profiles = await supabase
      .from('profiles')
      .select('id, full_name, roles(name)')
      .or('status.eq.active,status.eq.Active_Completed,status.eq.Active_Pending');

  if ((profiles as List).isEmpty) return [];

  final profileIds = profiles.map((p) => p['id'] as String).toList();

  final attendance = await supabase
      .from('attendance')
      .select('profile_id')
      .inFilter('profile_id', profileIds)
      .eq('attendance_type', 'shift')
      .gte('check_in_time', monthStart);

  final adjustments = await supabase
      .from('penalties_bonuses')
      .select('profile_id, type, amount')
      .inFilter('profile_id', profileIds)
      .gte('created_at', monthStart);

  final shiftCounts = <String, int>{};
  for (final a in attendance as List) {
    final id = a['profile_id'] as String;
    shiftCounts[id] = (shiftCounts[id] ?? 0) + 1;
  }

  final bonusTotals = <String, double>{};
  final penaltyTotals = <String, double>{};
  for (final a in adjustments as List) {
    final id = a['profile_id'] as String;
    final amt = (a['amount'] as num?)?.toDouble() ?? 0;
    if (a['type'] == 'bonus') {
      bonusTotals[id] = (bonusTotals[id] ?? 0) + amt;
    } else {
      penaltyTotals[id] = (penaltyTotals[id] ?? 0) + amt;
    }
  }

  final result = profiles.map<_StaffPayroll>((p) {
    final id = p['id'] as String;
    final roleData = p['roles'];
    final roleName =
        roleData is Map ? (roleData['name'] as String? ?? 'Staff') : 'Staff';
    return _StaffPayroll(
      id: id,
      name: p['full_name'] as String? ?? 'Unknown',
      role: roleName,
      shiftDays: shiftCounts[id] ?? 0,
      bonusTotal: bonusTotals[id] ?? 0,
      penaltyTotal: penaltyTotals[id] ?? 0,
    );
  }).toList();

  result.sort((a, b) => b.shiftDays.compareTo(a.shiftDays));
  return result;
});

class PayrollProcessingScreen extends ConsumerWidget {
  const PayrollProcessingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollAsync = ref.watch(payrollDataProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(DateTime.now());

    return DashboardScaffold(
      title: 'PAYROLL PROCESSING',
      subtitle: 'Attendance & adjustments — $monthLabel',
      showBackButton: true,
      children: [
        payrollAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (staff) =>
              _PayrollContent(staff: staff, monthLabel: monthLabel),
        ),
      ],
    );
  }
}

class _PayrollContent extends StatelessWidget {
  final List<_StaffPayroll> staff;
  final String monthLabel;

  const _PayrollContent(
      {required this.staff, required this.monthLabel});

  @override
  Widget build(BuildContext context) {
    final totalBonus = staff.fold(0.0, (s, p) => s + p.bonusTotal);
    final totalPenalty = staff.fold(0.0, (s, p) => s + p.penaltyTotal);
    final totalDays = staff.fold(0, (s, p) => s + p.shiftDays);
    final currFmt = NumberFormat('#,##0.00');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF334155)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Period',
                          style:
                              TextStyle(color: Colors.white60, fontSize: 12)),
                      Text(monthLabel,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${staff.length} staff',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat(
                      'Total Shifts', '$totalDays days', Colors.blue.shade200),
                  _buildHeaderStat('Bonuses',
                      '﷼ ${currFmt.format(totalBonus)}', Colors.green.shade200),
                  _buildHeaderStat(
                      'Penalties',
                      '﷼ ${currFmt.format(totalPenalty)}',
                      Colors.red.shade200),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Base salary requires HR configuration. Showing shifts attended and adjustments.',
            style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 16),
        Text('Staff Adjustments',
            style:
                GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        if (staff.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No active staff found.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ...staff.map((s) => _StaffPayrollTile(staff: s)),
      ],
    );
  }

  Widget _buildHeaderStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _StaffPayrollTile extends StatelessWidget {
  final _StaffPayroll staff;

  const _StaffPayrollTile({required this.staff});

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat('#,##0.00');
    final net = staff.netAdjustment;
    final netColor = net >= 0 ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color:
                Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              staff.name.isNotEmpty ? staff.name[0] : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text(staff.role,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${staff.shiftDays} shifts',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AppColors.textSecondary)),
              if (staff.bonusTotal > 0 || staff.penaltyTotal > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${net >= 0 ? '+' : ''}﷼ ${currFmt.format(net)}',
                  style: GoogleFonts.outfit(
                      color: netColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
