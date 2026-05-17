import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/shared/widgets/add_staff_dialog.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/shared/widgets/walim_table.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  final String? initialStatus;
  final String? initialSearch;
  const StaffManagementScreen({
    super.key,
    this.initialRole,
    this.initialStatus,
    this.initialSearch,
  });

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  late String _searchQuery;
  late String _selectedRole;
  late String? _selectedStatus;
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
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearch ?? '';
    _selectedRole = widget.initialRole ?? 'All';
    _selectedStatus = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentUserRole = ref.watch(authProvider).profile?.role;

    return DashboardScaffold(
      title: 'STAFF MONITORING',
      subtitle: 'Monitor and manage all team members across the organization',
      showBackButton: true,
      onSearchChanged: (value) => setState(() => _searchQuery = value),
      searchHint: 'Search by name, ID or phone...',
      body: Column(
        children: [
          _buildFilters(currentUserRole, isDark),
          const SizedBox(height: 24),
          Expanded(
            child: staffAsync.when(
              data: (staff) {
                final filteredStaff = staff.where((member) {
                  final profile = UserProfile.fromJson(member);
                  
                  // Apply role-based visibility restrictions
                  bool isVisibleByRole = true;
                  if (currentUserRole == 'Supervisor') {
                    isVisibleByRole = profile.role == 'Rider';
                  } else if (currentUserRole == 'Operations Manager') {
                    isVisibleByRole = profile.role == 'Rider' || profile.role == 'Supervisor';
                  }

                  if (!isVisibleByRole) return false;

                  final matchesSearch = profile.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      profile.id.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesRole = _selectedRole == 'All' || profile.role == _selectedRole;
                  final matchesStatus = _selectedStatus == null || profile.status == _selectedStatus;
                  return matchesSearch && matchesRole && matchesStatus;
                }).toList();

                if (isDesktop) {
                  return WalimDataTable<Map<String, dynamic>>(
                    columns: const [
                      WalimColumn(label: 'MEMBER', icon: Icons.person_outline_rounded),
                      WalimColumn(label: 'ROLE', icon: Icons.shield_outlined),
                      WalimColumn(label: 'STATUS', icon: Icons.info_outline_rounded),
                      WalimColumn(label: 'CONTACT', icon: Icons.phone_android_rounded),
                    ],
                    items: filteredStaff,
                    rowBuilder: (pagedStaff) => pagedStaff.map((member) {
                      final profile = UserProfile.fromJson(member);
                      return DataRow(
                        onSelectChanged: (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiderDetailScreen(profile: profile),
                            ),
                          );
                        },
                        cells: [
                          DataCell(_buildStaffInfo(profile)),
                          DataCell(_buildRoleBadge(profile.role)),
                          DataCell(_buildStatusBadge(profile.status)),
                          DataCell(Text(profile.phoneNumber ?? 'N/A', style: GoogleFonts.outfit(fontWeight: FontWeight.w600))),
                        ],
                      );
                    }).toList(),
                    emptyState: _buildEmptyState(),
                  );
                } else {
                  return SingleChildScrollView(
                    child: _buildStaffGrid(filteredStaff, isDesktop),
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Staff', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddStaffDialog(),
    ).then((_) => ref.invalidate(allStaffProvider));
  }

  Widget _buildFilters(String? currentUserRole, bool isDark) {
    List<String> visibleRoles = List.from(_roles);
    if (currentUserRole == 'Supervisor') {
      visibleRoles = ['All', 'Rider'];
    } else if (currentUserRole == 'Operations Manager') {
      visibleRoles = ['All', 'Supervisor', 'Rider'];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                'Filters',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: visibleRoles.map((role) {
                final isSelected = _selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(role),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedRole = role);
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.transparent,
                    labelStyle: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedStatus != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Status: ',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _selectedStatus!.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.primary,
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                  onDeleted: () => setState(() => _selectedStatus = null),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffInfo(UserProfile profile) {
    return Row(
      children: [
        _buildAvatar(profile),
        const SizedBox(width: 12),
        Text(
          profile.fullName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status.toLowerCase()) {
      case 'active_completed':
      case 'active':
        label = 'Active';
        color = const Color(0xFF10B981); // Emerald Green
        break;
      case 'active_pending':
        label = 'Pending KYC';
        color = const Color(0xFFF59E0B); // Amber
        break;
      case 'on_leave':
      case 'on leave':
        label = 'On Leave';
        color = const Color(0xFF3B82F6); // Blue
        break;
      case 'inactive':
      case 'inactive_completed':
      case 'inactive_pending':
        label = 'Inactive';
        color = const Color(0xFFEF4444); // Red
        break;
      default:
        label = status;
        color = const Color(0xFF64748B); // Slate Grey
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
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
                  _buildRoleBadge(profile.role),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withValues(alpha: 0.3), size: 20),
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
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref.read(operationsRepositoryProvider).deleteProfile(profile.id);
                ref.invalidate(allStaffProvider);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getRoleColor(profile.role),
            _getRoleColor(profile.role).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getRoleColor(profile.role).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          profile.fullName.isNotEmpty ? profile.fullName.substring(0, 1).toUpperCase() : '?',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    return Colors.grey.shade500;
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

