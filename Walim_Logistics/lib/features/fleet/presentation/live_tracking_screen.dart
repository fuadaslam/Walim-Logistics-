import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  late GoogleMapController _mapController;
  
  // Placeholder markers
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Fleet Map'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(24.7136, 46.6753), // Riyadh center
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController.setMapStyle(_mapDarkStyle);
            },
            markers: _markers,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          
          // Bottom Info Sheet
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
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
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Placeholder for Google Maps Dark Style String
  static const String _mapDarkStyle = '[]'; 
}
