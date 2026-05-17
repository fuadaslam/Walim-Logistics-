import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/reports/models/performance_record.dart';
import 'package:walim_logistics/shared/widgets/upload_report_dialog.dart';
import 'reports_notifier.dart';
import 'performance_notifier.dart';
import '../models/platform_report.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const ReportsScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final role = auth.profile?.role ?? 'Rider';
    final canUpload = role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body = Column(
      children: [
        _TabBar(controller: _tabs, isDark: isDark),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _UploadsTab(canUpload: canUpload),
              _PerformanceTab(),
              _AnalyticsTab(),
            ],
          ),
        ),
      ],
    );

    if (!widget.showScaffold) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('PLATFORM REPORTS')),
      body: body,
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => _showUploadSheet(context),
              label: const Text('Upload'),
              icon: const Icon(Icons.upload_file_rounded),
            )
          : null,
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UploadReportDialog(),
    ).then((ok) {
      if (ok == true) {
        ref.read(reportsProvider.notifier).loadReports();
        ref.read(performanceProvider.notifier).loadData();
      }
    });
  }
}

// ── Tab bar ─────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;

  const _TabBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Uploads'),
          Tab(text: 'Performance'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }
}

// ── UPLOADS TAB ─────────────────────────────────────────────────────────────

class _UploadsTab extends ConsumerWidget {
  final bool canUpload;
  const _UploadsTab({required this.canUpload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _UploadFilters(state: state, ref: ref),
          const SizedBox(height: 12),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.reports.isEmpty
                    ? _emptyState('No reports uploaded yet', 'Upload your first platform report', Icons.upload_file_outlined)
                    : _UploadList(reports: state.reports, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _UploadFilters extends StatelessWidget {
  final ReportsState state;
  final WidgetRef ref;
  const _UploadFilters({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterDrop<String?>(
            icon: Icons.hub_rounded,
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
        const SizedBox(width: 10),
        Expanded(
          child: _FilterDrop<ReportFrequency>(
            icon: Icons.schedule_rounded,
            value: state.selectedFrequency,
            items: ReportFrequency.values.map((f) => DropdownMenuItem(
              value: f,
              child: Text(f.name.toUpperCase()),
            )).toList(),
            onChanged: (v) => ref.read(reportsProvider.notifier).setFrequency(v!),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.read(reportsProvider.notifier).loadReports(),
        ),
      ],
    );
  }
}

class _UploadList extends StatelessWidget {
  final List<PlatformReport> reports;
  final bool isDark;
  const _UploadList({required this.reports, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UploadCard(report: reports[i], isDark: isDark),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final PlatformReport report;
  final bool isDark;
  const _UploadCard({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_fileIcon(report.fileType), color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.platformName,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  report.fileName,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(report.reportDate),
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          _StatusBadge(status: report.status),
        ],
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'excel': return Icons.table_chart_rounded;
      case 'csv': return Icons.grid_on_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}

// ── PERFORMANCE TAB ─────────────────────────────────────────────────────────

class _PerformanceTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PerformanceTab> createState() => _PerformanceTabState();
}

class _PerformanceTabState extends ConsumerState<_PerformanceTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(performanceProvider);
    final perfState = ref.watch(reportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = state.records
        .where((r) =>
            _search.isEmpty ||
            r.riderName.toLowerCase().contains(_search.toLowerCase()) ||
            r.externalRiderId.contains(_search))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _PerfFilters(
            state: state,
            platforms: perfState.platforms,
            onPlatformChanged: (id) => ref.read(performanceProvider.notifier).setPlatform(id),
            onSearchChanged: (v) => setState(() => _search = v),
            onRefresh: () => ref.read(performanceProvider.notifier).loadData(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _emptyState(
                        'No performance data',
                        'Upload platform reports to see rider metrics',
                        Icons.analytics_outlined,
                      )
                    : _PerformanceTable(records: filtered, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _PerfFilters extends StatelessWidget {
  final PerformanceState state;
  final List<Map<String, dynamic>> platforms;
  final ValueChanged<String?> onPlatformChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;

  const _PerfFilters({
    required this.state,
    required this.platforms,
    required this.onPlatformChanged,
    required this.onSearchChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onSearchChanged,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search rider name or ID…',
            hintStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FilterDrop<String?>(
                icon: Icons.hub_rounded,
                value: state.selectedPlatformId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Platforms')),
                  ...platforms.map((p) => DropdownMenuItem(
                    value: p['id'] as String,
                    child: Text(p['name'] as String),
                  )),
                ],
                onChanged: onPlatformChanged,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
            ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceTable extends StatelessWidget {
  final List<PerformanceRecord> records;
  final bool isDark;
  const _PerformanceTable({required this.records, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(
                isDark ? Colors.white.withValues(alpha: 0.03) : AppColors.background.withValues(alpha: 0.8),
              ),
              dataRowMaxHeight: 72,
              dataRowMinHeight: 60,
              dividerThickness: 0.5,
              horizontalMargin: 20,
              columnSpacing: 20,
              columns: [
                _col('RIDER', Icons.person_rounded),
                _col('PLATFORM', Icons.hub_rounded),
                _col('DATE', Icons.calendar_today_rounded),
                _col('ORDERS', Icons.local_shipping_rounded),
                _col('ON-TIME %', Icons.timer_rounded),
                _col('COMPLIANCE %', Icons.verified_rounded),
                _col('HRS WORKED', Icons.schedule_rounded),
                _col('AVG DELAY', Icons.hourglass_bottom_rounded),
              ],
              rows: records.map((r) => DataRow(cells: [
                DataCell(_riderCell(r)),
                DataCell(Text(
                  r.platformName.isNotEmpty ? r.platformName : r.reportType.displayName,
                  style: GoogleFonts.outfit(fontSize: 13),
                )),
                DataCell(Text(
                  DateFormat('MMM dd').format(r.recordDate),
                  style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                )),
                DataCell(Text(
                  r.totalOrders?.toString() ?? '—',
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                )),
                DataCell(_PctCell(value: r.deliveryOntimePct)),
                DataCell(_PctCell(value: r.shiftCompliancePct)),
                DataCell(Text(
                  r.workingHours != null ? r.workingHours!.toStringAsFixed(1) : '—',
                  style: GoogleFonts.outfit(fontSize: 13),
                )),
                DataCell(Text(
                  r.avgDelayMin != null ? '${r.avgDelayMin!.toStringAsFixed(0)}m' : '—',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: r.avgDelayMin != null && r.avgDelayMin! > 30 ? Colors.red : null,
                  ),
                )),
              ])).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _col(String label, IconData icon) {
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderCell(PerformanceRecord r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(r.riderName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(
          'ID: ${r.externalRiderId}',
          style: GoogleFonts.outfit(fontSize: 10, color: AppColors.textSecondary),
        ),
        if (r.riderId != null)
          const Icon(Icons.link_rounded, size: 12, color: Colors.green),
      ],
    );
  }
}

class _PctCell extends StatelessWidget {
  final double? value;
  const _PctCell({this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null) return Text('—', style: GoogleFonts.outfit(fontSize: 13));
    final pct = value!.clamp(0, 100).toDouble();
    Color color;
    if (pct >= 85) {
      color = const Color(0xFF10B981);
    } else if (pct >= 60) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${pct.toStringAsFixed(1)}%',
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

// ── ANALYTICS TAB ────────────────────────────────────────────────────────────

class _AnalyticsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(performanceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (state.loading) return const Center(child: CircularProgressIndicator());

    if (state.records.isEmpty) {
      return _emptyState(
        'No data to analyse',
        'Upload platform reports to see analytics',
        Icons.bar_chart_rounded,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards row
          _SummaryCards(state: state),
          const SizedBox(height: 20),

          // Platform comparison
          if (state.avgByPlatform.isNotEmpty) ...[
            _SectionHeader('Platform Comparison', Icons.hub_rounded),
            const SizedBox(height: 12),
            _PlatformBars(data: state.avgByPlatform),
            const SizedBox(height: 20),
          ],

          // Top performers
          if (state.topPerformers.isNotEmpty) ...[
            _SectionHeader('Top Performers', Icons.emoji_events_rounded),
            const SizedBox(height: 12),
            _RankedList(records: state.topPerformers, isDark: isDark, isTop: true),
            const SizedBox(height: 20),
          ],

          // Needs attention
          if (state.bottomPerformers.isNotEmpty) ...[
            _SectionHeader('Needs Attention', Icons.warning_amber_rounded),
            const SizedBox(height: 12),
            _RankedList(records: state.bottomPerformers, isDark: isDark, isTop: false),
            const SizedBox(height: 20),
          ],

          // Shift data
          if (state.shifts.isNotEmpty) ...[
            _SectionHeader('Shift Schedule Coverage', Icons.calendar_month_rounded),
            const SizedBox(height: 12),
            _ShiftSummary(shifts: state.shifts, isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final PerformanceState state;
  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          label: 'Avg Delivery On-Time',
          value: '${state.avgDeliveryOntime.toStringAsFixed(1)}%',
          icon: Icons.local_shipping_rounded,
          color: _rateColor(state.avgDeliveryOntime),
        ),
        _StatCard(
          label: 'Avg Shift Compliance',
          value: '${state.avgShiftCompliance.toStringAsFixed(1)}%',
          icon: Icons.verified_rounded,
          color: _rateColor(state.avgShiftCompliance),
        ),
        _StatCard(
          label: 'Total Orders',
          value: _fmt(state.totalOrders),
          icon: Icons.receipt_long_rounded,
          color: AppColors.accent,
        ),
        _StatCard(
          label: 'Riders Tracked',
          value: '${state.records.map((r) => r.externalRiderId).toSet().length}',
          icon: Icons.people_rounded,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Color _rateColor(double v) {
    if (v >= 85) return const Color(0xFF10B981);
    if (v >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  )),
              Text(label,
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlatformBars extends StatelessWidget {
  final Map<String, double> data;
  const _PlatformBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: sorted.map((e) {
          final pct = e.value.clamp(0, 100).toDouble();
          Color barColor;
          if (pct >= 85) {
            barColor = const Color(0xFF10B981);
          } else if (pct >= 60) {
            barColor = const Color(0xFFF59E0B);
          } else {
            barColor = const Color(0xFFEF4444);
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: barColor,
                        )),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    backgroundColor: barColor.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankedList extends StatelessWidget {
  final List<PerformanceRecord> records;
  final bool isDark;
  final bool isTop;
  const _RankedList({required this.records, required this.isDark, required this.isTop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: records.asMap().entries.map((e) {
          final idx = e.key;
          final r = e.value;
          final color = isTop ? const Color(0xFF10B981) : const Color(0xFFEF4444);
          return Column(
            children: [
              ListTile(
                dense: true,
                leading: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                title: Text(r.riderName, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  '${r.platformName.isNotEmpty ? r.platformName : r.reportType.displayName} · ${DateFormat('MMM dd').format(r.recordDate)}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textSecondary),
                ),
                trailing: _PctCell(value: r.deliveryOntimePct),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
              if (idx < records.length - 1)
                Divider(height: 1, color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ShiftSummary extends StatelessWidget {
  final List<ShiftRecord> shifts;
  final bool isDark;
  const _ShiftSummary({required this.shifts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final byArea = <String, int>{};
    for (final s in shifts) {
      if (s.area.isNotEmpty) {
        byArea[s.area] = (byArea[s.area] ?? 0) + 1;
      }
    }
    final sorted = byArea.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Total shift assignments: ',
                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
            Text('${shifts.length}',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...sorted.take(8).map((e) {
            final frac = e.value / shifts.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(e.key,
                        style: GoogleFonts.outfit(fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: frac,
                        minHeight: 8,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ],
    );
  }
}

class _FilterDrop<T> extends StatelessWidget {
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDrop({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              underline: const SizedBox(),
              isDense: true,
              style: GoogleFonts.outfit(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 13,
              ),
            ),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'uploaded':
      case 'verified':
      case 'approved':
        color = const Color(0xFF10B981);
        break;
      case 'pending':
      case 'draft':
        color = const Color(0xFFF59E0B);
        break;
      case 'missing':
      case 'rejected':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF64748B);
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

Widget _emptyState(String title, String subtitle, IconData icon) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(title,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 13)),
      ],
    ),
  );
}
