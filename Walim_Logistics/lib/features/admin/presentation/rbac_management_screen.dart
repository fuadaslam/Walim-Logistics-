import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

// Permission definitions shared across the screen
const _allPermissions = [
  _Permission('Can view financial data', Icons.payments_rounded),
  _Permission('Can assign shifts', Icons.schedule_rounded),
  _Permission('Can approve leaves', Icons.event_available_rounded),
  _Permission('Can manage fleet assets', Icons.directions_car_rounded),
  _Permission('Can view reports', Icons.bar_chart_rounded),
  _Permission('Can manage riders', Icons.motorcycle_rounded),
  _Permission('Can manage supervisors', Icons.supervisor_account_rounded),
  _Permission('Can access admin panel', Icons.admin_panel_settings_rounded),
  _Permission('Can create groups', Icons.group_add_rounded),
];

const _defaultPermissions = {
  'Admin': {
    'Can view financial data': true,
    'Can assign shifts': true,
    'Can approve leaves': true,
    'Can manage fleet assets': true,
    'Can view reports': true,
    'Can manage riders': true,
    'Can manage supervisors': true,
    'Can access admin panel': true,
    'Can create groups': true,
  },
  'Operations Manager': {
    'Can view financial data': false,
    'Can assign shifts': true,
    'Can approve leaves': false,
    'Can manage fleet assets': true,
    'Can view reports': true,
    'Can manage riders': true,
    'Can manage supervisors': true,
    'Can access admin panel': false,
    'Can create groups': true,
  },
  'Supervisor': {
    'Can view financial data': false,
    'Can assign shifts': true,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': true,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'HR': {
    'Can view financial data': false,
    'Can assign shifts': false,
    'Can approve leaves': true,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'Finance Manager': {
    'Can view financial data': true,
    'Can assign shifts': false,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'Leader': {
    'Can view financial data': false,
    'Can assign shifts': true,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'Rider': {
    'Can view financial data': false,
    'Can assign shifts': false,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': false,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'Business Development': {
    'Can view financial data': true,
    'Can assign shifts': false,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': false,
    'Can create groups': false,
  },
  'IT Dev': {
    'Can view financial data': false,
    'Can assign shifts': false,
    'Can approve leaves': false,
    'Can manage fleet assets': false,
    'Can view reports': true,
    'Can manage riders': false,
    'Can manage supervisors': false,
    'Can access admin panel': true,
    'Can create groups': false,
  },
};

class _Permission {
  final String label;
  final IconData icon;
  const _Permission(this.label, this.icon);
}

class RBACManagementScreen extends StatefulWidget {
  const RBACManagementScreen({super.key});

  @override
  State<RBACManagementScreen> createState() => _RBACManagementScreenState();
}

class _RBACManagementScreenState extends State<RBACManagementScreen> {
  late Map<String, Map<String, bool>> _permissions;
  final Set<String> _editingRoles = {};
  final Set<String> _savedRoles = {};

  @override
  void initState() {
    super.initState();
    _permissions = {
      for (final entry in _defaultPermissions.entries)
        entry.key: Map<String, bool>.from(entry.value),
    };
  }

  void _togglePermission(String role, String permission) {
    setState(() {
      _permissions[role]![permission] = !(_permissions[role]![permission] ?? false);
      _savedRoles.remove(role);
    });
  }

  void _saveRole(String role) {
    setState(() {
      _editingRoles.remove(role);
      _savedRoles.add(role);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$role permissions saved'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetRole(String role) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset $role?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'This will restore the default permissions for this role.',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _permissions[role] = Map<String, bool>.from(_defaultPermissions[role]!);
                _editingRoles.remove(role);
                _savedRoles.remove(role);
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = _permissions.keys.toList();

    return DashboardScaffold(
      title: 'ACCESS CONTROL (RBAC)',
      subtitle: 'Manage user permissions and role assignments',
      showBackButton: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            final isEditing = _editingRoles.contains(role);
            final isSaved = _savedRoles.contains(role);
            return _buildRoleTile(role, isEditing, isSaved);
          },
        ),
      ],
    );
  }

  Widget _buildRoleTile(String role, bool isEditing, bool isSaved) {
    final perms = _permissions[role]!;
    final enabledCount = perms.values.where((v) => v).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEditing ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
          width: isEditing ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded && !isEditing) {
            setState(() => _editingRoles.add(role));
          }
        },
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Icon(_getRoleIcon(role), color: AppColors.primary, size: 20),
        ),
        title: Text(role, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '$enabledCount of ${_allPermissions.length} permissions enabled',
          style: TextStyle(
            color: enabledCount > 0 ? Colors.green : AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSaved)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Saved',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                ..._allPermissions.map((perm) => _buildPermissionRow(role, perm, perms[perm.label] ?? false)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _resetRole(role),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _saveRole(role),
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Save Permissions'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

  Widget _buildPermissionRow(String role, _Permission perm, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (value ? AppColors.primary : AppColors.textSecondary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              perm.icon,
              size: 14,
              color: value ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              perm.label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: value ? null : AppColors.textSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) => _togglePermission(role, perm.label),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'Admin': return Icons.security_rounded;
      case 'Rider': return Icons.motorcycle_rounded;
      case 'Leader': return Icons.leaderboard_rounded;
      case 'Finance Manager': return Icons.payments_rounded;
      case 'Operations Manager': return Icons.manage_accounts_rounded;
      case 'HR': return Icons.people_alt_rounded;
      case 'Supervisor': return Icons.supervisor_account_rounded;
      case 'Business Development': return Icons.trending_up_rounded;
      case 'IT Dev': return Icons.code_rounded;
      default: return Icons.person_rounded;
    }
  }
}
