import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  late GoogleMapController _mapController;
  
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('rider1'),
      position: LatLng(24.7136, 46.6753),
      infoWindow: InfoWindow(title: 'Ahmed - Online'),
    ),
    const Marker(
      markerId: MarkerId('rider2'),
      position: LatLng(24.7200, 46.6800),
      infoWindow: InfoWindow(title: 'Khalid - On Delivery'),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'LIVE FLEET MAP',
      subtitle: 'Real-time positioning of all active riders',
      showBackButton: true,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(24.7136, 46.6753),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                ),
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildStatusChip('Online: 12', AppColors.accent),
                        const SizedBox(width: 8),
                        _buildStatusChip('Offline: 2', AppColors.textSecondary),
                        const Spacer(),
                        const Text('Riyadh Central', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
