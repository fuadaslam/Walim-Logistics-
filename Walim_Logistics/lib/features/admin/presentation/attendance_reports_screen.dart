import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/finance/presentation/finance_notifier.dart';

final attendanceReportsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(operationsRepositoryProvider);
  return repo.fetchAttendanceReports();
});

final groupsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(operationsRepositoryProvider).fetchGroups();
});

class AttendanceReportsScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const AttendanceReportsScreen({super.key, this.initialStatus});

  @override
  ConsumerState<AttendanceReportsScreen> createState() => _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState extends ConsumerState<AttendanceReportsScreen> {
  DateTime? selectedDate;
  String? selectedPlatformId;
  String? selectedGroupId;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(attendanceReportsProvider);
    final groupsAsync = ref.watch(groupsProvider);
    final platformsAsync = ref.watch(platformsProvider);

    return DashboardScaffold(
      title: 'SHIFT MONITOR',
      subtitle: 'Track Start-of-Shift (SOS) and End-of-Shift (EOS) compliance',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.refresh(attendanceReportsProvider),
        ),
      ],
      children: [
        _buildFilters(groupsAsync, platformsAsync),
        const SizedBox(height: 24),
        reportsAsync.when(
          data: (reports) {
            final filteredReports = reports.where((r) {
              if (selectedDate != null) {
                final reportDate = DateTime.parse(r['report_date']);
                if (reportDate.year != selectedDate!.year ||
                    reportDate.month != selectedDate!.month ||
                    reportDate.day != selectedDate!.day) {
                  return false;
                }
              }
              if (selectedPlatformId != null && r['platform_id'] != selectedPlatformId) {
                return false;
              }
              if (selectedGroupId != null && r['group_id'] != selectedGroupId) {
                return false;
              }
              if (selectedStatus != null && r['status'] != selectedStatus) {
                return false;
              }
              return true;
            }).toList();

            if (filteredReports.isEmpty) {
              return const EmptyStatePlaceholder(
                icon: Icons.history_rounded,
                title: 'No reports found',
                subtitle: 'Try adjusting your filters or wait for supervisors to submit reports.',
                color: Colors.blueGrey,
              );
            }

            return _buildReportsTable(filteredReports);
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(40.0),
            child: CircularProgressIndicator(),
          )),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ],
    );
  }

  Widget _buildFilters(
    AsyncValue<List<Map<String, dynamic>>> groups,
    AsyncValue<List<Map<String, dynamic>>> platforms,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: _buildFilterItem(
              label: 'Date',
              value: selectedDate != null ? DateFormat('MMM dd, yyyy').format(selectedDate!) : 'All Dates',
              icon: Icons.calendar_today_rounded,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('Platform', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
                platforms.when(
                  data: (data) => _buildDropdown(
                    value: selectedPlatformId,
                    items: data,
                    hint: 'All Platforms',
                    onChanged: (val) => setState(() => selectedPlatformId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text('Group', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
                groups.when(
                  data: (data) => _buildDropdown(
                    value: selectedGroupId,
                    items: data,
                    hint: 'All Groups',
                    onChanged: (val) => setState(() => selectedGroupId = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Error'),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                selectedDate = null;
                selectedPlatformId = null;
                selectedGroupId = null;
                selectedStatus = null;
              });
            },
            icon: const Icon(Icons.clear_all_rounded),
            label: const Text('Clear Filters'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              foregroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: GoogleFonts.outfit(fontSize: 14)),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(value: null, child: Text(hint)),
            ...items.map((i) => DropdownMenuItem(
                  value: i['id'] as String,
                  child: Text(i['name'] as String, overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterItem({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTable(List<Map<String, dynamic>> reports) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 64,
          dataRowMinHeight: 72,
          dataRowMaxHeight: 72,
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withOpacity(0.05)),
          columns: [
            DataColumn(label: _buildTableHeader('Date')),
            DataColumn(label: _buildTableHeader('Group')),
            DataColumn(label: _buildTableHeader('Platform')),
            DataColumn(label: _buildTableHeader('Supervisor')),
            DataColumn(label: _buildTableHeader('SOS Time')),
            DataColumn(label: _buildTableHeader('EOS Time')),
            DataColumn(label: _buildTableHeader('Status')),
          ],
          rows: reports.map((report) {
            final sosAt = report['sos_submitted_at'] != null 
                ? DateFormat('HH:mm').format(DateTime.parse(report['sos_submitted_at']).toLocal())
                : '---';
            final eosAt = report['eos_submitted_at'] != null
                ? DateFormat('HH:mm').format(DateTime.parse(report['eos_submitted_at']).toLocal())
                : '---';
            
            return DataRow(cells: [
              DataCell(Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(report['report_date'])), 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
              DataCell(Text(report['groups']?['name'] ?? 'N/A', style: GoogleFonts.outfit())),
              DataCell(Text(report['platforms']?['name'] ?? 'N/A', style: GoogleFonts.outfit())),
              DataCell(Text(report['profiles']?['full_name'] ?? 'N/A', style: GoogleFonts.outfit())),
              DataCell(_buildTimeCell(sosAt, report['sos_submitted_at'] != null)),
              DataCell(_buildTimeCell(eosAt, report['eos_submitted_at'] != null)),
              DataCell(_buildStatusBadge(report['status'])),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTimeCell(String time, bool isPresent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPresent ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isPresent ? Border.all(color: AppColors.primary.withOpacity(0.1)) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPresent) Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
          if (isPresent) const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.outfit(
              color: isPresent ? AppColors.primary : AppColors.textSecondary.withOpacity(0.5),
              fontWeight: isPresent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        icon = Icons.verified_rounded;
        break;
      case 'SOS_SUBMITTED':
        color = Colors.orange;
        icon = Icons.login_rounded;
        break;
      case 'EOS_SUBMITTED':
        color = Colors.blue;
        icon = Icons.logout_rounded;
        break;
      case 'NEEDS_CORRECTION':
        color = Colors.red;
        icon = Icons.error_outline_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.replaceAll('_', ' '),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
