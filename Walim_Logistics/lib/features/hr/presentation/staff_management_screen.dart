import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/shared/models/profile.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String _searchQuery = '';
  String _selectedRole = 'All';
  final List<String> _roles = [
    'All',
    'Admin',
    'Operations Manager',
    'Supervisor',
    'Leader',
    'Rider',
    'HR',
    'Finance Manager',
    'IT_Dev',
    'Business Development',
  ];

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return DashboardScaffold(
      title: 'STAFF MONITORING',
      subtitle: 'Monitor and manage all team members across the organization',
      showBackButton: true,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      searchHint: 'Search by name, ID or phone...',
      children: [
        _buildRoleFilter(),
        const SizedBox(height: 24),
        staffAsync.when(
          data: (staff) {
            final filteredStaff = staff.where((member) {
              final profile = UserProfile.fromJson(member);
              final matchesSearch = profile.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  profile.id.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesRole = _selectedRole == 'All' || profile.role == _selectedRole;
              return matchesSearch && matchesRole;
            }).toList();

            if (filteredStaff.isEmpty) {
              return _buildEmptyState();
            }

            return _buildStaffGrid(filteredStaff, isDesktop);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Staff', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddStaffDialog(),
    ).then((_) => ref.invalidate(allStaffProvider));
  }

  Widget _buildRoleFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _roles.map((role) {
          final isSelected = _selectedRole == role;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedRole = role);
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primary,
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStaffGrid(List<Map<String, dynamic>> staff, bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 100,
      ),
      itemCount: staff.length,
      itemBuilder: (context, index) {
        final profile = UserProfile.fromJson(staff[index]);
        return _buildStaffCard(profile);
      },
    );
  }

  Widget _buildStaffCard(UserProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiderDetailScreen(profile: profile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildAvatar(profile),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    profile.fullName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(profile.role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      profile.role.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: _getRoleColor(profile.role),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.3), size: 20),
              onPressed: () => _confirmDelete(profile),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Member', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove ${profile.fullName} from the system?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(operationsRepositoryProvider).deleteProfile(profile.id);
                ref.invalidate(allStaffProvider);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(profile.role).withValues(alpha: 0.2),
            _getRoleColor(profile.role).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: _getRoleColor(profile.role).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          profile.fullName.isNotEmpty ? profile.fullName.substring(0, 1).toUpperCase() : '?',
          style: GoogleFonts.outfit(
            color: _getRoleColor(profile.role),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Admin': return Colors.red;
      case 'Operations Manager': return Colors.orange;
      case 'Supervisor': return Colors.blue;
      case 'Leader': return Colors.purple;
      case 'Rider': return Colors.teal;
      case 'HR': return Colors.pink;
      case 'Finance Manager': return Colors.green;
      case 'IT_Dev': return Colors.indigo;
      case 'Business Development': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Icon(Icons.people_outline_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No staff members found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or role filter',
            style: GoogleFonts.outfit(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddStaffDialog extends ConsumerStatefulWidget {
  const _AddStaffDialog();

  @override
  ConsumerState<_AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends ConsumerState<_AddStaffDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _iqamaCtrl = TextEditingController();
  String _selectedRole = 'Rider';
  bool _loading = false;

  final List<String> _roles = [
    'Admin',
    'Operations Manager',
    'Supervisor',
    'Leader',
    'Rider',
    'HR',
    'Finance Manager',
    'IT_Dev',
    'Business Development',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _iqamaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add New Staff Member', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _iqamaCtrl,
              decoration: const InputDecoration(labelText: 'Iqama Number (Optional)', prefixIcon: Icon(Icons.badge)),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Email are required')));
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(operationsRepositoryProvider).createProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        roleName: _selectedRole,
        iqamaNumber: _iqamaCtrl.text.trim().isEmpty ? null : _iqamaCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
