import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class ShiftPlannerScreen extends ConsumerStatefulWidget {
  const ShiftPlannerScreen({super.key});

  @override
  ConsumerState<ShiftPlannerScreen> createState() =>
      _ShiftPlannerScreenState();
}

class _ShiftPlannerScreenState extends ConsumerState<ShiftPlannerScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedGroupId;
  String? _selectedPlatformId;
  TimeOfDay _shiftStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 20, minute: 0);

  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _platforms = [];
  List<Map<String, dynamic>> _previewPlans = [];

  bool _loading = false;
  bool _previewing = false;
  String? _resultMessage;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final repo = ref.read(operationsRepositoryProvider);
    final results =
        await Future.wait([repo.fetchGroups(), repo.fetchPlatforms()]);
    if (mounted) {
      setState(() {
        _groups = results[0];
        _platforms = results[1];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DashboardScaffold(
      title: 'SHIFT PLANNER',
      subtitle: 'Generate rider shift plans for a date from group members',
      showBackButton: true,
      activeItem: 'Dashboard',
      children: [
        // Setup card
        _card(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                  'Shift Setup', Icons.event_note_rounded, AppColors.primary),
              const SizedBox(height: 16),

              // Date
              _datePicker(theme),
              const SizedBox(height: 12),

              // Platform
              _dropdown(
                theme: theme,
                hint: 'Select Platform',
                icon: Icons.store_rounded,
                value: _selectedPlatformId,
                items: _platforms,
                onChanged: (v) => setState(() {
                  _selectedPlatformId = v;
                  // If current group doesn't belong to this platform, clear it
                  if (v != null && _selectedGroupId != null) {
                    final group = _groups.firstWhere(
                      (g) => g['id'] == _selectedGroupId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (group.isNotEmpty && group['platform_id'] != v) {
                      _selectedGroupId = null;
                    }
                  }
                }),
              ),
              const SizedBox(height: 12),

              // Group
              _dropdown(
                theme: theme,
                hint: 'Select Group',
                icon: Icons.groups_rounded,
                value: _selectedGroupId,
                items: _groups
                    .where((g) =>
                        _selectedPlatformId == null ||
                        g['platform_id'] == _selectedPlatformId)
                    .toList(),
                onChanged: (v) => setState(() {
                  _selectedGroupId = v;
                  _previewPlans = [];
                  _resultMessage = null;

                  // Auto-select platform if group is chosen
                  if (v != null) {
                    final group = _groups.firstWhere(
                      (g) => g['id'] == v,
                      orElse: () => <String, dynamic>{},
                    );
                    if (group.isNotEmpty && group['platform_id'] != null) {
                      _selectedPlatformId = group['platform_id'] as String;
                    }
                  }
                }),
              ),
              const SizedBox(height: 12),

              // Shift time
              Row(
                children: [
                  Expanded(
                      child: _timePicker(
                          'Shift Start', _shiftStart, (t) {
                    setState(() => _shiftStart = t);
                  })),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _timePicker(
                          'Shift End', _shiftEnd, (t) {
                    setState(() => _shiftEnd = t);
                  })),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _canGenerate && !_loading ? _preview : null,
                      icon: const Icon(Icons.preview_rounded, size: 18),
                      label: Text('Preview',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side:
                            const BorderSide(color: AppColors.primary),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          _canGenerate && !_loading ? _generate : null,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.bolt_rounded),
                      label: Text('GENERATE PLANS',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Result banner
        if (_resultMessage != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(_resultMessage!,
                      style: GoogleFonts.outfit(
                          color: Colors.green,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

        // Preview list
        if (_previewing)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),

        if (_previewPlans.isNotEmpty) ...[
          const SizedBox(height: 16),
          _card(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader(
                    'Preview — ${_previewPlans.length} Riders',
                    Icons.list_alt_rounded,
                    Colors.orange),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _previewPlans.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final plan = _previewPlans[i];
                    final profile =
                        plan['profiles'] as Map<String, dynamic>?;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          (profile?['full_name'] as String? ?? '?')[0]
                              .toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      title: Text(
                          profile?['full_name'] as String? ??
                              'Unknown',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Text(
                          profile?['iqama_number'] as String? ?? '',
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  bool get _canGenerate =>
      _selectedGroupId != null && _selectedPlatformId != null;

  Future<void> _preview() async {
    setState(() {
      _previewing = true;
      _previewPlans = [];
    });
    final members = await ref
        .read(operationsRepositoryProvider)
        .fetchGroupMembers(_selectedGroupId!);
    if (mounted) {
      setState(() {
        _previewPlans = members;
        _previewing = false;
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _resultMessage = null;
    });

    final shiftStartDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _shiftStart.hour,
      _shiftStart.minute,
    );
    final shiftEndDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _shiftEnd.hour,
      _shiftEnd.minute,
    );

    try {
      final count = await ref
          .read(operationsRepositoryProvider)
          .generateShiftPlans(
            groupId: _selectedGroupId!,
            platformId: _selectedPlatformId!,
            shiftDate: _selectedDate,
            shiftStart: shiftStartDt,
            shiftEnd: shiftEndDt,
          );
      if (mounted) {
        setState(() => _resultMessage =
            'Successfully generated shift plans for $count riders on ${DateFormat('d MMM yyyy').format(_selectedDate)}.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _datePicker(ThemeData theme) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEE, d MMM yyyy').format(_selectedDate),
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _timePicker(
      String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: Colors.grey)),
                Text(time.format(context),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required ThemeData theme,
    required String hint,
    required IconData icon,
    required String? value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<String?> onChanged,
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
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint,
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: Colors.grey)),
                isExpanded: true,
                items: items
                    .map((p) => DropdownMenuItem<String>(
                          value: p['id'] as String,
                          child: Text(p['name'] as String,
                              style: GoogleFonts.outfit(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
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
        Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }

  Widget _card({required bool isDark, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: child,
    );
  }
}
