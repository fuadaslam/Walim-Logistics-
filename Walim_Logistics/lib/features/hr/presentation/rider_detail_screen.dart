import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/fleet/presentation/fleet_asset_registry_screen.dart';
import 'package:walim_logistics/features/hr/presentation/asset_management_screen.dart';
import 'package:walim_logistics/features/hr/presentation/document_vault_screen.dart';
import 'package:walim_logistics/features/incidents/presentation/incident_report_screen.dart';
import 'package:walim_logistics/features/fleet/presentation/shift_assignment_screen.dart';

import 'package:walim_logistics/features/fleet/data/fleet_repository.dart';
import 'package:walim_logistics/features/hr/data/hr_repository.dart';
import 'package:walim_logistics/shared/models/assigned_asset.dart';

import 'package:walim_logistics/features/admin/data/operations_repository.dart';
import 'package:walim_logistics/features/admin/data/office_repository.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/inspections/presentation/inspection_screen.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_widgets.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/rider_data_provider.dart';
import 'package:walim_logistics/features/hr/presentation/edit_profile_screen.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';
import 'package:walim_logistics/features/tracking/screens/vehicle_detail_screen.dart';
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';

final _riderAssetsProvider = FutureProvider.autoDispose.family<List<AssignedAsset>, String>((ref, id) async {
  final assets = await ref.watch(hrRepositoryProvider).getAssetsForProfile(id);
  
  try {
    final supabase = ref.watch(supabaseProvider);
    final vehicles = await supabase
        .from('vehicles')
        .select('id, plate_number, make, model, type, vin_number')
        .eq('assigned_profile_id', id);
        
    final List<AssignedAsset> vehicleAssets = (vehicles as List).map((v) {
      final plate = v['plate_number']?.toString() ?? '';
      final make = v['make']?.toString() ?? '';
      final model = v['model']?.toString() ?? '';
      final type = v['type']?.toString() ?? 'vehicle';
      
      String displayName = plate;
      if (displayName.isEmpty && make.isNotEmpty) {
        displayName = '$make $model';
      }
      if (displayName.isEmpty) {
        displayName = type.toUpperCase();
      }
      
      return AssignedAsset(
        assignmentId: v['id'] as String,
        profileId: id,
        assetId: v['id'] as String,
        assetName: displayName,
        assetCategory: 'vehicle',
        assetSerialNumber: v['vin_number'] as String?,
        assetStatus: 'assigned',
      );
    }).toList();
    
    // De-duplicate if the vehicle already exists in assets
    final existingAssetIds = assets.map((a) => a.assetId).toSet();
    final uniqueVehicleAssets = vehicleAssets.where((va) => !existingAssetIds.contains(va.assetId)).toList();
    
    return [...assets, ...uniqueVehicleAssets];
  } catch (e) {
    return assets;
  }
});

final _riderDocumentsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) {
  return ref.watch(hrRepositoryProvider).getDocumentsForProfile(id);
});

final _riderStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  return ref.watch(hrRepositoryProvider).getProfileStats(id);
});

final _riderZoneByIdProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) {
  return ref.watch(fleetRepositoryProvider).getRiderCurrentZone(id);
});



class RiderDetailScreen extends ConsumerWidget {
  final UserProfile? profile;
  
  const RiderDetailScreen({super.key, this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileByIdProvider(profile?.id ?? ''));
    final currentProfile = profileAsync.value ?? profile;

    if (currentProfile == null) {
      return const DashboardScaffold(
        title: 'Rider Profile',
        subtitle: 'Loading profile...',
        showBackButton: true,
        children: [Center(child: CircularProgressIndicator())],
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 900;
    final name = currentProfile.fullName;
    
    return DashboardScaffold(
      title: '${currentProfile.role} Details',
      subtitle: 'Managing identity and dynamics for $name',
      showBackButton: true,
      children: [
        _buildHeader(context, ref, currentProfile),
        SizedBox(height: isMobile ? 16 : 32),
        _buildStatsGrid(context, ref, currentProfile.id),
        SizedBox(height: isMobile ? 16 : 32),
        if (isMobile)
          Column(
            children: [
              _buildMainContent(context, ref, currentProfile),
              const SizedBox(height: 24),
              _buildSecondaryContent(context, ref, currentProfile),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildMainContent(context, ref, currentProfile),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildSecondaryContent(context, ref, currentProfile),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, WidgetRef ref, String? id) {
    if (id == null) return const SizedBox.shrink();
    
    final statsAsync = ref.watch(_riderStatsProvider(id));
    final isMobile = MediaQuery.of(context).size.width < 900;

    return statsAsync.when(
      data: (stats) {
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                  _buildStatCard(context, 'Total Working Days', stats['workingDays'].toString(), Icons.calendar_today_rounded, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'Working Hours', '${stats['workingHours']}h', Icons.access_time_rounded, Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard(context, 'Leave', '${stats['leaveDays']} Days', Icons.beach_access_rounded, Colors.orange),
                  const SizedBox(width: 12),
                  _buildStatCard(context, 'Requests', '${stats['pendingRequests']} Pending', Icons.history_edu_rounded, Colors.purple),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            _buildStatCard(context, 'Total Working Days', stats['workingDays'].toString(), Icons.calendar_today_rounded, Colors.blue),
            const SizedBox(width: 20),
            _buildStatCard(context, 'Working Hours', '${stats['workingHours']}h', Icons.access_time_rounded, Colors.green),
            const SizedBox(width: 20),
            _buildStatCard(context, 'Leave', '${stats['leaveDays']} Days', Icons.beach_access_rounded, Colors.orange),
            const SizedBox(width: 20),
            _buildStatCard(context, 'Requests', '${stats['pendingRequests']} Pending', Icons.history_edu_rounded, Colors.purple),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading stats: $e'),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, UserProfile currentProfile) {
    return Column(
      children: [
        _buildSectionCard(
          context: context,
          title: 'Personal & Legal Identity',
          icon: Icons.badge_outlined,
          child: _buildIdentityDetails(context, currentProfile),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Asset Assignments',
          icon: Icons.motorcycle_outlined,
          child: _buildAssetDetails(context, currentProfile),
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context: context,
          title: 'Performance Analytics',
          icon: Icons.insights_rounded,
          child: _buildPerformanceChart(context),
        ),
      ],
    );
  }

  Widget _buildSecondaryContent(BuildContext context, WidgetRef ref, UserProfile currentProfile) {
    final currentUser = ref.watch(authProvider).profile;
    final isRider = currentUser?.role == 'Rider';

    return Column(
      children: [
        _buildSectionCard(
          context: context,
          title: 'Compliance & Docs',
          icon: Icons.folder_shared_outlined,
          child: _buildComplianceList(context),
        ),
        const SizedBox(height: 24),
        if (isRider)
          _buildSectionCard(
            context: context,
            title: 'Account Actions',
            icon: Icons.account_circle_outlined,
            child: _buildActionRow(
              context,
              'Logout',
              Icons.logout_rounded,
              AppColors.error,
              () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to log out of your account?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(authProvider.notifier).signOut();
                }
              },
            ),
          )
        else
          _buildSectionCard(
            context: context,
            title: 'Quick Actions',
            icon: Icons.bolt_rounded,
            child: _buildQuickActions(context, ref, currentProfile),
          ),
      ],
    );
  }
  Widget _buildHeader(BuildContext context, WidgetRef ref, UserProfile currentProfile) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final name = currentProfile.fullName;
    final id = currentProfile.id;
    final displayId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
    
    final avatar = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: isMobile ? 64 : 110,
          height: isMobile ? 64 : 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
        ),
        Container(
          width: isMobile ? 52 : 94,
          height: isMobile ? 52 : 94,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: -2,
              )
            ],
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : "R",
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 22 : 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: isMobile ? 2 : 10,
          right: isMobile ? 2 : 10,
          child: Container(
            width: isMobile ? 14 : 18,
            height: isMobile ? 14 : 18,
            decoration: BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF0F172A), width: isMobile ? 2 : 3),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        ),
      ],
    );

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              name,
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 18 : 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            _buildStatusDropdown(context, ref, currentProfile),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'ID: $id • ${currentProfile.role}',
          textAlign: TextAlign.start,
          style: GoogleFonts.outfit(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: isMobile ? 12 : 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 20),
        Wrap(
          alignment: WrapAlignment.start,
          spacing: isMobile ? 6 : 10,
          runSpacing: isMobile ? 6 : 10,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final zoneAsync = ref.watch(_riderZoneByIdProvider(currentProfile.id));
                final locationText = currentProfile.location ?? zoneAsync.value?['name'] ?? 'Default Hub';
                return _buildHeaderTag(Icons.location_on_rounded, locationText);
              },
            ),
            if (currentProfile.platformName != null)
              _buildHeaderTag(Icons.hub_outlined, currentProfile.platformName!),
            if (currentProfile.groupName != null)
              _buildHeaderTag(Icons.group_work_outlined, currentProfile.groupName!),
          ],
        ),

      ],
    );

    final currentUser = ref.watch(authProvider).profile;
    final isOwnProfile = currentUser?.id == currentProfile.id;
    final isStaff = ['Admin', 'HR', 'Supervisor', 'Operations Manager'].contains(currentUser?.role);
    final canEdit = isOwnProfile || isStaff;

    final buttons = isMobile 
      ? Row(
          children: [
            if (canEdit)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileScreen(profile: currentProfile),
                      ),
                    );
                    if (updated == true) {
                      ref.invalidate(profileByIdProvider(currentProfile.id));
                    }
                  },
                  icon: Icon(Icons.edit_outlined, size: 14),
                  label: Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            if (canEdit && !isOwnProfile) SizedBox(width: 12),
            if (!isOwnProfile)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon')));
                  },
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
          ],
        )
      : Column(
          children: [
            if (canEdit)
              ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfileScreen(profile: currentProfile),
                    ),
                  );
                  if (updated == true) {
                    ref.invalidate(profileByIdProvider(currentProfile.id));
                  }
                },
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  minimumSize: Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            if (canEdit && !isOwnProfile) SizedBox(height: 12),
            if (!isOwnProfile)
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon')));
                },
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text('Message'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  minimumSize: Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
          ],
        );

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          isMobile 
            ? Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      avatar,
                      SizedBox(width: 16),
                      Expanded(child: info),
                    ],
                  ),
                  SizedBox(height: 16),
                  buttons,
                ],
              )
            : Row(
                children: [
                  avatar,
                  SizedBox(width: 32),
                  Expanded(child: info),
                  SizedBox(width: 32),
                  buttons,
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildHeaderTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 12),
          const SizedBox(width: 6),
          Text(
            label, 
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.7), 
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )
          ),
        ],
      ),
    );
  }


  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 20),
            ),
            SizedBox(height: isMobile ? 12 : 24),
            Text(
              value, 
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 20 : 28, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.5,
              )
            ),
            const SizedBox(height: 2),
            Text(
              label, 
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white54 : AppColors.textSecondary, 
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w500,
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required BuildContext context, required String title, required IconData icon, required Widget child}) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: isMobile ? 16 : 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          child,
        ],
      ),
    );
  }

  Widget _buildIdentityDetails(BuildContext context, UserProfile? profile) {
    final bool isSupervisor = profile?.role == 'Supervisor';
    
    return Column(
      children: [
        if (isSupervisor) ...[
          _buildDetailRow(context, 'Managed Platforms', profile?.managedPlatforms ?? 'None Designated'),
          _buildDetailRow(context, 'Managed Groups', profile?.managedGroups ?? 'None Designated'),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, thickness: 0.5),
          ),
          const SizedBox(height: 12),
        ] else ...[
          if (profile?.platformName != null)
            _buildDetailRow(context, 'Active Platform', profile!.platformName!),
          if (profile?.groupName != null)
            _buildDetailRow(context, 'Primary Group', profile!.groupName!),
          if (profile?.platformName != null || profile?.groupName != null)
            const SizedBox(height: 12),
        ],
        _buildDetailRow(context, 'Iqama Number', profile?.iqamaNumber ?? 'N/A', isCopyable: true),
        _buildDetailRow(context, 'Passport Number', profile?.passportNumber ?? 'N/A', isCopyable: true),
        _buildDetailRow(context, 'Driving License', profile?.drivingLicense ?? 'Saudi Private (Valid)'),
        _buildDetailRow(context, 'Sponsorship', profile?.sponsorship ?? 'Walim Logistics Co.'),
        _buildDetailRow(context, 'Mobile Number', profile?.phoneNumber ?? 'N/A', isCopyable: true),
        _buildDetailRow(context, 'Emergency Contact', profile?.emergencyContact ?? 'N/A'),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isCopyable = false}) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(), 
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary.withValues(alpha: 0.6), 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              )
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value, 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, 
                      fontSize: 15,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )
                  ),
                ),
                if (isCopyable)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.copy_all_rounded, size: 16, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          if (isCopyable)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildAssetDetails(BuildContext context, UserProfile? profile) {
    if (profile == null) return const Center(child: Text('No profile data'));
    
    return Consumer(builder: (context, ref, _) {
      final assetsAsync = ref.watch(_riderAssetsProvider(profile.id));
      final vehicles = ref.watch(trackingProvider).vehicles;
      
      return assetsAsync.when(
        data: (assets) {
          if (assets.isEmpty) {
            return const EmptyStatePlaceholder(
              icon: Icons.inventory_2_outlined,
              title: 'No Assets Assigned',
              subtitle: 'This staff member hasn\'t been issued any company equipment yet.',
              color: Colors.blueGrey,
            );
          }
          return Column(
            children: assets.map((asset) {
              final isVehicle = asset.assetCategory?.toLowerCase() == 'vehicle';
              VoidCallback? onTap;
              
              if (isVehicle) {
                onTap = () {
                  final cleanAssetName = asset.assetName.replaceAll(' ', '').toLowerCase();
                  final matchingVehicle = vehicles.firstWhere(
                    (v) {
                      final cleanPlate = v.plateNumber.replaceAll(' ', '').toLowerCase();
                      return cleanPlate.isNotEmpty && (
                        cleanPlate == cleanAssetName || 
                        cleanAssetName.contains(cleanPlate) || 
                        cleanPlate.contains(cleanAssetName)
                      );
                    },
                    orElse: () => vehicles.firstWhere(
                      (v) => v.riderName?.toLowerCase() == profile.fullName.toLowerCase() || 
                             (profile.iqamaNumber != null && v.iqamaNumber == profile.iqamaNumber),
                      orElse: () => Vehicle(
                        id: asset.assetId,
                        name: asset.assetName,
                        plateNumber: asset.assetName,
                        riderName: profile.fullName,
                        iqamaNumber: profile.iqamaNumber,
                      ),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VehicleDetailScreen(vehicle: matchingVehicle),
                    ),
                  );
                };
              }
              
              return _buildAssetItem(
                context: context,
                category: asset.assetCategory ?? 'Asset',
                title: asset.assetName,
                subtitle: 'S/N: ${asset.assetSerialNumber ?? 'N/A'}',
                icon: _getAssetIcon(asset.assetCategory),
                color: _getAssetColor(asset.assetCategory),
                onTap: onTap,
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStatePlaceholder(
          icon: Icons.error_outline_rounded,
          title: 'Assets Unavailable',
          subtitle: 'Error loading assets: $e',
          color: AppColors.error,
        ),
      );
    });
  }

  IconData _getAssetIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'vehicle': return Icons.motorcycle;
      case 'bag': return Icons.shopping_bag_outlined;
      case 'uniform': return Icons.checkroom_outlined;
      case 'smartphone': return Icons.phone_android_rounded;
      default: return Icons.inventory_2_outlined;
    }
  }

  Color _getAssetColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'vehicle': return Colors.blue;
      case 'bag': return Colors.orange;
      case 'uniform': return Colors.purple;
      case 'smartphone': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Widget _buildAssetItem({
    required BuildContext context,
    required String category,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: isMobile ? 20 : 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toUpperCase(), 
                        style: GoogleFonts.outfit(
                          color: color.withValues(alpha: 0.7), 
                          fontSize: 8, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title, 
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, 
                          fontSize: isMobile ? 14 : 16,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        )
                      ),
                      Text(
                        subtitle, 
                        style: GoogleFonts.outfit(
                          color: AppColors.textSecondary.withValues(alpha: 0.6), 
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  ),
                ),
                if (!isMobile)
                  TextButton(
                    onPressed: onTap ?? () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Manage', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  IconButton(
                    onPressed: onTap ?? () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
                    },
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplianceList(BuildContext context) {
    if (profile == null) return const SizedBox();
    
    return Consumer(builder: (context, ref, _) {
      final docsAsync = ref.watch(_riderDocumentsProvider(profile!.id));
      
      return docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return const EmptyStatePlaceholder(
              icon: Icons.badge_outlined,
              title: 'No Documents Found',
              subtitle: 'Digital records for Iqama, Passport, or Health IDs are not available.',
              color: Colors.orange,
            );
          }
          return Column(
            children: docs.map((doc) {
              final expiry = DateTime.parse(doc['expiry_date']);
              final daysLeft = expiry.difference(DateTime.now()).inDays;
              final progress = (daysLeft / 365).clamp(0.0, 1.0);
              final color = daysLeft < 30 ? Colors.red : (daysLeft < 90 ? Colors.orange : Colors.green);
              
              return _buildComplianceItem(
                context, 
                doc['name'] ?? 'Document', 
                daysLeft < 0 ? 'Expired' : 'Expires in $daysLeft days', 
                progress, 
                color
              );
            }).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStatePlaceholder(
          icon: Icons.error_outline_rounded,
          title: 'Compliance Data Unavailable',
          subtitle: 'Error: $e',
          color: AppColors.error,
        ),
      );
    });
  }

  Widget _buildComplianceItem(BuildContext context, String title, String status, double progress, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentVaultScreen()));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title, 
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  letterSpacing: -0.2,
                )
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status, 
                  style: GoogleFonts.outfit(
                    color: color, 
                    fontSize: 11, 
                    fontWeight: FontWeight.w900
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 8,
                width: 300 * progress, // Simplified for demonstration
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, UserProfile currentProfile) {
    final currentUser = ref.watch(authProvider).profile;
    
    final canRequestOfficeVisit = () {
      if (currentUser == null) return false;
      final userRole = currentUser.role;
      final targetRole = currentProfile.role;

      if (userRole == 'Admin' || userRole == 'Operations Manager') {
        return targetRole == 'Rider' || targetRole == 'Supervisor';
      }
      
      if (userRole == 'Supervisor') {
        return targetRole == 'Rider' && currentProfile.supervisorId == currentUser.id;
      }
      
      return false;
    }();

    return Column(
      children: [
        if (canRequestOfficeVisit) ...[
          _buildActionRow(context, 'Request Office Visit', Icons.meeting_room_rounded, Colors.purple, () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Request Office Visit', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Text('Are you sure you want to request ${currentProfile.fullName} to visit the office?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Request', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                await ref.read(officeRepositoryProvider).requestOfficeCall(
                  targetProfileId: currentProfile.id,
                  requestedByProfileId: currentUser!.id,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Office request sent successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            }
          }),
          const SizedBox(height: 12),
        ],
        _buildActionRow(context, 'Perform Inspection', Icons.security_rounded, Colors.redAccent, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InspectionScreen()));
        }),
        const SizedBox(height: 12),
        _buildActionRow(context, 'Assign New Asset', Icons.add_business_rounded, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FleetAssetRegistryScreen()));
        }),
        const SizedBox(height: 12),
        _buildActionRow(context, 'Document Vault', Icons.folder_zip_outlined, Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentVaultScreen()));
        }),
        const SizedBox(height: 12),
        _buildActionRow(context, 'Assign Shift', Icons.event_available_rounded, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftAssignmentScreen()));
        }),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context, WidgetRef ref, UserProfile? profile) {
    if (profile == null) return const SizedBox();
    
    final statuses = ['Active', 'On Break', 'Offline', 'Suspended', 'Terminated'];
    final currentStatus = profile.status[0].toUpperCase() + profile.status.substring(1).toLowerCase();
    
    return PopupMenuButton<String>(
      initialValue: currentStatus,
      onSelected: (String status) async {
        try {
          await ref.read(operationsRepositoryProvider).updateProfileStatus(profile.id, status);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to $status')));
          ref.invalidate(allStaffProvider);
          ref.invalidate(profileByIdProvider(profile.id));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      itemBuilder: (BuildContext context) {
        return statuses.map((String status) {
          return PopupMenuItem<String>(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(status, style: GoogleFonts.outfit(fontSize: 14)),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _getStatusColor(currentStatus).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: _getStatusColor(currentStatus), shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              currentStatus.toUpperCase(),
              style: TextStyle(
                color: _getStatusColor(currentStatus), 
                fontSize: 8, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 1.0
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final cleanStatus = status.toLowerCase().replaceAll('_', ' ').trim();
    switch (cleanStatus) {
      case 'active':
      case 'active completed':
        return const Color(0xFF10B981); // Emerald Green
      case 'active pending':
        return const Color(0xFFF59E0B); // Amber/Orange
      case 'on break':
      case 'on leave':
        return Colors.orange;
      case 'offline':
        return Colors.grey;
      case 'suspended':
        return Colors.amber;
      case 'terminated':
        return Colors.red;
      case 'inactive':
      case 'inactive completed':
      case 'inactive pending':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }






  Widget _buildPerformanceChart(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 12),
            Text(
              'Weekly Performance Visualization',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const Text(
              '(Integrating with Live Telemetry Data)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
