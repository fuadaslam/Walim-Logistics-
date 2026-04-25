import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class VehicleDetailScreen extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final pos = vehicle.position;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vehicle.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            Text(vehicle.fullPlate, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_location_rounded),
            onPressed: () {},
            tooltip: 'Share Live Location',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
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
                          if (constraints.maxWidth > 700) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildModernSection(
                                    title: 'Vehicle Information',
                                    icon: Icons.info_outline_rounded,
                                    children: [
                                      _buildInfoTile('Unit Name', vehicle.name, Icons.label_rounded),
                                      _buildInfoTile('Identity Plate', vehicle.fullPlate, Icons.badge_rounded),
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
                                          title: 'Live Telemetry',
                                          icon: Icons.sensors_rounded,
                                          children: [
                                            _buildInfoTile('Current Speed', '${pos.speed.toStringAsFixed(1)} km/h', Icons.speed_rounded),
                                            _buildInfoTile('Ignition State', pos.ignition ? 'Active' : 'Standby', Icons.power_rounded),
                                            _buildInfoTile('Update Frequency', '${DateTime.now().difference(pos.timestamp).inSeconds}s ago', Icons.timer_rounded),
                                            if (pos.address.isNotEmpty) _buildInfoTile('Current Address', pos.address, Icons.location_on_rounded),
                                          ],
                                        ),
                                      const SizedBox(height: 24),
                                      _buildModernSection(
                                        title: 'Fleet Metrics',
                                        icon: Icons.analytics_outlined,
                                        children: [
                                          if (pos != null && pos.odometer > 0)
                                            _buildInfoTile('Odometer', '${(pos.odometer / 1000).toStringAsFixed(1)} km', Icons.route_rounded),
                                          _buildInfoTile('Engine Hours', '${vehicle.engineHours.toStringAsFixed(1)} h', Icons.access_time_filled_rounded),
                                          _buildInfoTile('Communication', vehicle.protocol.isEmpty ? 'TCP/IP Standard' : vehicle.protocol, Icons.wifi_tethering_rounded),
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
                                  if (vehicle.model.isNotEmpty) _buildInfoTile('Hardware', vehicle.model, Icons.memory_rounded),
                                  if (vehicle.vin.isNotEmpty) _buildInfoTile('VIN / Serial', vehicle.vin, Icons.fingerprint_rounded),
                                ],
                              ),
                              const SizedBox(height: 24),
                              if (pos != null)
                                _buildModernSection(
                                  title: 'Live Telemetry',
                                  icon: Icons.sensors_rounded,
                                  children: [
                                    _buildInfoTile('Current Speed', '${pos.speed.toStringAsFixed(1)} km/h', Icons.speed_rounded),
                                    _buildInfoTile('Ignition State', pos.ignition ? 'Active' : 'Standby', Icons.power_rounded),
                                    _buildInfoTile('Update Frequency', '${DateTime.now().difference(pos.timestamp).inSeconds}s ago', Icons.timer_rounded),
                                    if (pos.address.isNotEmpty) _buildInfoTile('Current Address', pos.address, Icons.location_on_rounded),
                                  ],
                                ),
                              const SizedBox(height: 24),
                              _buildModernSection(
                                title: 'Fleet Metrics',
                                icon: Icons.analytics_outlined,
                                children: [
                                  if (pos != null && pos.odometer > 0)
                                    _buildInfoTile('Odometer', '${(pos.odometer / 1000).toStringAsFixed(1)} km', Icons.route_rounded),
                                  _buildInfoTile('Engine Hours', '${vehicle.engineHours.toStringAsFixed(1)} h', Icons.access_time_filled_rounded),
                                  _buildInfoTile('Communication', vehicle.protocol.isEmpty ? 'TCP/IP Standard' : vehicle.protocol, Icons.wifi_tethering_rounded),
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
      ),
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
                        color: AppTheme.statusColor(vehicle.status, moving: pos.moving, ignition: pos.ignition),
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
    final color = AppTheme.statusColor(vehicle.status, moving: isMoving, ignition: hasIgnition);
    
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
              isMoving ? Icons.local_shipping_rounded : (hasIgnition ? Icons.pause_circle_rounded : Icons.stop_circle_rounded),
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
                  isMoving ? 'MOVING NOW' : (hasIgnition ? 'IDLING' : 'OFFLINE'),
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
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
    final color = AppTheme.statusColor(vehicle.status, moving: position.moving, ignition: position.ignition);
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
