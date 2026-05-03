import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

final _membersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, groupId) =>
      ref.watch(operationsRepositoryProvider).fetchGroupMembers(groupId),
);

final _allRidersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(operationsRepositoryProvider).fetchRiders(),
);

class RiderGroupAssignmentScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const RiderGroupAssignmentScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<RiderGroupAssignmentScreen> createState() =>
      _RiderGroupAssignmentScreenState();
}

class _RiderGroupAssignmentScreenState
    extends ConsumerState<RiderGroupAssignmentScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(_membersProvider(widget.groupId));
    final allRidersAsync = ref.watch(_allRidersProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DashboardScaffold(
      title: widget.groupName.toUpperCase(),
      subtitle: 'Manage riders assigned to this group',
      showBackButton: true,
      activeItem: 'Dashboard',
      children: [
        // Current members section
        _sectionHeader('Current Group Members', Icons.people_rounded,
            AppColors.primary),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString(),
              style: GoogleFonts.outfit(color: Colors.red)),
          data: (members) => members.isEmpty
              ? _emptyMembers()
              : _membersList(members, isDark),
        ),

        const SizedBox(height: 32),

        // Add riders section
        _sectionHeader(
            'Add Riders to Group', Icons.person_add_rounded, Colors.green),
        const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _search = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Search riders by name or iqama…',
            prefixIcon:
                const Icon(Icons.search_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        allRidersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text(e.toString(),
              style: GoogleFonts.outfit(color: Colors.red)),
          data: (allRiders) {
            return membersAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (members) {
                final memberIds =
                    members.map((m) => m['rider_id'] as String).toSet();
                final available = allRiders
                    .where((r) => !memberIds.contains(r['id'] as String))
                    .where((r) {
                  if (_search.isEmpty) return true;
                  final name =
                      (r['full_name'] as String? ?? '').toLowerCase();
                  final iqama =
                      (r['iqama_number'] as String? ?? '').toLowerCase();
                  return name.contains(_search) ||
                      iqama.contains(_search);
                }).toList();

                if (available.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'All riders are already in this group.',
                        style:
                            GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: available.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (context, i) =>
                      _AvailableRiderTile(
                    rider: available[i],
                    groupId: widget.groupId,
                    onAdded: () {
                      ref.invalidate(_membersProvider(widget.groupId));
                      ref.invalidate(_allRidersProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }

  Widget _emptyMembers() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Text('No riders in this group yet.',
            style: GoogleFonts.outfit(color: Colors.grey)),
      ),
    );
  }

  Widget _membersList(List<Map<String, dynamic>> members, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final m = members[i];
          final profile = m['profiles'] as Map<String, dynamic>?;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                (profile?['full_name'] as String? ?? '?')[0].toUpperCase(),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(profile?['full_name'] as String? ?? 'Unknown',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            subtitle: Text(
                profile?['iqama_number'] as String? ?? '',
                style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  color: Colors.red),
              tooltip: 'Remove from group',
              onPressed: () => _confirmRemove(context, m, profile),
            ),
          );
        },
      ),
    );
  }

  void _confirmRemove(BuildContext context, Map<String, dynamic> member,
      Map<String, dynamic>? profile) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove Rider',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove ${profile?['full_name'] ?? 'this rider'} from the group?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(operationsRepositoryProvider).removeRiderFromGroup(
                    groupId: widget.groupId,
                    riderId: member['rider_id'] as String,
                  );
              ref.invalidate(_membersProvider(widget.groupId));
              ref.invalidate(_allRidersProvider);
            },
            child: Text('Remove',
                style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Available Rider Tile
// ---------------------------------------------------------------------------

class _AvailableRiderTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> rider;
  final String groupId;
  final VoidCallback onAdded;

  const _AvailableRiderTile({
    required this.rider,
    required this.groupId,
    required this.onAdded,
  });

  @override
  ConsumerState<_AvailableRiderTile> createState() =>
      _AvailableRiderTileState();
}

class _AvailableRiderTileState extends ConsumerState<_AvailableRiderTile> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: Text(
          (widget.rider['full_name'] as String? ?? '?')[0].toUpperCase(),
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(widget.rider['full_name'] as String? ?? 'Unknown',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      subtitle: Text(
          widget.rider['iqama_number'] as String? ?? '',
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
      trailing: _adding
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: Colors.green),
              tooltip: 'Add to group',
              onPressed: _add,
            ),
    );
  }

  Future<void> _add() async {
    setState(() => _adding = true);
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
      await ref.read(operationsRepositoryProvider).addRiderToGroup(
            groupId: widget.groupId,
            riderId: widget.rider['id'] as String,
            addedBy: uid,
          );
      widget.onAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}
