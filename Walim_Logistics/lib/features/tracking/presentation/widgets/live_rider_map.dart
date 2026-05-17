import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/features/tracking/services/location_providers.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';

class LiveRiderMap extends ConsumerStatefulWidget {
  const LiveRiderMap({super.key});

  @override
  ConsumerState<LiveRiderMap> createState() => _LiveRiderMapState();
}

class _LiveRiderMapState extends ConsumerState<LiveRiderMap> {
  final MapController _mapController = MapController();
  String _searchQuery = '';
  String _selectedCity = 'All';
  final TextEditingController _searchController = TextEditingController();

  static const _cities = {
    'All': LatLng(23.8859, 45.0792),
    'Riyadh': LatLng(24.7136, 46.6753),
    'Jeddah': LatLng(21.4858, 39.1925),
    'Taif': LatLng(21.2854, 40.4094),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ridersAsync = ref.watch(allRidersLocationProvider);

    return ridersAsync.when(
      data: (riders) {
        final filteredRiders = riders.where((r) {
          final query = _searchQuery.toLowerCase();
          final matchesSearch = r.fullName.toLowerCase().contains(query) ||
              (r.phoneNumber?.contains(query) ?? false);
          
          if (!matchesSearch) return false;
          if (_selectedCity == 'All') return true;

          final lat = r.lastLat!;
          final lng = r.lastLng!;
          if (_selectedCity == 'Riyadh') {
            return lat > 24.0 && lat < 25.5 && lng > 46.0 && lng < 47.5;
          } else if (_selectedCity == 'Jeddah') {
            return lat > 21.0 && lat < 22.0 && lng > 38.8 && lng < 39.6;
          } else if (_selectedCity == 'Taif') {
            return lat > 20.8 && lat < 21.8 && lng > 40.0 && lng < 41.0;
          }
          return true;
        }).toList();

        return Column(
          children: [
            _buildSearchHeader(),
            _buildCityToggle(),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _cities[_selectedCity]!,
                      initialZoom: _selectedCity == 'All' ? 5.0 : 12.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.walim.walim_logistics',
                      ),
                      MarkerLayer(
                        markers: filteredRiders.map((rider) {
                          return Marker(
                            point: LatLng(rider.lastLat!, rider.lastLng!),
                            width: 60,
                            height: 60,
                            child: GestureDetector(
                              onTap: () => _showRiderDetails(context, rider),
                              child: _buildRiderMarker(rider),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  _buildRiderCount(filteredRiders.length),
                  Positioned(
                    bottom: 24,
                    right: 16,
                    child: Column(
                      children: [
                        _buildMapControlButton(
                          icon: Icons.my_location_rounded,
                          onTap: () => _mapController.move(_cities[_selectedCity]!, _selectedCity == 'All' ? 5 : 12),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMapControlButton(
                                icon: Icons.add_rounded,
                                onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                                noShadow: true,
                              ),
                              Divider(height: 1, color: Theme.of(context).dividerColor),
                              _buildMapControlButton(
                                icon: Icons.remove_rounded,
                                onTap: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                                noShadow: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCityToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _cities.keys.map((city) {
            final isSelected = _selectedCity == city;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCity = city);
                    _mapController.move(_cities[city]!, city == 'All' ? 5 : 12);
                  }
                },
                selectedColor: AppColors.primary,
                labelStyle: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
                elevation: isSelected ? 4 : 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search rider by name or phone...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildRiderMarker(UserProfile rider) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              rider.fullName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            rider.fullName.split(' ')[0],
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildRiderCount(int count) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '$count Riders Active',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMapControlButton({required IconData icon, required VoidCallback onTap, bool noShadow = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: noShadow ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  void _showRiderDetails(BuildContext context, UserProfile rider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    rider.fullName[0].toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.fullName,
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Rider ID: ${rider.id.substring(0, 8)}',
                        style: GoogleFonts.outfit(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.phone, 'Phone', rider.phoneNumber ?? 'N/A'),
            _buildInfoRow(Icons.access_time, 'Last Update', _formatLastUpdate(rider.lastLocationUpdate)),
            _buildInfoRow(Icons.location_on, 'Location', '${rider.lastLat?.toStringAsFixed(4)}, ${rider.lastLng?.toStringAsFixed(4)}'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _mapController.move(LatLng(rider.lastLat!, rider.lastLng!), 15);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.my_location_rounded, size: 18),
                    label: const Text('Focus on Map', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RiderDetailScreen(profile: rider),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.badge_outlined, size: 18, color: Colors.white),
                    label: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text('$label: ', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
          Text(value, style: GoogleFonts.outfit()),
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime? dateTime) {
    if (dateTime == null) return 'Never';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
