import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'reports_notifier.dart';
import '../models/platform_report.dart';

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
    // For a real app, we'd calculate missing based on platforms * frequency
    final missingCount = isAdminOrOps ? 3 : 0; 

    return Row(
      children: [
        _StatCard(
          title: 'Total Uploaded',
          value: '$uploadedCount',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        if (isAdminOrOps)
          _StatCard(
            title: 'Missing Reports',
            value: '$missingCount',
            icon: Icons.warning_rounded,
            color: Colors.orange,
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
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
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

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: state.reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final report = state.reports[index];
        return _ReportCard(report: report);
      },
    );
  }

  void _showUploadDialog(BuildContext context, WidgetRef ref, ReportsState state) {
    String? selectedPlatformId = state.selectedPlatformId ?? (state.platforms.length == 1 ? state.platforms.first['id'] as String : null);
    ReportFrequency selectedFrequency = state.selectedFrequency;
    DateTime selectedDate = state.selectedDate;
    String fileName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.upload_file_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Text('Upload Platform Excel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PLATFORM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedPlatformId,
                  hint: const Text('Choose platform'),
                  items: state.platforms.map((p) => DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text(p['name'] as String),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedPlatformId = v),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('REPORT FREQUENCY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                DropdownButtonFormField<ReportFrequency>(
                  value: selectedFrequency,
                  items: ReportFrequency.values.map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.name.toUpperCase()),
                  )).toList(),
                  onChanged: (v) => setState(() => selectedFrequency = v!),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('REPORT DATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('FILE SELECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.table_view_rounded, size: 48, color: Colors.green),
                      const SizedBox(height: 12),
                      Text(
                        fileName.isEmpty ? 'Select Excel or CSV File' : fileName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: fileName.isEmpty ? Colors.grey : AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => fileName = 'platform_report_${DateFormat('yyyyMMdd').format(selectedDate)}.xlsx'),
                        icon: const Icon(Icons.attach_file_rounded),
                        label: const Text('Browse Files'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: (selectedPlatformId == null || fileName.isEmpty) ? null : () {
                ref.read(reportsProvider.notifier).uploadReport(
                  fileName: fileName,
                  fileType: 'xlsx',
                  fileUrl: 'mock_url',
                  reportDate: selectedDate,
                  frequency: selectedFrequency,
                  platformId: selectedPlatformId!,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Upload Report'),
            ),
          ],
        ),
      ),
    );
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
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

class _ReportCard extends StatelessWidget {
  final PlatformReport report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.platformName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${report.frequency.name.toUpperCase()} - ${DateFormat('MMM dd, yyyy').format(report.reportDate)}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Theme.of(context).disabledColor),
                ),
                Text(
                  'By: ${report.supervisorName}',
                  style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).disabledColor.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: report.status),
              const SizedBox(height: 8),
              Text(
                DateFormat('HH:mm').format(report.uploadedAt),
                style: GoogleFonts.outfit(fontSize: 12, color: Theme.of(context).disabledColor),
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {}, // Download logic
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'uploaded' ? Colors.blue : (status == 'verified' ? Colors.green : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
