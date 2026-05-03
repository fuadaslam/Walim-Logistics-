import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'rider_group_assignment_screen.dart';

final _groupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(operationsRepositoryProvider).fetchGroups(),
);

class GroupSetupScreen extends ConsumerWidget {
  const GroupSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(_groupsProvider);

    return DashboardScaffold(
      title: 'GROUP MANAGEMENT',
      subtitle: 'Create groups and assign riders to supervisors',
      showBackButton: true,
      activeItem: 'Dashboard',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupDialog(context, ref, null),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Group',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      children: [
        groupsAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator())),
          error: (e, _) => _ErrorTile(message: e.toString()),
          data: (groups) {
            if (groups.isEmpty) {
              return _EmptyState(
                onTap: () => _showGroupDialog(context, ref, null),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) =>
                  _GroupCard(group: groups[i], ref: ref),
            );
          },
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  void _showGroupDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      builder: (_) => _GroupDialog(existing: existing, ref: ref),
    );
  }
}

// ---------------------------------------------------------------------------
// Group Card
// ---------------------------------------------------------------------------

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final WidgetRef ref;

  const _GroupCard({required this.group, required this.ref});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final platform = group['platforms'] as Map<String, dynamic>?;
    final supervisor = group['profiles'] as Map<String, dynamic>?;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] as String,
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (platform != null)
                      Text(
                        platform['name'] as String,
                        style: GoogleFonts.outfit(
                            fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (group['is_active'] as bool? ?? true)
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (group['is_active'] as bool? ?? true) ? 'Active' : 'Inactive',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: (group['is_active'] as bool? ?? true)
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (supervisor != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.manage_accounts_rounded,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Supervisor: ${supervisor['full_name']}',
                  style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _ActionBtn(
                icon: Icons.people_rounded,
                label: 'Manage Riders',
                color: AppColors.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RiderGroupAssignmentScreen(
                      groupId: group['id'] as String,
                      groupName: group['name'] as String,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.edit_rounded,
                label: 'Edit',
                color: Colors.orange,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) =>
                      _GroupDialog(existing: group, ref: ref),
                ),
              ),
              const SizedBox(width: 8),
              _ActionBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Delete',
                color: Colors.red,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete Group',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${group['name']}"? This will remove all group members and shift plans.',
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
              await ref
                  .read(operationsRepositoryProvider)
                  .deleteGroup(group['id'] as String);
              ref.invalidate(_groupsProvider);
            },
            child: Text('Delete',
                style:
                    GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group Dialog (Create / Edit)
// ---------------------------------------------------------------------------

class _GroupDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final WidgetRef ref;

  const _GroupDialog({this.existing, required this.ref});

  @override
  ConsumerState<_GroupDialog> createState() => _GroupDialogState();
}

class _GroupDialogState extends ConsumerState<_GroupDialog> {
  final _nameCtrl = TextEditingController();
  String? _selectedPlatformId;
  String? _selectedZoneId;
  String? _selectedSupervisorId;
  bool _loading = false;

  List<Map<String, dynamic>> _platforms = [];
  List<Map<String, dynamic>> _zones = [];
  List<Map<String, dynamic>> _supervisors = [];

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!['name'] as String? ?? '';
      _selectedPlatformId = widget.existing!['platform_id'] as String?;
      _selectedZoneId = widget.existing!['zone_id'] as String?;
      _selectedSupervisorId = widget.existing!['supervisor_id'] as String?;
    }
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(operationsRepositoryProvider);
    final results = await Future.wait([
      repo.fetchPlatforms(),
      repo.fetchZones(),
      repo.fetchSupervisors(),
    ]);
    if (mounted) {
      setState(() {
        _platforms = results[0];
        _zones = results[1];
        _supervisors = results[2];
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
        isEdit ? 'Edit Group' : 'Create New Group',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.groups_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _buildDropdown('Platform', _platforms, _selectedPlatformId,
                (v) => setState(() => _selectedPlatformId = v)),
            const SizedBox(height: 12),
            _buildDropdown('Zone (optional)', _zones, _selectedZoneId,
                (v) => setState(() => _selectedZoneId = v)),
            const SizedBox(height: 12),
            _buildDropdown(
                'Supervisor (optional)',
                _supervisors,
                _selectedSupervisorId,
                (v) => setState(() => _selectedSupervisorId = v)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.outfit()),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white),
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Save' : 'Create',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

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
      items: [
        DropdownMenuItem<String>(
            value: null,
            child: Text('None', style: GoogleFonts.outfit())),
        ...items.map((p) => DropdownMenuItem<String>(
              value: p['id'] as String,
              child: Text(p['full_name'] ?? p['name'] ?? '',
                  style: GoogleFonts.outfit()),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Group name is required.')));
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(operationsRepositoryProvider);
    final uid =
        Supabase.instance.client.auth.currentUser?.id ?? '';

    try {
      if (widget.existing == null) {
        await repo.createGroup(
          name: _nameCtrl.text.trim(),
          platformId: _selectedPlatformId,
          zoneId: _selectedZoneId,
          supervisorId: _selectedSupervisorId,
          createdBy: uid,
        );
      } else {
        await repo.updateGroup(
          id: widget.existing!['id'] as String,
          name: _nameCtrl.text.trim(),
          platformId: _selectedPlatformId,
          zoneId: _selectedZoneId,
          supervisorId: _selectedSupervisorId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.ref.invalidate(_groupsProvider);
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

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.groups_outlined,
                size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No groups yet.',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Create your first group to start assigning riders.',
                style:
                    GoogleFonts.outfit(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Create Group',
                  style: GoogleFonts.outfit(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message,
          style: GoogleFonts.outfit(color: Colors.red)),
    );
  }
}
