import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../dashboard/presentation/widgets/dashboard_scaffold.dart';
import '../services/geocoding_provider.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = vehicle.position;

    return DashboardScaffold(
      title: vehicle.name,
      subtitle: vehicle.fullPlate,
      showBackButton: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_location_rounded),
          onPressed: () {},
          tooltip: 'Share Live Location',
        ),
        const SizedBox(width: 8),
      ],
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pos != null) _buildMapSection(context, pos),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusHighlight(pos),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 850) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 320,
                                  child: _buildModernSection(
                                    title: 'Vehicle Information',
                                    icon: Icons.info_outline_rounded,
                                    children: [
                                      _buildInfoTile('Unit Name', vehicle.name, Icons.label_rounded, color: Colors.orange),
                                      _buildInfoTile('Identity Plate', vehicle.fullPlate, Icons.badge_rounded, color: Colors.orange),
                                      if (vehicle.riderName != null) _buildInfoTile('Rider Name', vehicle.riderName!, Icons.person_rounded, color: Colors.blue),
                                      if (vehicle.iqamaNumber != null) _buildInfoTile('Iqama Number', vehicle.iqamaNumber!, Icons.badge_outlined, color: Colors.blue),
                                      if (vehicle.model.isNotEmpty) _buildInfoTile('Hardware', vehicle.model, Icons.memory_rounded),
                                      if (vehicle.vin.isNotEmpty) _buildInfoTile('VIN / Serial', vehicle.vin, Icons.fingerprint_rounded),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    children: [
                                      if (pos != null)
                                        _buildModernSection(
                                          title: 'Detailed Telemetry',
                                          icon: Icons.analytics_outlined,
                                          children: [
                                            _buildInfoTile('Odometer', '${(pos.odometer > 0 ? (pos.odometer / 1000).toStringAsFixed(0) : '0')} km', Icons.route_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Status', vehicle.status.toUpperCase(), Icons.info_outline_rounded, color: AppTheme.primary),
                                            _buildAddressTile(ref, pos),
                                            _buildInfoTile('Altitude', '${pos.altitude.toStringAsFixed(0)} m', Icons.height_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Angle', '${pos.heading.toStringAsFixed(0)} °', Icons.explore_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Position', '${pos.lat.toStringAsFixed(6)} °, ${pos.lng.toStringAsFixed(6)} °', Icons.my_location_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Speed', '${pos.speed.toStringAsFixed(0)} kph', Icons.speed_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Time (position)', DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.timestamp), Icons.access_time_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Time (server)', pos.serverTimestamp != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.serverTimestamp!) : '-', Icons.dns_rounded, color: AppTheme.primary),
                                            _buildInfoTile('External Power', '${pos.power.toStringAsFixed(2)} V', Icons.battery_charging_full_rounded, color: AppTheme.primary),
                                            _buildInfoTile('Ignition', pos.ignition ? 'on' : 'off', Icons.power_settings_new_rounded, color: AppTheme.primary),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          return Column(
                            children: [
                              _buildModernSection(
                                title: 'Vehicle Information',
                                icon: Icons.info_outline_rounded,
                                children: [
                                  _buildInfoTile('Unit Name', vehicle.name, Icons.label_rounded),
                                  _buildInfoTile('Identity Plate', vehicle.fullPlate, Icons.badge_rounded),
                                  if (vehicle.riderName != null) _buildInfoTile('Rider Name', vehicle.riderName!, Icons.person_rounded, color: Colors.blue),
                                  if (vehicle.iqamaNumber != null) _buildInfoTile('Iqama Number', vehicle.iqamaNumber!, Icons.badge_outlined, color: Colors.blue),
                                  if (vehicle.model.isNotEmpty) _buildInfoTile('Hardware', vehicle.model, Icons.memory_rounded),
                                  if (vehicle.vin.isNotEmpty) _buildInfoTile('VIN / Serial', vehicle.vin, Icons.fingerprint_rounded),
                                ],
                              ),
                              const SizedBox(height: 24),
                                  if (pos != null)
                                    _buildModernSection(
                                      title: 'Detailed Telemetry',
                                      icon: Icons.analytics_outlined,
                                      children: [
                                        _buildInfoTile('Odometer', '${(pos.odometer > 0 ? (pos.odometer / 1000).toStringAsFixed(0) : '0')} km', Icons.route_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Status', vehicle.status.toUpperCase(), Icons.info_outline_rounded, color: AppTheme.primary),
                                        _buildAddressTile(ref, pos),
                                        _buildInfoTile('Altitude', '${pos.altitude.toStringAsFixed(0)} m', Icons.height_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Angle', '${pos.heading.toStringAsFixed(0)} °', Icons.explore_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Position', '${pos.lat.toStringAsFixed(6)} °, ${pos.lng.toStringAsFixed(6)} °', Icons.my_location_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Speed', '${pos.speed.toStringAsFixed(0)} kph', Icons.speed_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Time (position)', DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.timestamp), Icons.access_time_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Time (server)', pos.serverTimestamp != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(pos.serverTimestamp!) : '-', Icons.dns_rounded, color: AppTheme.primary),
                                        _buildInfoTile('External Power', '${pos.power.toStringAsFixed(2)} V', Icons.battery_charging_full_rounded, color: AppTheme.primary),
                                        _buildInfoTile('Ignition', pos.ignition ? 'on' : 'off', Icons.power_settings_new_rounded, color: AppTheme.primary),
                                      ],
                                    ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context, VehiclePosition pos) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mapHeight = (screenHeight * 0.35).clamp(280.0, 450.0);
    
    return Container(
      height: mapHeight,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
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
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () => _showFullMap(context, pos),
                backgroundColor: Colors.white,
                child: const Icon(Icons.fullscreen_rounded, color: AppTheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHighlight(VehiclePosition? pos) {
    final isMoving = pos?.moving ?? false;
    final hasIgnition = pos?.ignition ?? false;
    String displayStatus = vehicle.status;
    if (displayStatus == 'offline' && pos != null) {
      if (DateTime.now().difference(pos.timestamp).inHours <= 48) {
        displayStatus = 'stopped';
      }
    }
    final color = AppTheme.statusColor(vehicle.status, moving: isMoving, ignition: hasIgnition, timestamp: pos?.timestamp);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
            child: Icon(
              displayStatus == 'moving' ? Icons.local_shipping_rounded : (displayStatus == 'idle' ? Icons.pause_circle_rounded : (displayStatus == 'stopped' ? Icons.stop_circle_outlined : Icons.wifi_off_rounded)),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayStatus.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ),
                const SizedBox(height: 2),
                Text(
                  isMoving ? '${pos?.speed.toStringAsFixed(0)} km/h Speed' : 'Stationary Asset',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF1E293B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSection({required String title, required IconData icon, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 850 ? 2 : (constraints.maxWidth > 600 ? 3 : (constraints.maxWidth > 400 ? 2 : 1));
              final itemWidth = (constraints.maxWidth / crossAxisCount).floorToDouble();
              
              return Wrap(
                children: children.map((child) => SizedBox(
                  width: itemWidth,
                  child: child,
                )).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, {Color? color}) {
    final themeColor = color ?? AppTheme.primary;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile(WidgetRef ref, VehiclePosition pos) {
    if (pos.address.isNotEmpty && pos.address != 'false') {
      return _buildInfoTile('Address', pos.address, Icons.location_on_rounded, color: AppTheme.primary);
    }

    final addressAsync = ref.watch(geocodingProvider((lat: pos.lat, lng: pos.lng)));
    
    return addressAsync.when(
      data: (address) => _buildInfoTile('Address', address, Icons.location_on_rounded, color: AppTheme.primary),
      loading: () => _buildInfoTile('Address', 'Fetching address...', Icons.location_on_rounded, color: AppTheme.primary),
      error: (err, stack) => _buildInfoTile('Address', 'Address Unavailable', Icons.location_on_rounded, color: AppTheme.primary),
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
