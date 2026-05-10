import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../dashboard/presentation/widgets/dashboard_scaffold.dart';
import '../services/geocoding_provider.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';
import '../../../shared/models/profile.dart';
import '../../hr/presentation/rider_detail_screen.dart';
import '../../hr/presentation/hr_notifier.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = vehicle.position;
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Fetch staff list to dynamically link to the assigned rider
    final staffAsync = ref.watch(allStaffProvider);
    UserProfile? riderProfile;

    if (vehicle.riderName != null && staffAsync.hasValue) {
      final staffList = staffAsync.value ?? [];
      for (final member in staffList) {
        final name = member['full_name']?.toString() ?? '';
        final iqama = member['iqama_number']?.toString() ?? '';
        if (name.toLowerCase() == vehicle.riderName!.toLowerCase() ||
            (vehicle.iqamaNumber != null && iqama == vehicle.iqamaNumber)) {
          riderProfile = UserProfile.fromJson(member);
          break;
        }
      }
    }

    if (riderProfile == null && vehicle.riderName != null) {
      riderProfile = UserProfile(
        id: vehicle.iqamaNumber ?? 'fallback_rider',
        role: 'Rider',
        fullName: vehicle.riderName!,
        iqamaNumber: vehicle.iqamaNumber,
        status: 'active',
      );
    }

    return DashboardScaffold(
      title: 'VEHICLE CONSOLE',
      subtitle: 'Real-time telemetry and management portal for ${vehicle.name}',
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_location_rounded),
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: 'https://walim.logistics/live/vehicle/BD2731'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Live tracking link copied!'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          tooltip: 'Share Live Location',
        ),
        const SizedBox(width: 8),
      ],
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStunningHeroHeader(context, pos),
                  const SizedBox(height: 24),
                  if (isMobile)
                    Column(
                      children: [
                        _buildVehicleInfoCard(context),
                        const SizedBox(height: 24),
                        _buildSectionCard(
                          context: context,
                          title: 'Assigned Operator',
                          subtitle: 'Primary rider currently allocated to this vehicle',
                          icon: Icons.person_rounded,
                          child: _buildRiderCard(context, ref, riderProfile),
                        ),
                        const SizedBox(height: 24),
                        if (pos != null) ...[
                          _buildSectionCard(
                            context: context,
                            title: 'GPS Tracking Map',
                            subtitle: 'Real-time geographic position lock',
                            icon: Icons.map_rounded,
                            child: _buildMapSection(context, pos),
                          ),
                          const SizedBox(height: 24),
                          _buildTelemetryCard(context, ref, pos),
                        ] else
                          _buildGPSOfflineSection(context),
                        const SizedBox(height: 24),
                        _buildControlCenter(context),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildVehicleInfoCard(context),
                              const SizedBox(height: 24),
                              _buildSectionCard(
                                context: context,
                                title: 'Assigned Operator',
                                subtitle: 'Primary rider currently allocated to this vehicle',
                                icon: Icons.person_rounded,
                                child: _buildRiderCard(context, ref, riderProfile),
                              ),
                              const SizedBox(height: 24),
                              if (pos != null)
                                _buildTelemetryCard(context, ref, pos)
                              else
                                _buildGPSOfflineSection(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              if (pos != null) ...[
                                _buildSectionCard(
                                  context: context,
                                  title: 'GPS Tracking Map',
                                  subtitle: 'Real-time geographic position lock',
                                  icon: Icons.map_rounded,
                                  child: _buildMapSection(context, pos),
                                ),
                                const SizedBox(height: 24),
                              ],
                              _buildControlCenter(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStunningHeroHeader(BuildContext context, VehiclePosition? pos) {
    final isMoving = pos?.moving ?? false;
    final hasIgnition = pos?.ignition ?? false;
    final displayStatus = vehicle.getDisplayStatus();
    final color = AppTheme.statusColor(vehicle.status, moving: isMoving, ignition: hasIgnition, timestamp: pos?.timestamp);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
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
                    AppTheme.primary.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: isMobile ? 56 : 84,
                height: isMobile ? 56 : 84,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.motorcycle_rounded,
                    color: AppTheme.primary,
                    size: isMobile ? 28 : 42,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.name,
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 18 : 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: Text(
                            vehicle.fullPlate,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'IMEI: ${vehicle.id}',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayStatus.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMoving ? '${pos?.speed.toStringAsFixed(0)} kph' : 'Stationary Asset',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.textHeading,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textBody,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInteractiveTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    bool isCopyable = false,
  }) {
    final themeColor = color ?? AppTheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: themeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.textBody.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
              ],
            ),
          ),
          if (isCopyable && value != '-')
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 16, color: themeColor.withValues(alpha: 0.7)),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: IconButton.styleFrom(
                hoverColor: themeColor.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleInfoCard(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Vehicle Information',
      subtitle: 'Identity metrics and hardware parameters',
      icon: Icons.info_outline_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 550 ? 2 : 1;
          final itemWidth = (constraints.maxWidth / crossAxisCount) - (crossAxisCount == 2 ? 8 : 0);

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Unit Name',
                  value: vehicle.name,
                  icon: Icons.label_rounded,
                  color: Colors.orange,
                  isCopyable: true,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Identity Plate',
                  value: vehicle.fullPlate,
                  icon: Icons.badge_rounded,
                  color: Colors.orange,
                  isCopyable: true,
                ),
              ),
              if (vehicle.model.isNotEmpty)
                SizedBox(
                  width: itemWidth,
                  child: _buildInteractiveTile(
                    context,
                    label: 'Make & Model',
                    value: vehicle.make.isNotEmpty ? '${vehicle.make} ${vehicle.model}' : vehicle.model,
                    icon: Icons.directions_car_filled_rounded,
                  ),
                ),
              if (vehicle.vin.isNotEmpty)
                SizedBox(
                  width: itemWidth,
                  child: _buildInteractiveTile(
                    context,
                    label: 'VIN / Serial',
                    value: vehicle.vin,
                    icon: Icons.fingerprint_rounded,
                    isCopyable: true,
                  ),
                ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Odometer',
                  value: '${(vehicle.odometer > 0 ? (vehicle.odometer / 1000).toStringAsFixed(0) : '0')} km',
                  icon: Icons.route_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Device Protocol',
                  value: vehicle.protocol.isNotEmpty ? vehicle.protocol : 'TRACKER_v4',
                  icon: Icons.dns_rounded,
                  color: AppTheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, WidgetRef ref, UserProfile? profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.005),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
        ),
        child: Column(
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: AppTheme.textBody.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No Assigned Rider',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textHeading),
            ),
            const SizedBox(height: 4),
            Text(
              'This asset is currently unassigned to any rider.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textBody),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Assign Rider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Text(
                profile.fullName.isNotEmpty ? profile.fullName.substring(0, 1).toUpperCase() : 'R',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textHeading,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.badge_rounded, size: 14, color: AppTheme.textBody),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Iqama: ${profile.iqamaNumber ?? 'N/A'}',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textBody, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiderDetailScreen(profile: profile),
                ),
              );
            },
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              foregroundColor: AppTheme.primary,
              padding: const EdgeInsets.all(12),
            ),
            tooltip: 'View Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(BuildContext context, WidgetRef ref, VehiclePosition pos) {
    return _buildSectionCard(
      context: context,
      title: 'Detailed Telemetry',
      subtitle: 'Real-time sensor feeds and diagnostic data',
      icon: Icons.analytics_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 550 ? 2 : 1;
          final itemWidth = (constraints.maxWidth / crossAxisCount) - (crossAxisCount == 2 ? 8 : 0);

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Status',
                  value: vehicle.status.toUpperCase(),
                  icon: Icons.info_outline_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildAddressTile(context, ref, pos),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Altitude',
                  value: '${pos.altitude.toStringAsFixed(0)} m',
                  icon: Icons.height_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Angle Heading',
                  value: '${pos.heading.toStringAsFixed(0)} °',
                  icon: Icons.explore_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Coordinates',
                  value: '${pos.lat.toStringAsFixed(6)}, ${pos.lng.toStringAsFixed(6)}',
                  icon: Icons.my_location_rounded,
                  color: AppTheme.primary,
                  isCopyable: true,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Speed',
                  value: '${pos.speed.toStringAsFixed(0)} kph',
                  icon: Icons.speed_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Device Timestamp',
                  value: DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.timestamp),
                  icon: Icons.access_time_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Server Received Time',
                  value: pos.serverTimestamp != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.serverTimestamp!) : '-',
                  icon: Icons.dns_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'External Voltage',
                  value: '${pos.power.toStringAsFixed(2)} V',
                  icon: Icons.battery_charging_full_rounded,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _buildInteractiveTile(
                  context,
                  label: 'Ignition State',
                  value: pos.ignition ? 'ON' : 'OFF',
                  icon: Icons.power_settings_new_rounded,
                  color: pos.ignition ? AppTheme.success : AppTheme.danger,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressTile(BuildContext context, WidgetRef ref, VehiclePosition pos) {
    if (pos.address.isNotEmpty && pos.address != 'false') {
      return _buildInteractiveTile(context, label: 'Address', value: pos.address, icon: Icons.location_on_rounded, color: AppTheme.primary, isCopyable: true);
    }

    final addressAsync = ref.watch(geocodingProvider((lat: pos.lat, lng: pos.lng)));

    return addressAsync.when(
      data: (address) => _buildInteractiveTile(context, label: 'Address', value: address, icon: Icons.location_on_rounded, color: AppTheme.primary, isCopyable: true),
      loading: () => _buildInteractiveTile(context, label: 'Address', value: 'Fetching address...', icon: Icons.location_on_rounded, color: AppTheme.primary),
      error: (err, stack) => _buildInteractiveTile(context, label: 'Address', value: 'Address Unavailable', icon: Icons.location_on_rounded, color: AppTheme.primary),
    );
  }

  Widget _buildGPSOfflineSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.005),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.gps_off_rounded, size: 48, color: AppTheme.danger),
          ),
          const SizedBox(height: 20),
          Text(
            'GPS Telemetry Offline',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textHeading,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This vehicle is currently not transmitting live coordinates. Last known telemetry data is unavailable.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textBody,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pinging tracking unit...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.cell_tower_rounded, size: 16),
                label: const Text('Ping Device'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Requesting diagnostic signal...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlCenter(BuildContext context) {
    return _buildSectionCard(
      context: context,
      title: 'Control Center',
      subtitle: 'Execute diagnostic and administrative commands',
      icon: Icons.bolt_rounded,
      child: Column(
        children: [
          _buildActionButton(
            context,
            label: 'Share Live Link',
            icon: Icons.share_location_rounded,
            color: Colors.blue,
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'https://walim.logistics/live/vehicle/BD2731'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Live link copied to clipboard!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            label: 'Report Incident',
            icon: Icons.report_problem_rounded,
            color: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Incident reporting system coming soon'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            context,
            label: 'Request Maintenance',
            icon: Icons.build_rounded,
            color: Colors.purple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maintenance request filed successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.textHeading,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textBody.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, VehiclePosition pos) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(pos.lat, pos.lng),
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.walim.tracking',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(pos.lat, pos.lng),
                      width: 60,
                      height: 60,
                      child: _VehicleMarker(
                        moving: pos.moving,
                        heading: pos.heading,
                        color: AppTheme.statusColor(vehicle.status, moving: pos.moving, ignition: pos.ignition, timestamp: pos.timestamp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              bottom: 12,
              right: 12,
              child: FloatingActionButton.small(
                onPressed: () => _showFullMap(context, pos),
                backgroundColor: Colors.white,
                elevation: 2,
                child: const Icon(Icons.fullscreen_rounded, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullMap(BuildContext context, VehiclePosition pos) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _FullMapScreen(vehicle: vehicle, position: pos)));
  }
}

class _VehicleMarker extends StatelessWidget {
  final bool moving;
  final double heading;
  final Color color;

  const _VehicleMarker({required this.moving, required this.heading, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: heading * 3.14159 / 180,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10)],
        ),
        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _FullMapScreen extends StatelessWidget {
  final Vehicle vehicle;
  final VehiclePosition position;

  const _FullMapScreen({required this.vehicle, required this.position});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(vehicle.status, moving: position.moving, ignition: position.ignition, timestamp: position.timestamp);
    return Scaffold(
      appBar: AppBar(title: Text(vehicle.name)),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(position.lat, position.lng),
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.walim.tracking',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position.lat, position.lng),
                width: 56,
                height: 56,
                child: _VehicleMarker(moving: position.moving, heading: position.heading, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

