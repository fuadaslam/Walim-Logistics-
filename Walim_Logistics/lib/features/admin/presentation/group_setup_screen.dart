import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'rider_group_assignment_screen.dart';

final _groupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(operationsRepositoryProvider).fetchGroups(),
);

class GroupSetupScreen extends ConsumerWidget {
  const GroupSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(_groupsProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return DashboardScaffold(
      title: 'GROUP MANAGEMENT',
      subtitle: 'Create groups and assign riders to supervisors',
      showBackButton: true,
      activeItem: 'Dashboard',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGroupBottomSheet(context, ref, null),
        backgroundColor: AppColors.primary,
        elevation: 4,
        hoverElevation: 6,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Group',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: groupsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, _) => _ErrorTile(message: e.toString()),
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyStatePlaceholder(
              icon: Icons.groups_outlined,
              title: 'No groups yet',
              subtitle: 'Create your first group to start assigning riders to supervisors.',
              color: AppColors.primary,
              actionLabel: 'Create Group',
              onAction: () => _showGroupBottomSheet(context, ref, null),
            );
          }

          if (isDesktop) {
            return GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: groups.length,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: width > 1400 ? 580 : 490,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                mainAxisExtent: 310,
              ),
              itemBuilder: (context, i) => _GroupCard(group: groups[i], ref: ref),
            );
          } else {
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 120),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) => _GroupCard(group: groups[i], ref: ref),
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Unified Helper for Bottom Sheet
// ---------------------------------------------------------------------------

void _showGroupBottomSheet(BuildContext context, WidgetRef ref, Map<String, dynamic>? existing) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => _GroupBottomSheet(existing: existing, ref: ref),
  );
}

// ---------------------------------------------------------------------------
// Group Card
// ---------------------------------------------------------------------------

class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final WidgetRef ref;

  const _GroupCard({required this.group, required this.ref});

  Color _getPlatformColor(String? name) {
    if (name == null) return AppColors.primary;
    final n = name.toLowerCase();
    if (n.contains('hunger')) return const Color(0xFFFF5E00); // HungerStation Orange
    if (n.contains('jahez')) return const Color(0xFFE21A53); // Jahez Pink/Red
    if (n.contains('noon')) return const Color(0xFFFEE000); // Noon Yellow
    if (n.contains('toyou')) return const Color(0xFF1D1B26); // Toyou Dark Blue
    if (n.contains('mrsool')) return const Color(0xFF00B0FF); // Mrsool Blue
    if (n.contains('careem')) return const Color(0xFF47B749); // Careem Green
    return AppColors.primary;
  }

  String _getPlatformLetter(String? name) {
    if (name == null || name.isEmpty) return 'G';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final platform = group['platforms'] as Map<String, dynamic>?;
    final supervisor = group['supervisor'] as Map<String, dynamic>?;
    final leader = group['leader'] as Map<String, dynamic>?;
    final zone = group['zones'] as Map<String, dynamic>?;

    final platformName = platform?['name'] as String?;
    final platformColor = _getPlatformColor(platformName);
    final platformLetter = _getPlatformLetter(platformName);

    // Smart color combinations for premium, highly readable badges
    Color platformTextColor = platformColor;
    Color platformBgColor = platformColor.withOpacity(0.08);
    if (platformName != null) {
      final pName = platformName.toLowerCase();
      if (pName.contains('noon')) {
        platformTextColor = const Color(0xFFD97706); // Beautiful dark gold
        platformBgColor = const Color(0xFFFFFBE7); // Very soft warm yellow
      } else if (pName.contains('careem')) {
        platformTextColor = const Color(0xFF15803D); // Clean forest green
        platformBgColor = const Color(0xFFDCFCE7); // Softer mint
      } else if (pName.contains('toyou')) {
        platformTextColor = isDark ? Colors.white : const Color(0xFF1D1B26);
        platformBgColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Stack(
        children: [
          // Elegant subtle left indicator bar
          Positioned(
            left: 0,
            top: 24,
            bottom: 24,
            width: 4,
            child: Container(
              decoration: BoxDecoration(
                color: platformColor,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Soft circular logo badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: platformBgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        platformLetter,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: platformTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'] as String,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (platform != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 13,
                                  color: isDark ? Colors.white38 : Colors.grey[400],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    platformName!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark ? Colors.white54 : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(group['is_active'] as bool? ?? true),
                  ],
                ),

                const SizedBox(height: 20),

                // Sleek Unified Stats Row
                _buildStatsRow(context, zone),

                const SizedBox(height: 20),

                // Seamless Management Team Row
                _buildTeamRow(context, supervisor, leader),

                const SizedBox(height: 20),

                // Premium Action Toolbar
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: _ActionBtn(
                        icon: Icons.people_rounded,
                        label: 'Manage Riders',
                        isPrimary: true,
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiderGroupAssignmentScreen(
                              groupId: group['id'] as String,
                              groupName: group['name'] as String,
                            ),
                          ),
                        ).then((_) => ref.invalidate(_groupsProvider)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _ActionBtn(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        isPrimary: false,
                        color: isDark ? Colors.white70 : Colors.black87,
                        onTap: () => _showGroupBottomSheet(context, ref, group),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.red.withOpacity(0.1)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                        onPressed: () => _confirmDelete(context),
                        tooltip: 'Delete Group',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, Map<String, dynamic>? zone) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.015) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          _buildCompactStatColumn(
            'RIDERS',
            '12',
            Icons.motorcycle_rounded,
            const Color(0xFF3B82F6),
            context,
          ),
          _buildVerticalDivider(isDark),
          _buildCompactStatColumn(
            'SHIFTS',
            'Active',
            Icons.insights_rounded,
            const Color(0xFF10B981),
            context,
          ),
          _buildVerticalDivider(isDark),
          _buildCompactStatColumn(
            'ZONE',
            zone?['name'] as String? ?? 'N/A',
            Icons.explore_rounded,
            const Color(0xFFF59E0B),
            context,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 24,
      color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildCompactStatColumn(
    String label,
    String value,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color.withOpacity(0.85)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(BuildContext context, Map<String, dynamic>? supervisor, Map<String, dynamic>? leader) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Expanded(
          child: _buildTeamMemberItem(
            'SUPERVISOR',
            supervisor != null ? (supervisor['full_name'] as String) : 'Unassigned',
            Icons.manage_accounts_rounded,
            AppColors.primary,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTeamMemberItem(
            'LEADER',
            leader != null ? (leader['full_name'] as String) : 'Unassigned',
            Icons.star_rounded,
            Colors.amber,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamMemberItem(String role, String name, IconData icon, Color iconColor, bool isDark) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                role,
                style: GoogleFonts.outfit(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF64748B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('Delete Group', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${group['name']}"? This will remove all group members and shift plans.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(operationsRepositoryProvider).deleteGroup(group['id'] as String);
              ref.invalidate(_groupsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(100, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group Bottom Sheet (Create / Edit)
// ---------------------------------------------------------------------------

class _GroupBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final WidgetRef ref;

  const _GroupBottomSheet({this.existing, required this.ref});

  @override
  ConsumerState<_GroupBottomSheet> createState() => _GroupBottomSheetState();
}

class _GroupBottomSheetState extends ConsumerState<_GroupBottomSheet> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Elegant drag handle indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 20),
                      width: 48,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Title + Close Button Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Group' : 'Create New Group',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close_rounded, color: isDark ? Colors.white54 : Colors.grey),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                          padding: const EdgeInsets.all(8),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Form Input Sections
                  Text(
                    'Group Details',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    style: GoogleFonts.outfit(),
                    decoration: InputDecoration(
                      labelText: 'Group Name',
                      hintText: 'e.g., Riyadh South - HungerStation',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.groups_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Assignments',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDropdown(
                    'Platform',
                    _platforms,
                    _selectedPlatformId,
                    (v) => setState(() => _selectedPlatformId = v),
                    Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Zone (optional)',
                    _zones,
                    _selectedZoneId,
                    (v) => setState(() => _selectedZoneId = v),
                    Icons.explore_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    'Supervisor (optional)',
                    _supervisors,
                    _selectedSupervisorId,
                    (v) => setState(() => _selectedSupervisorId = v),
                    Icons.manage_accounts_rounded,
                  ),

                  const SizedBox(height: 28),

                  // Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(
                              color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  isEdit ? 'Save Changes' : 'Create Group',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<Map<String, dynamic>> items,
    String? value,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
        prefixIcon: Icon(icon, size: 20),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('None', style: GoogleFonts.outfit()),
        ),
        ...items.map(
          (p) => DropdownMenuItem<String>(
            value: p['id'] as String,
            child: Text(
              p['full_name'] ?? p['name'] ?? '',
              style: GoogleFonts.outfit(),
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name is required.')),
      );
      return;
    }
    setState(() => _loading = true);
    final repo = ref.read(operationsRepositoryProvider);
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary
              ? color
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? color
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
