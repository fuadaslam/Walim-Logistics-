import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';

class ShiftClusterManagerScreen extends ConsumerStatefulWidget {
  const ShiftClusterManagerScreen({super.key});

  @override
  ConsumerState<ShiftClusterManagerScreen> createState() => _ShiftClusterManagerScreenState();
}

class _ShiftClusterManagerScreenState extends ConsumerState<ShiftClusterManagerScreen> {
  final MapController _mapController = MapController();
  
  // Mock data for clusters
  final List<DemandCluster> _clusters = [
    DemandCluster(
      name: 'Olaya District',
      center: const LatLng(24.7087, 46.6749),
      demandLevel: 0.85,
      riderCount: 12,
      requiredRiders: 20,
      color: Colors.redAccent,
    ),
    DemandCluster(
      name: 'King Fahd Road',
      center: const LatLng(24.7236, 46.6713),
      demandLevel: 0.65,
      riderCount: 15,
      requiredRiders: 18,
      color: Colors.orangeAccent,
    ),
    DemandCluster(
      name: 'Diplomatic Quarter',
      center: const LatLng(24.6789, 46.6212),
      demandLevel: 0.45,
      riderCount: 8,
      requiredRiders: 6,
      color: Colors.greenAccent,
    ),
    DemandCluster(
      name: 'Al Malaz',
      center: const LatLng(24.6647, 46.7328),
      demandLevel: 0.75,
      riderCount: 10,
      requiredRiders: 15,
      color: Colors.orangeAccent,
    ),
  ];

  DemandCluster? _selectedCluster;

  @override
  Widget build(BuildContext context) {
    return DashboardScaffold(
      title: 'SHIFT CLUSTER MANAGER',
      subtitle: 'Demand-based positioning & fleet balancing',
      showBackButton: true,
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(24.7136, 46.6753),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.walim.tracking',
                    ),
                    CircleLayer(
                      circles: _clusters.map((cluster) {
                        return CircleMarker(
                          point: cluster.center,
                          radius: 1000,
                          useRadiusInMeter: true,
                          color: cluster.color.withValues(alpha: 0.3),
                          borderColor: cluster.color,
                          borderStrokeWidth: 2,
                        );
                      }).toList(),
                    ),
                    MarkerLayer(
                      markers: _clusters.map((cluster) {
                        return Marker(
                          point: cluster.center,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCluster = cluster),
                            child: _ClusterMarker(cluster: cluster),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: _MapControlPanel(
                    onOptimize: _optimizeFleet,
                  ),
                ),
                if (_selectedCluster != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _ClusterDetailCard(
                      cluster: _selectedCluster!,
                      onClose: () => setState(() => _selectedCluster = null),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildStatsSection(),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operational Intelligence',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'System Load',
                value: 'High',
                subValue: '82% Utilization',
                icon: Icons.speed_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Supply Gap',
                value: '-14',
                subValue: 'Riders Needed',
                icon: Icons.person_search_rounded,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Avg. Response',
                value: '4.2m',
                subValue: 'Within Target',
                icon: Icons.timer_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _optimizeFleet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Optimizing fleet positioning based on real-time demand...'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class DemandCluster {
  final String name;
  final LatLng center;
  final double demandLevel;
  final int riderCount;
  final int requiredRiders;
  final Color color;

  DemandCluster({
    required this.name,
    required this.center,
    required this.demandLevel,
    required this.riderCount,
    required this.requiredRiders,
    required this.color,
  });
}

class _ClusterMarker extends StatelessWidget {
  final DemandCluster cluster;
  const _ClusterMarker({required this.cluster});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: cluster.color.withValues(alpha: 0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: cluster.color, width: 3),
      ),
      child: Center(
        child: Text(
          '${(cluster.demandLevel * 100).toInt()}%',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: cluster.color,
          ),
        ),
      ),
    );
  }
}

class _MapControlPanel extends StatelessWidget {
  final VoidCallback onOptimize;
  const _MapControlPanel({required this.onOptimize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          _ControlButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Optimize',
            onTap: onOptimize,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _ControlButton(
            icon: Icons.layers_rounded,
            label: 'Heatmap',
            onTap: () {},
            color: Colors.blueGrey,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClusterDetailCard extends StatelessWidget {
  final DemandCluster cluster;
  final VoidCallback onClose;

  const _ClusterDetailCard({required this.cluster, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final gap = cluster.requiredRiders - cluster.riderCount;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cluster.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grid_view_rounded, color: cluster.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cluster.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'High Demand Zone',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Riders', value: '${cluster.riderCount}'),
              _MiniStat(label: 'Needed', value: '${cluster.requiredRiders}'),
              _MiniStat(
                label: 'Gap', 
                value: '${gap > 0 ? '+' : ''}$gap',
                color: gap > 0 ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: cluster.color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Re-balance Fleet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
