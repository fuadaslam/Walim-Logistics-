import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'supervisor_notifier.dart';

class DailyShiftControlScreen extends ConsumerStatefulWidget {
  final bool showScaffold;

  const DailyShiftControlScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<DailyShiftControlScreen> createState() =>
      _DailyShiftControlScreenState();
}

class _DailyShiftControlScreenState
    extends ConsumerState<DailyShiftControlScreen> {
  final _correctionController = TextEditingController();

  @override
  void dispose() {
    _correctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (!widget.showScaffold) return body;

    return DashboardScaffold(
      title: 'DAILY SHIFT CONTROL',
      subtitle: 'SOS · EOS · Attendance · Validation',
      showBackButton: true,
      activeItem: 'Dashboard',
      children: [body],
    );
  }

  Widget _buildBody(BuildContext context) {
    final state = ref.watch(shiftControlProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SelectionPanel(isDark: isDark),
        const SizedBox(height: 20),
        if (state.report != null) ...[
          _StatusStepper(status: state.reportStatus, isDark: isDark),
          const SizedBox(height: 20),
          if (state.error != null)
            _ErrorBanner(message: state.error!),
          _buildPhaseContent(context, state, isDark),
        ] else if (state.loading) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
        ] else ...[
          _EmptyState(isDark: isDark),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPhaseContent(
      BuildContext context, ShiftControlState state, bool isDark) {
    switch (state.reportStatus) {
      case 'DRAFT':
      case 'SOS_SUBMITTED':
        if (state.reportStatus == 'SOS_SUBMITTED') {
          return _EOSSection(isDark: isDark);
        }
        return _SOSSection(isDark: isDark);
      case 'EOS_SUBMITTED':
        return _UploadSection(isDark: isDark);
      case 'PENDING_ANALYSIS':
        return _PendingSection(isDark: isDark);
      case 'NEEDS_CORRECTION':
        return _CorrectionSection(
          isDark: isDark,
          controller: _correctionController,
        );
      case 'APPROVED':
        return _ApprovedSection(isDark: isDark);
      default:
        return _SOSSection(isDark: isDark);
    }
  }
}

// ---------------------------------------------------------------------------
// Selection Panel
// ---------------------------------------------------------------------------

class _SelectionPanel extends ConsumerStatefulWidget {
  final bool isDark;
  const _SelectionPanel({required this.isDark});

  @override
  ConsumerState<_SelectionPanel> createState() => _SelectionPanelState();
}

class _SelectionPanelState extends ConsumerState<_SelectionPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);
    final theme = Theme.of(context);

    return _Card(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.tune_rounded,
            label: 'Shift Setup',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 16),

          // Date picker row
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 7)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) notifier.selectDate(picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEE, d MMM yyyy').format(state.selectedDate),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  Icon(Icons.edit_calendar_rounded,
                      size: 16, color: theme.textTheme.bodyMedium?.color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Platform dropdown
          _buildDropdown<String>(
            theme: theme,
            hint: 'Select Platform',
            icon: Icons.store_rounded,
            value: state.selectedPlatformId,
            items: state.platforms
                .map((p) => DropdownMenuItem<String>(
                      value: p['id'] as String,
                      child: Text(p['name'] as String),
                    ))
                .toList(),
            onChanged: notifier.selectPlatform,
          ),
          const SizedBox(height: 12),

          // Group dropdown
          _buildDropdown<String>(
            theme: theme,
            hint: 'Select Group',
            icon: Icons.groups_rounded,
            value: state.selectedGroupId,
            items: state.groups
                .where((g) =>
                    state.selectedPlatformId == null ||
                    g['platform_id'] == state.selectedPlatformId)
                .map((g) => DropdownMenuItem<String>(
                      value: g['id'] as String,
                      child: Text(g['name'] as String),
                    ))
                .toList(),
            onChanged: notifier.selectGroup,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  state.canLoadReport && !state.loading
                      ? () => notifier.loadReport()
                      : null,
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                state.report == null ? 'Load / Create Report' : 'Reload Report',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required ThemeData theme,
    required String hint,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(hint,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
                isExpanded: true,
                items: items,
                onChanged: onChanged,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Stepper
// ---------------------------------------------------------------------------

class _StatusStepper extends StatelessWidget {
  final String status;
  final bool isDark;

  const _StatusStepper({required this.status, required this.isDark});

  static const _steps = [
    'DRAFT',
    'SOS_SUBMITTED',
    'EOS_SUBMITTED',
    'PENDING_ANALYSIS',
    'APPROVED',
  ];

  static const _labels = [
    'Draft',
    'SOS',
    'EOS',
    'Validating',
    'Approved',
  ];

  static const _icons = [
    Icons.edit_note_rounded,
    Icons.login_rounded,
    Icons.logout_rounded,
    Icons.analytics_rounded,
    Icons.check_circle_rounded,
  ];

  int get _currentIndex {
    if (status == 'NEEDS_CORRECTION') return 3;
    return _steps.indexOf(status).clamp(0, _steps.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final isError = status == 'NEEDS_CORRECTION';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isError
            ? Colors.red.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isError
              ? Colors.red.withValues(alpha: 0.2)
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            final filled = stepIdx < _currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: filled
                    ? AppColors.primary
                    : (isDark ? Colors.white24 : Colors.black12),
              ),
            );
          }

          final stepIdx = i ~/ 2;
          final isActive = stepIdx == _currentIndex;
          final isDone = stepIdx < _currentIndex;
          final stepColor = isError && isActive
              ? Colors.red
              : (isActive || isDone ? AppColors.primary : Colors.grey);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isActive || isDone)
                      ? stepColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: stepColor.withValues(alpha: isActive ? 1 : 0.4),
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : _icons[stepIdx],
                  size: 18,
                  color: stepColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[stepIdx],
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w400,
                  color: stepColor,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SOS Section
// ---------------------------------------------------------------------------

class _SOSSection extends ConsumerStatefulWidget {
  final bool isDark;
  const _SOSSection({required this.isDark});

  @override
  ConsumerState<_SOSSection> createState() => _SOSSectionState();
}

class _SOSSectionState extends ConsumerState<_SOSSection> {
  bool _showAddRider = false;
  final _nameCtrl = TextEditingController();
  final _iqamaCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iqamaCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);

    final presentCount = state.attendanceItems
        .where((i) => i.attendanceStatus == 'present')
        .length;
    final absentCount = state.attendanceItems
        .where((i) => i.attendanceStatus == 'absent')
        .length;
    final manualCount =
        state.attendanceItems.where((i) => i.isManualAddition).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary chips
        _Card(
          isDark: widget.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.login_rounded,
                label: 'Start of Shift (SOS) — Attendance',
                isDark: widget.isDark,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                      label: 'Total',
                      count: state.attendanceItems.length,
                      color: AppColors.primary),
                  _StatChip(
                      label: 'Present',
                      count: presentCount,
                      color: Colors.green),
                  _StatChip(
                      label: 'Absent',
                      count: absentCount,
                      color: Colors.red),
                  if (manualCount > 0)
                    _StatChip(
                        label: 'Manual',
                        count: manualCount,
                        color: Colors.orange),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rider list
        if (state.attendanceItems.isEmpty)
          _Card(
            isDark: widget.isDark,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 40,
                        color: Colors.grey.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    Text(
                      'No riders planned for this shift.\nAdd riders manually using the button below.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                          color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          _Card(
            isDark: widget.isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.list_alt_rounded,
                  label: 'Rider List',
                  isDark: widget.isDark,
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.attendanceItems.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 48),
                  itemBuilder: (context, index) {
                    final item = state.attendanceItems[index];
                    return _RiderRow(
                      item: item,
                      index: index,
                      isDark: widget.isDark,
                      onStatusChanged: (s) =>
                          notifier.updateAttendanceStatus(index, s),
                      onReasonChanged: (r) =>
                          notifier.updateAbsenceReason(index, r),
                    );
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // Add manual rider
        _Card(
          isDark: widget.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _SectionHeader(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Add Newly Joined Rider',
                    isDark: widget.isDark,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        setState(() => _showAddRider = !_showAddRider),
                    icon: Icon(
                      _showAddRider
                          ? Icons.expand_less_rounded
                          : Icons.add_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_showAddRider) ...[
                const SizedBox(height: 12),
                _buildTextField(_nameCtrl, 'Full Name', Icons.person_rounded),
                const SizedBox(height: 8),
                _buildTextField(
                    _iqamaCtrl, 'Iqama / ID Number', Icons.badge_rounded),
                const SizedBox(height: 8),
                _buildTextField(
                    _reasonCtrl, 'Reason for manual addition', Icons.note_rounded),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_nameCtrl.text.trim().isEmpty ||
                          _reasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Name and reason are required.')),
                        );
                        return;
                      }
                      notifier.addManualRider(
                        name: _nameCtrl.text.trim(),
                        iqama: _iqamaCtrl.text.trim(),
                        reason: _reasonCtrl.text.trim(),
                      );
                      _nameCtrl.clear();
                      _iqamaCtrl.clear();
                      _reasonCtrl.clear();
                      setState(() => _showAddRider = false);
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text('Add Rider',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Shift context — incidents, leave, pending requests
        _ShiftContextPanel(isDark: widget.isDark),
        const SizedBox(height: 12),

        // Handover Verification Checklist
        _Card(
          isDark: widget.isDark,
          child: _VerificationChecklist(
            checklist: state.verificationChecklist,
            onToggle: notifier.toggleVerification,
            title: 'Shift Handover Verification',
          ),
        ),
        const SizedBox(height: 12),

        // Handover Notes
        _Card(
          isDark: widget.isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.note_alt_rounded,
                label: 'Handover Notes',
                isDark: widget.isDark,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: notifier.updateHandoverNotes,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Add any specific instructions or issues for the next shift...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Submit SOS
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (state.loading || !state.allVerified)
                ? null
                : () async {
                    final err =
                        await ref.read(shiftControlProvider.notifier).submitSOS();
                    if (err != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
            icon: state.loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.login_rounded),
            label: Text(
              'SUBMIT SOS',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.allVerified ? AppColors.primary : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (!state.allVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Complete all verification checks above to submit SOS',
                style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isDense: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rider Row
// ---------------------------------------------------------------------------

class _RiderRow extends StatelessWidget {
  final RiderAttendanceItem item;
  final int index;
  final bool isDark;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onReasonChanged;

  const _RiderRow({
    required this.item,
    required this.index,
    required this.isDark,
    required this.onStatusChanged,
    required this.onReasonChanged,
  });

  static const _statuses = ['present', 'absent', 'leave', 'suspended'];
  static const _statusColors = {
    'present': Colors.green,
    'absent': Colors.red,
    'leave': Colors.orange,
    'suspended': Colors.grey,
    'carry_over': Colors.blue,
  };

  @override
  Widget build(BuildContext context) {
    final statusColor =
        _statusColors[item.attendanceStatus] ?? Colors.grey;
    final isReadOnly = item.isCarryOver;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Text(
                  item.riderName.isNotEmpty
                      ? item.riderName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),

              // Name + tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.riderName,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isManualAddition) ...[
                          const SizedBox(width: 6),
                          _MiniTag(label: 'Manual', color: Colors.orange),
                        ],
                        if (item.isCarryOver) ...[
                          const SizedBox(width: 6),
                          _MiniTag(label: 'Carry-over', color: Colors.blue),
                        ],
                      ],
                    ),
                    if (item.riderIqama != null)
                      Text(
                        item.riderIqama!,
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
              ),

              // Status selector
              if (!isReadOnly)
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: item.attendanceStatus,
                    isDense: true,
                    borderRadius: BorderRadius.circular(10),
                    items: _statuses
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _statusColors[s],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(_capitalize(s),
                                      style:
                                          GoogleFonts.outfit(fontSize: 13)),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onStatusChanged(v);
                    },
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Carry-over',
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          // Absence reason field
          if (item.attendanceStatus == 'absent' && !isReadOnly) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: TextField(
                onChanged: onReasonChanged,
                controller: TextEditingController(text: item.absenceReason)
                  ..selection = TextSelection.collapsed(
                      offset: item.absenceReason?.length ?? 0),
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Absence reason (required)',
                  hintStyle: GoogleFonts.outfit(
                      fontSize: 13, color: Colors.red.withValues(alpha: 0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                  suffixIcon: const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// EOS Section
// ---------------------------------------------------------------------------

class _EOSSection extends ConsumerWidget {
  final bool isDark;
  const _EOSSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendance summary (read-only)
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.checklist_rounded,
                label: 'SOS Submitted — Attendance Summary',
                isDark: isDark,
                statusColor: Colors.green,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    label: 'Present',
                    count: state.attendanceItems
                        .where((i) => i.attendanceStatus == 'present')
                        .length,
                    color: Colors.green,
                  ),
                  _StatChip(
                    label: 'Absent',
                    count: state.attendanceItems
                        .where((i) => i.attendanceStatus == 'absent')
                        .length,
                    color: Colors.red,
                  ),
                  _StatChip(
                    label: 'Leave',
                    count: state.attendanceItems
                        .where((i) => i.attendanceStatus == 'leave')
                        .length,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Shift context — incidents, leave, pending requests
        _ShiftContextPanel(isDark: isDark),
        const SizedBox(height: 12),

        // EOS Verification
        _Card(
          isDark: isDark,
          child: _VerificationChecklist(
            checklist: state.verificationChecklist,
            onToggle: notifier.toggleVerification,
            title: 'End of Shift Verification',
          ),
        ),
        const SizedBox(height: 12),

        // Handover Notes (for EOS)
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.note_alt_rounded,
                label: 'Handover Notes',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: notifier.updateHandoverNotes,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Summarize shift results and any items requiring follow-up...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // EOS handover gate
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.logout_rounded,
                label: 'Submit EOS',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: state.nextSupervisorSosSubmitted
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.nextSupervisorSosSubmitted
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.nextSupervisorSosSubmitted
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      color: state.nextSupervisorSosSubmitted
                          ? Colors.green
                          : Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.nextSupervisorSosSubmitted
                            ? 'Next supervisor has submitted SOS. You can now submit EOS.'
                            : 'Waiting for the next supervisor to submit their SOS before EOS is unlocked.',
                        style: GoogleFonts.outfit(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => notifier.checkNextSupervisorSOS(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text('Check Status',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.nextSupervisorSosSubmitted &&
                              state.allVerified &&
                              !state.loading
                          ? () => notifier.submitEOS()
                          : null,
                      icon: state.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.logout_rounded),
                      label: Text(
                        'SUBMIT EOS',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (state.nextSupervisorSosSubmitted && state.allVerified) ? AppColors.primary : Colors.grey,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              if (!state.allVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      'Complete all verification checks to submit EOS',
                      style: GoogleFonts.outfit(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Upload Section
// ---------------------------------------------------------------------------

class _UploadSection extends ConsumerStatefulWidget {
  final bool isDark;
  const _UploadSection({required this.isDark});

  @override
  ConsumerState<_UploadSection> createState() => _UploadSectionState();
}

class _UploadSectionState extends ConsumerState<_UploadSection> {
  final _fileNameCtrl = TextEditingController();
  String _fileType = 'excel';

  @override
  void dispose() {
    _fileNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);

    return _Card(
      isDark: widget.isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.upload_file_rounded,
            label: 'Upload Platform Report',
            isDark: widget.isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload the Excel or CSV report downloaded from the delivery platform (next-day upload).',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // File name input
          TextField(
            controller: _fileNameCtrl,
            style: GoogleFonts.outfit(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'File name (e.g. noon_report_2026-05-02.xlsx)',
              prefixIcon: const Icon(Icons.insert_drive_file_rounded,
                  size: 18, color: AppColors.primary),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // File type selector
          Row(
            children: [
              Text('File type:',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 12),
              _buildTypeChip('excel', 'Excel'),
              const SizedBox(width: 8),
              _buildTypeChip('csv', 'CSV'),
              const SizedBox(width: 8),
              _buildTypeChip('pdf', 'PDF'),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: state.loading
                  ? null
                  : () async {
                      final name = _fileNameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Enter a file name first.')),
                        );
                        return;
                      }
                      await notifier.uploadPlatformReport(
                        fileName: name,
                        fileType: _fileType,
                      );
                    },
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                'UPLOAD & SEND FOR VALIDATION',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String value, String label) {
    final selected = _fileType == value;
    return GestureDetector(
      onTap: () => setState(() => _fileType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.primary : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Section
// ---------------------------------------------------------------------------

class _PendingSection extends ConsumerWidget {
  final bool isDark;
  const _PendingSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);

    return _Card(
      isDark: isDark,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Report is being validated…',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Platform report has been uploaded. Run the validation check to see if the report is ready to be approved.',
            style:
                GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  state.loading ? null : () => notifier.runValidation(),
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.analytics_rounded),
              label: Text(
                'RUN VALIDATION',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Correction Section
// ---------------------------------------------------------------------------

class _CorrectionSection extends ConsumerWidget {
  final bool isDark;
  final TextEditingController controller;

  const _CorrectionSection(
      {required this.isDark, required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftControlProvider);
    final notifier = ref.read(shiftControlProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error summary
        _Card(
          isDark: isDark,
          borderColor: Colors.red.withValues(alpha: 0.4),
          backgroundColor: Colors.red.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.error_outline_rounded,
                label:
                    'Validation Failed — ${state.validationFlags.length} Issue${state.validationFlags.length == 1 ? '' : 's'} Found',
                isDark: isDark,
                statusColor: Colors.red,
              ),
              const SizedBox(height: 12),
              ...state.validationFlags
                  .map((f) => _FlagRow(flag: f))
                  ,
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Correction notes
        _Card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.edit_rounded,
                label: 'Correction Notes',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Describe what was corrected / clarified…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await notifier
                            .saveCorrectionNotes(controller.text);
                        messenger.showSnackBar(
                          const SnackBar(
                              content: Text('Notes saved.')),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, size: 18),
                      label: Text('Save Notes',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            const BorderSide(color: AppColors.primary),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => notifier.runValidation(),
                      icon: state.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.replay_rounded),
                      label: Text(
                        'RE-VALIDATE',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  final Map<String, dynamic> flag;
  const _FlagRow({required this.flag});

  @override
  Widget build(BuildContext context) {
    final type = flag['flag_type'] as String? ?? '';
    final desc = flag['description'] as String? ?? '';

    final iconData = switch (type) {
      'MISSING_REASON' => Icons.text_fields_rounded,
      'MISSING_SOS' => Icons.login_rounded,
      'MISSING_EOS' => Icons.logout_rounded,
      'MISSING_PLATFORM_REPORT' => Icons.upload_file_rounded,
      'MANUAL_ADDED_RIDER' => Icons.person_add_alt_1_rounded,
      _ => Icons.warning_amber_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, size: 14, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatFlagType(type),
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.red),
                ),
                Text(desc,
                    style:
                        GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFlagType(String t) => t.replaceAll('_', ' ');
}

// ---------------------------------------------------------------------------
// Shift Context Panel — incidents, leaves on date, pending requests
// ---------------------------------------------------------------------------

class _ShiftContextPanel extends ConsumerWidget {
  final bool isDark;
  const _ShiftContextPanel({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftControlProvider);
    final incidents = state.groupIncidents;
    final leaves = state.groupLeaveRequests;
    final pending = state.groupPendingRequests;

    if (incidents.isEmpty && leaves.isEmpty && pending.isEmpty) {
      return const SizedBox.shrink();
    }

    return _Card(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.dashboard_customize_rounded,
            label: 'Shift Context',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          if (incidents.isNotEmpty)
            _ContextTile(
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
              label: 'Active Incidents',
              count: incidents.length,
              children: incidents
                  .map((t) => _IncidentRow(ticket: t))
                  .toList(),
            ),
          if (leaves.isNotEmpty)
            _ContextTile(
              icon: Icons.event_busy_rounded,
              color: Colors.orange,
              label: 'On Leave Today',
              count: leaves.length,
              children: leaves
                  .map((r) => _LeaveRow(request: r))
                  .toList(),
            ),
          if (pending.isNotEmpty)
            _ContextTile(
              icon: Icons.pending_actions_rounded,
              color: AppColors.primary,
              label: 'Pending Requests',
              count: pending.length,
              children: pending
                  .map((r) => _RequestRow(request: r))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _ContextTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final List<Widget> children;

  const _ContextTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        title: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
            ),
          ],
        ),
        children: children,
      ),
    );
  }
}

class _IncidentRow extends StatelessWidget {
  final Map<String, dynamic> ticket;
  const _IncidentRow({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final profile = ticket['profiles'] as Map<String, dynamic>?;
    final riderName =
        profile?['full_name'] as String? ?? 'Unknown Rider';
    final type = ticket['type'] as String? ?? 'other';
    final subject = ticket['subject'] as String? ?? '';
    final priority = ticket['priority'] as String? ?? 'normal';
    final priorityColor = priority == 'high'
        ? Colors.red
        : priority == 'normal'
            ? Colors.orange
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
                color: priorityColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$riderName · ${_formatType(type)} · $priority priority',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatType(String t) =>
      t.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
}

class _LeaveRow extends StatelessWidget {
  final Map<String, dynamic> request;
  const _LeaveRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final profile = request['profiles'] as Map<String, dynamic>?;
    final riderName =
        profile?['full_name'] as String? ?? 'Unknown Rider';
    final start = request['start_date'] as String? ?? '';
    final end = request['end_date'] as String?;
    final dateRange = end != null && end != start ? '$start → $end' : start;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.person_off_rounded,
              size: 14, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderName,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  dateRange,
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  final Map<String, dynamic> request;
  const _RequestRow({required this.request});

  @override
  Widget build(BuildContext context) {
    final profile = request['profiles'] as Map<String, dynamic>?;
    final riderName =
        profile?['full_name'] as String? ?? 'Unknown Rider';
    final type = request['type'] as String? ?? '';
    final subject = request['subject'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.assignment_rounded,
              size: 14, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: GoogleFonts.outfit(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$riderName · $type',
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Verification Checklist Component
// ---------------------------------------------------------------------------

class _VerificationChecklist extends StatelessWidget {
  final Map<String, bool> checklist;
  final ValueChanged<String> onToggle;
  final String title;

  const _VerificationChecklist({
    required this.checklist,
    required this.onToggle,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified_user_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify the following data points before proceeding:',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        ...checklist.keys.map((key) => _VerificationItem(
              label: _getLabel(key),
              value: checklist[key] ?? false,
              onChanged: (_) => onToggle(key),
            )),
      ],
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'riders':
        return 'Verify Rider Attendance & Availability';
      case 'leave':
        return 'Check Approved Leaves & Documentation';
      case 'vehicles':
        return 'Verify Vehicle Status & Handover Records';
      case 'issues':
        return 'Review Active Incidents & Maintenance Needs';
      default:
        return key;
    }
  }
}

class _VerificationItem extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _VerificationItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500)),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approved Section
// ---------------------------------------------------------------------------

class _ApprovedSection extends ConsumerWidget {
  final bool isDark;
  const _ApprovedSection({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shiftControlProvider);
    final reportDate = state.report?['report_date'] as String? ?? '';

    return _Card(
      isDark: isDark,
      borderColor: Colors.green.withValues(alpha: 0.4),
      backgroundColor: Colors.green.withValues(alpha: 0.04),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 48, color: Colors.green),
          ),
          const SizedBox(height: 16),
          Text(
            'Report Approved!',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.green),
          ),
          const SizedBox(height: 8),
          Text(
            'Shift report for $reportDate has passed all validation checks and has been approved.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Summary
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _StatChip(
                label: 'Total Riders',
                count: state.attendanceItems.length,
                color: AppColors.primary,
              ),
              _StatChip(
                label: 'Present',
                count: state.attendanceItems
                    .where((i) => i.attendanceStatus == 'present')
                    .length,
                color: Colors.green,
              ),
              _StatChip(
                label: 'Absent',
                count: state.attendanceItems
                    .where((i) => i.attendanceStatus == 'absent')
                    .length,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 56, color: Colors.grey.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'Select a platform and group,\nthen tap "Load / Create Report".',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color? borderColor;
  final Color? backgroundColor;

  const _Card({
    required this.child,
    required this.isDark,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: borderColor ?? theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final Color? statusColor;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.isDark,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = statusColor ?? AppColors.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800, fontSize: 14, color: color),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
            fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
