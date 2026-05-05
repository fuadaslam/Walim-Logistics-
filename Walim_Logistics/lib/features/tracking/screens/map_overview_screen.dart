import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import 'vehicle_detail_screen.dart';

class MapOverviewScreen extends StatefulWidget {
  final List<Vehicle> vehicles;

  const MapOverviewScreen({super.key, required this.vehicles});

  @override
  State<MapOverviewScreen> createState() => _MapOverviewScreenState();
}

class _MapOverviewScreenState extends State<MapOverviewScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final withPositions = widget.vehicles.where((v) => v.position != null).toList();

    LatLng initialCenter = const LatLng(24.7136, 46.6753); // Riyadh
    if (withPositions.isNotEmpty) {
      final pos = withPositions.first.position!;
      initialCenter = LatLng(pos.lat, pos.lng);
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: withPositions.length == 1 ? 13 : 8,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.walim.tracking',
            ),
            MarkerLayer(
              markers: withPositions.map((vehicle) {
                final pos = vehicle.position!;
                return Marker(
                  point: LatLng(pos.lat, pos.lng),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showVehiclePopup(context, vehicle),
                    child: _MapMarker(vehicle: vehicle),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 20,
          left: 20,
          child: Row(
            children: [
              if (Navigator.canPop(context)) ...[
                _MapButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
              ],
              _MapOverlayHeader(count: withPositions.length),
            ],
          ),
        ),
        Positioned(
          bottom: 30,
          right: 20,
          child: _MapControls(
            onZoomIn: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
            onZoomOut: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
            onFitAll: () => _fitAllMarkers(withPositions),
            showFitAll: withPositions.isNotEmpty,
          ),
        ),
        if (withPositions.isEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_rounded, color: Colors.redAccent),
                  SizedBox(width: 12),
                  Text('No live tracking data available', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _fitAllMarkers(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) return;
    final positions = vehicles.map((v) => v.position!).toList();
    if (positions.length == 1) {
      _mapController.move(LatLng(positions[0].lat, positions[0].lng), 14);
      return;
    }

    double minLat = positions[0].lat, maxLat = positions[0].lat;
    double minLng = positions[0].lng, maxLng = positions[0].lng;

    for (final pos in positions) {
      if (pos.lat < minLat) minLat = pos.lat;
      if (pos.lat > maxLat) maxLat = pos.lat;
      if (pos.lng < minLng) minLng = pos.lng;
      if (pos.lng > maxLng) maxLng = pos.lng;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    _mapController.move(LatLng(centerLat, centerLng), 6);
  }

  void _showVehiclePopup(BuildContext context, Vehicle vehicle) {
    final pos = vehicle.position!;
    final color = AppTheme.statusColor(vehicle.status, moving: pos.moving, ignition: pos.ignition);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(pos.moving ? Icons.local_shipping_rounded : Icons.pause_circle_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        vehicle.fullPlate,
                        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _PopupStat(icon: Icons.speed_rounded, label: 'Speed', value: '${pos.speed.toStringAsFixed(0)} km/h'),
                _PopupStat(icon: Icons.gps_fixed_rounded, label: 'Accuracy', value: 'High'),
                _PopupStat(icon: Icons.access_time_rounded, label: 'Seen', value: '${DateTime.now().difference(pos.timestamp).inMinutes}m ago'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Open Vehicle Dashboard', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOverlayHeader extends StatelessWidget {
  final int count;
  const _MapOverlayHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.share_location_rounded, color: AppTheme.primary, size: 18),
          const SizedBox(width: 10),
          Text(
            '$count Assets Live',
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitAll;
  final bool showFitAll;

  const _MapControls({required this.onZoomIn, required this.onZoomOut, required this.onFitAll, this.showFitAll = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showFitAll) ...[
          _MapButton(icon: Icons.center_focus_strong_rounded, onTap: onFitAll, isPrimary: true),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              _MapButton(icon: Icons.add_rounded, onTap: onZoomIn),
              const Divider(height: 1, indent: 8, endIndent: 8),
              _MapButton(icon: Icons.remove_rounded, onTap: onZoomOut),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MapButton({required this.icon, required this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppTheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF64748B), size: 24),
        ),
      ),
    );
  }
}

class _PopupStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PopupStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  final Vehicle vehicle;
  const _MapMarker({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final pos = vehicle.position!;
    final color = AppTheme.statusColor(vehicle.status, moving: pos.moving, ignition: pos.ignition);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
        Transform.rotate(
          angle: pos.heading * 3.14159 / 180,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Icon(
              pos.moving ? Icons.navigation_rounded : Icons.circle_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
}
