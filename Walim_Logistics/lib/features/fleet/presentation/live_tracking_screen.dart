import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/tracking/services/location_providers.dart';
import 'package:walim_logistics/core/services/location_service.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final bool showScaffold;
  const LiveTrackingScreen({super.key, this.showScaffold = true});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(24.7136, 46.6753); // Default to Riyadh
  String _locationLabel = 'Riyadh Central';
  bool _isLocationInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final hasPermission = await locationService.checkPermissions();
      
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _locationLabel = 'Current Location';
            _isLocationInitialized = true;
          });
          
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition, 12),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
    }
  }

  Set<Marker> _buildMarkers(List<dynamic> riders) {
    return riders.map((rider) {
      return Marker(
        markerId: MarkerId(rider.id ?? 'unknown'),
        position: LatLng(rider.lastLat ?? 0, rider.lastLng ?? 0),
        infoWindow: InfoWindow(
          title: '${rider.fullName ?? 'Rider'}',
          snippet: 'Last seen: ${rider.lastLocationUpdate != null ? _formatDate(rider.lastLocationUpdate!) : 'Unknown'}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(allRidersLocationProvider);

    final content = Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                ridersAsync.when(
                  data: (riders) => GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition,
                      zoom: 12,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_isLocationInitialized) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(_currentPosition, 12),
                        );
                      }
                    },
                    markers: _buildMarkers(riders),
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
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
                    child: ridersAsync.when(
                      data: (riders) => Row(
                        children: [
                          _buildStatusChip('Online: ${riders.length}', AppColors.accent),
                          const SizedBox(width: 8),
                          _buildStatusChip('Live tracking active', AppColors.textSecondary),
                          const Spacer(),
                          Text(_locationLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const Text('Error loading status'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.showScaffold) return content;

    return DashboardScaffold(
      title: 'LIVE FLEET MAP',
      subtitle: 'Real-time positioning of all active riders',
      showBackButton: true,
      children: [content],
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
