import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/admin/presentation/monitoring_providers.dart';
import 'package:walim_logistics/shared/widgets/add_staff_dialog.dart';
import 'package:walim_logistics/shared/widgets/add_asset_dialog.dart';
import 'package:walim_logistics/shared/widgets/add_platform_dialog.dart';

class QuickAddMenu extends ConsumerWidget {
  const QuickAddMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTab = ref.watch(navigationProvider).activeTab;

    switch (activeTab) {
      case DashboardTab.riders:
        return _buildDirectAddButton(
          context,
          label: 'ADD RIDER',
          icon: Icons.person_add_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddStaffDialog(initialRole: 'Rider'),
          ).then((_) {
            ref.invalidate(allStaffProvider);
            ref.invalidate(detailedRidersProvider);
          }),
        );
      case DashboardTab.supervisors:
        return _buildDirectAddButton(
          context,
          label: 'ADD SUPERVISOR',
          icon: Icons.person_add_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddStaffDialog(initialRole: 'Supervisor'),
          ).then((_) {
            ref.invalidate(allStaffProvider);
            ref.invalidate(detailedSupervisorsProvider);
          }),
        );
      case DashboardTab.hr:
        return _buildDirectAddButton(
          context,
          label: 'ADD STAFF',
          icon: Icons.person_add_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddStaffDialog(),
          ).then((_) => ref.invalidate(allStaffProvider)),
        );
      case DashboardTab.vehicles:
        return _buildDirectAddButton(
          context,
          label: 'ADD VEHICLE',
          icon: Icons.directions_car_filled_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddAssetDialog(),
          ),
        );
      case DashboardTab.assets:
        return _buildDirectAddButton(
          context,
          label: 'ADD ASSET',
          icon: Icons.inventory_2_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddAssetDialog(),
          ),
        );
      case DashboardTab.platforms:
        return _buildDirectAddButton(
          context,
          label: 'ADD PLATFORM',
          icon: Icons.hub_rounded,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AddPlatformDialog(),
          ).then((_) => ref.invalidate(detailedPlatformsProvider)),
        );
      default:
        return PopupMenuButton<String>(
          offset: const Offset(0, -130), // Offset upwards for FAB usage
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 24,
          color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.98) : Colors.white,
          tooltip: 'Quick Add',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  'ADD',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          onSelected: (value) {
            if (value == 'staff') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddStaffDialog(),
              ).then((_) {
                ref.invalidate(allStaffProvider);
                ref.invalidate(detailedRidersProvider);
                ref.invalidate(detailedSupervisorsProvider);
              });
            } else if (value == 'asset') {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddAssetDialog(),
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'staff',
              child: _buildItem(
                context,
                Icons.person_add_rounded,
                'Add Staff',
                'Register new rider or manager',
                Colors.blue,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'asset',
              child: _buildItem(
                context,
                Icons.directions_car_filled_rounded,
                'Add Asset',
                'Register new vehicle',
                Colors.orange,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildDirectAddButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
