import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'reports_notifier.dart';
import '../models/platform_report.dart';
import 'package:walim_logistics/shared/widgets/upload_report_dialog.dart';

class ReportsScreen extends ConsumerWidget {
  final bool showScaffold;
  const ReportsScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final authState = ref.watch(authProvider);
    final role = authState.profile?.role ?? 'Rider';
    final isAdminOrOps = role == 'Admin' || role == 'Operations Manager';

    Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStats(context, state, isAdminOrOps),
        const SizedBox(height: 24),
        _buildFilters(context, ref, state),
        const SizedBox(height: 16),
        Expanded(
          child: state.loading 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildReportList(context, state),
        ),
      ],
    );

    if (!showScaffold) return body;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PLATFORM REPORTS'),
        actions: [
          if (role == 'Supervisor' || role == 'Admin')
            IconButton(
              icon: const Icon(Icons.upload_file_rounded),
              onPressed: () => _showUploadDialog(context, ref, state),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: body,
      ),
      floatingActionButton: (role == 'Supervisor' || role == 'Admin')
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadDialog(context, ref, state),
              label: const Text('Upload Report'),
              icon: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _buildStats(BuildContext context, ReportsState state, bool isAdminOrOps) {
    final uploadedCount = state.reports.length;
    // Platforms that have no upload for the currently selected date
    final selectedDateStr = state.selectedDate.toIso8601String().split('T')[0];
    final uploadedPlatformIds = state.reports
        .where((r) => r.reportDate.toIso8601String().split('T')[0] == selectedDateStr)
        .map((r) => r.platformId)
        .toSet();
    final missingCount = isAdminOrOps
        ? state.platforms.where((p) => !uploadedPlatformIds.contains(p['id'] as String)).length
        : 0;

    final color = Colors.grey.shade500;
    return Row(
      children: [
        _StatCard(
          title: 'Total Uploaded',
          value: '$uploadedCount',
          icon: Icons.check_circle_rounded,
          color: color,
        ),
        const SizedBox(width: 16),
        if (isAdminOrOps)
          _StatCard(
            title: 'Missing Reports',
            value: '$missingCount',
            icon: Icons.warning_rounded,
            color: color,
          ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, WidgetRef ref, ReportsState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DropdownFilter(
              label: 'Platform',
              value: state.selectedPlatformId,
              items: [
                const DropdownMenuItem(value: null, child: Text('All Platforms')),
                ...state.platforms.map((p) => DropdownMenuItem(
                  value: p['id'] as String,
                  child: Text(p['name'] as String),
                )),
              ],
              onChanged: (v) => ref.read(reportsProvider.notifier).setPlatform(v),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _DropdownFilter(
              label: 'Frequency',
              value: state.selectedFrequency,
              items: ReportFrequency.values.map((f) => DropdownMenuItem(
                value: f,
                child: Text(f.name.toUpperCase()),
              )).toList(),
              onChanged: (v) => ref.read(reportsProvider.notifier).setFrequency(v!),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(reportsProvider.notifier).loadReports(),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(BuildContext context, ReportsState state) {
    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(
              'No reports found',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or upload a new report',
              style: GoogleFonts.outfit(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.background.withValues(alpha: 0.5)),
              dataRowMaxHeight: 75,
              dataRowMinHeight: 65,
              dividerThickness: 0.5,
              horizontalMargin: 24,
              columnSpacing: 12,
              columns: [
                DataColumn(label: _buildHeaderLabel('PLATFORM', Icons.hub_rounded)),
                DataColumn(label: _buildHeaderLabel('FREQUENCY', Icons.schedule_rounded)),
                DataColumn(label: _buildHeaderLabel('SUPERVISOR', Icons.supervisor_account_rounded)),
                DataColumn(label: _buildHeaderLabel('STATUS', Icons.info_outline_rounded)),
              ],
              rows: state.reports.map((report) => DataRow(
                onSelectChanged: (_) {
                  // Download or view report
                },
                cells: [
                  DataCell(_buildPlatformCell(report)),
                  DataCell(Text(report.frequency.name.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Text(report.supervisorName, style: GoogleFonts.outfit(color: AppColors.textSecondary))),
                  DataCell(_StatusBadge(status: report.status)),
                ],
              )).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCell(PlatformReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          report.platformName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          DateFormat('MMM dd, yyyy').format(report.reportDate),
          style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref, ReportsState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UploadReportDialog(),
    ).then((success) {
      if (success == true) {
        ref.read(reportsProvider.notifier).loadReports();
      }
    });
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
                Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).disabledColor)),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          underline: const SizedBox(),
          style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14),
        ),
      ],
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'uploaded':
      case 'verified':
      case 'approved':
      case 'complete':
        color = const Color(0xFF10B981); // Emerald Green
        break;
      case 'pending':
      case 'draft':
        color = const Color(0xFFF59E0B); // Amber / Yellow
        break;
      case 'missing':
      case 'rejected':
      case 'failed':
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        color = const Color(0xFF64748B); // Slate Grey
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
