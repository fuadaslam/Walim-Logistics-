import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final _todayScheduleProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
  return ref.watch(operationsRepositoryProvider).fetchSupervisorTodaySchedule(uid);
});

final _groupMembersWithAttendanceProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) => ref
      .watch(operationsRepositoryProvider)
      .fetchGroupMembersWithAttendance(groupId),
);

class SupervisorGroupScreen extends ConsumerWidget {
  final bool showScaffold;
  const SupervisorGroupScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(_todayScheduleProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = scheduleAsync.when(
      loading: () => const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator())),
      error: (e, _) => _ErrorCard(message: e.toString()),
      data: (schedule) {
        if (schedule == null) {
          return _NoScheduleCard(isDark: isDark);
        }
        final group = schedule['groups'] as Map<String, dynamic>?;
        final platform = schedule['platforms'] as Map<String, dynamic>?;
        final groupId = group?['id'] as String?;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's assignment banner
            _AssignmentBanner(
              schedule: schedule,
              group: group,
              platform: platform,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            if (groupId != null)
              _GroupMembersList(
                groupId: groupId,
                groupName: group?['name'] as String? ?? 'My Group',
                isDark: isDark,
              ),
          ],
        );
      },
    );

    if (!showScaffold) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: body,
      );
    }

    return DashboardScaffold(
      title: 'MY GROUP',
      subtitle: 'Your assigned riders for today\'s shift',
      showBackButton: true,
      activeItem: 'Dashboard',
      children: [body],
    );
  }
}

// ---------------------------------------------------------------------------
// Assignment Banner
// ---------------------------------------------------------------------------

class _AssignmentBanner extends StatelessWidget {
  final Map<String, dynamic> schedule;
  final Map<String, dynamic>? group;
  final Map<String, dynamic>? platform;
  final bool isDark;

  const _AssignmentBanner({
    required this.schedule,
    required this.group,
    required this.platform,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final shiftStart = schedule['shift_start'] != null
        ? DateTime.tryParse(schedule['shift_start'] as String)
        : null;
    final shiftEnd = schedule['shift_end'] != null
        ? DateTime.tryParse(schedule['shift_end'] as String)
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.outfit(
                    color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            group?['name'] as String? ?? 'My Group',
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            platform?['name'] as String? ?? '',
            style: GoogleFonts.outfit(
                color: Colors.white70, fontSize: 14),
          ),
          if (shiftStart != null && shiftEnd != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('HH:mm').format(shiftStart)} – ${DateFormat('HH:mm').format(shiftEnd)}',
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group Members List
// ---------------------------------------------------------------------------

class _GroupMembersList extends ConsumerWidget {
  final String groupId;
  final String groupName;
  final bool isDark;

  const _GroupMembersList({
    required this.groupId,
    required this.groupName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync =
        ref.watch(_groupMembersWithAttendanceProvider(groupId));
    final theme = Theme.of(context);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(e.toString(),
          style: GoogleFonts.outfit(color: Colors.red)),
      data: (members) {
        final present =
            members.where((m) => m['today_status'] == 'present').length;
        final absent =
            members.where((m) => m['today_status'] == 'absent').length;
        final notMarked = members
            .where((m) => m['today_status'] == 'not_marked')
            .length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _statChip('${members.length}', 'Total', AppColors.primary),
                const SizedBox(width: 8),
                _statChip('$present', 'Present', Colors.green),
                const SizedBox(width: 8),
                _statChip('$absent', 'Absent', Colors.red),
                const SizedBox(width: 8),
                if (notMarked > 0)
                  _statChip('$notMarked', 'Unmarked', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),

            // Member cards
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.dividerColor.withOpacity(0.4)),
              ),
              child: members.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No riders in this group yet.\nAsk your Ops Manager to assign riders.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 60),
                      itemBuilder: (_, i) =>
                          _MemberTile(member: members[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(count,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member Tile
// ---------------------------------------------------------------------------

class _MemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  const _MemberTile({required this.member});

  static const _statusColors = {
    'present': Colors.green,
    'absent': Colors.red,
    'leave': Colors.orange,
    'suspended': Colors.grey,
    'carry_over': Colors.blue,
    'not_marked': Colors.amber,
  };

  static const _statusIcons = {
    'present': Icons.check_circle_rounded,
    'absent': Icons.cancel_rounded,
    'leave': Icons.beach_access_rounded,
    'suspended': Icons.block_rounded,
    'carry_over': Icons.sync_rounded,
    'not_marked': Icons.radio_button_unchecked_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final profile = member['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Unknown';
    final iqama = profile?['iqama_number'] as String? ?? '';
    final phone = profile?['phone_number'] as String? ?? '';
    final todayStatus = member['today_status'] as String? ?? 'not_marked';
    final statusColor = _statusColors[todayStatus] ?? Colors.grey;
    final statusIcon = _statusIcons[todayStatus] ?? Icons.help_outline_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.12),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Row(
                  children: [
                    if (iqama.isNotEmpty) ...[
                      Text(iqama,
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey)),
                      const SizedBox(width: 8),
                    ],
                    if (phone.isNotEmpty)
                      Text(phone,
                          style: GoogleFonts.outfit(
                              fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                _formatStatus(todayStatus),
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatStatus(String s) {
    if (s == 'not_marked') return 'Not Marked';
    if (s == 'carry_over') return 'Carry-Over';
    return s[0].toUpperCase() + s.substring(1);
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _NoScheduleCard extends StatelessWidget {
  final bool isDark;
  const _NoScheduleCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.event_busy_rounded,
                size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'No shift assigned for today',
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your Operations Manager has not assigned you to a group for today\'s shift yet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: GoogleFonts.outfit(color: Colors.red)),
    );
  }
}
