import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final _schedulesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, DateTime>(
  (ref, date) =>
      ref.watch(operationsRepositoryProvider).fetchSchedules(date),
);

class SupervisorScheduleScreen extends ConsumerStatefulWidget {
  const SupervisorScheduleScreen({super.key});

  @override
  ConsumerState<SupervisorScheduleScreen> createState() =>
      _SupervisorScheduleScreenState();
}

class _SupervisorScheduleScreenState
    extends ConsumerState<SupervisorScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(_schedulesProvider(_selectedDate));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DashboardScaffold(
      title: 'SUPERVISOR SCHEDULE',
      subtitle: 'Assign supervisors to groups for each shift',
      showBackButton: true,
      activeItem: 'Dashboard',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssignDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.assignment_ind_rounded, color: Colors.white),
        label: Text('Assign Supervisor',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      children: [
        // Date selector
        _DateSelector(
          selectedDate: _selectedDate,
          onChanged: (d) => setState(() => _selectedDate = d),
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // Schedule list
        schedulesAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator())),
          error: (e, _) => Text(e.toString(),
              style: GoogleFonts.outfit(color: Colors.red)),
          data: (schedules) => schedules.isEmpty
              ? _EmptySchedule(date: _selectedDate)
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: schedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _ScheduleCard(schedule: schedules[i], isDark: isDark),
                ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AssignDialog(
        initialDate: _selectedDate,
        onAssigned: () => ref.invalidate(_schedulesProvider(_selectedDate)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Schedule Card
// ---------------------------------------------------------------------------

class _ScheduleCard extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final bool isDark;

  const _ScheduleCard({required this.schedule, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supervisor = schedule['profiles'] as Map<String, dynamic>?;
    final group = schedule['groups'] as Map<String, dynamic>?;
    final platform = schedule['platforms'] as Map<String, dynamic>?;

    final shiftStart = schedule['shift_start'] != null
        ? DateTime.tryParse(schedule['shift_start'] as String)
        : null;
    final shiftEnd = schedule['shift_end'] != null
        ? DateTime.tryParse(schedule['shift_end'] as String)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.manage_accounts_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supervisor?['full_name'] as String? ?? 'Unknown Supervisor',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${group?['name'] ?? '—'}  ·  ${platform?['name'] ?? '—'}',
                  style:
                      GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                ),
                if (shiftStart != null && shiftEnd != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${DateFormat('HH:mm').format(shiftStart)} – ${DateFormat('HH:mm').format(shiftEnd)}',
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Assigned',
                style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign Dialog
// ---------------------------------------------------------------------------

class _AssignDialog extends ConsumerStatefulWidget {
  final DateTime initialDate;
  final VoidCallback onAssigned;

  const _AssignDialog(
      {required this.initialDate, required this.onAssigned});

  @override
  ConsumerState<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends ConsumerState<_AssignDialog> {
  DateTime _date = DateTime.now();
  String? _supervisorId;
  String? _groupId;
  String? _platformId;
  TimeOfDay _shiftStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _shiftEnd = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = false;

  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _platforms = [];

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(operationsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchSupervisors(),
      repo.fetchGroups(),
      repo.fetchPlatforms(),
    ]);
    if (mounted) {
      setState(() {
        _supervisors = results[0];
        _groups = results[1];
        _platforms = results[2];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Assign Supervisor',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(DateFormat('EEE, d MMM yyyy').format(_date),
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown('Supervisor', _supervisors, _supervisorId,
                (v) => setState(() => _supervisorId = v)),
            const SizedBox(height: 12),
            _buildDropdown('Group', _groups, _groupId,
                (v) => setState(() => _groupId = v)),
            const SizedBox(height: 12),
            _buildDropdown('Platform', _platforms, _platformId,
                (v) => setState(() => _platformId = v)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _timeTile('Start', _shiftStart, (t) {
                  setState(() => _shiftStart = t);
                })),
                const SizedBox(width: 8),
                Expanded(child: _timeTile('End', _shiftEnd, (t) {
                  setState(() => _shiftEnd = t);
                })),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit()),
        ),
        ElevatedButton(
          onPressed: _canSave && !_loading ? _save : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text('Assign',
                  style:
                      GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  bool get _canSave =>
      _supervisorId != null && _groupId != null && _platformId != null;

  Widget _buildDropdown(String label, List<Map<String, dynamic>> items,
      String? value, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
      items: items
          .map((p) => DropdownMenuItem<String>(
                value: p['id'] as String,
                child: Text(p['full_name'] ?? p['name'] ?? '',
                    style: GoogleFonts.outfit()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _timeTile(
      String label, TimeOfDay time, ValueChanged<TimeOfDay> onChanged) {
    return InkWell(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 10, color: Colors.grey)),
                Text(time.format(context),
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final shiftStartDt = DateTime(
        _date.year, _date.month, _date.day, _shiftStart.hour, _shiftStart.minute);
    final shiftEndDt = DateTime(
        _date.year, _date.month, _date.day, _shiftEnd.hour, _shiftEnd.minute);

    try {
      await ref.read(operationsRepositoryProvider).assignSupervisor(
            supervisorId: _supervisorId!,
            groupId: _groupId!,
            platformId: _platformId!,
            scheduleDate: _date,
            shiftStart: shiftStartDt,
            shiftEnd: shiftEndDt,
          );
      if (mounted) {
        Navigator.pop(context);
        widget.onAssigned();
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
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;
  final bool isDark;

  const _DateSelector(
      {required this.selectedDate,
      required this.onChanged,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final d = DateTime.now().add(Duration(days: i - 1));
        final isSelected = d.day == selectedDate.day &&
            d.month == selectedDate.month &&
            d.year == selectedDate.year;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(d),
            child: Container(
              margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(d),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  Text(
                    d.day.toString(),
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isSelected ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final DateTime date;
  const _EmptySchedule({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_ind_outlined,
                size: 56, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'No supervisors assigned for\n${DateFormat('d MMM yyyy').format(date)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
