import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../dashboard/presentation/widgets/dashboard_scaffold.dart';
import '../services/tracking_provider.dart';
import '../theme/app_theme.dart';
import '../models/vehicle.dart';
import 'vehicle_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showScaffold;
  const HomeScreen({super.key, this.showScaffold = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeMenu = 'Live Ops';
  final MapController _mapController = MapController();
  Vehicle? _selectedVehicle;
  bool _hasInitiallyCentered = false;
  bool _mapReady = false;
  bool _showTrackingSidebar = true;

  static const _cities = {
    'All':    LatLng(23.8859, 45.0792),
    'Riyadh': LatLng(24.7136, 46.6753),
    'Jeddah': LatLng(21.4858, 39.1925),
    'Taif':   LatLng(21.2854, 40.4094),
  };
  String _activeCity = 'All';

  void _onMapReady() {
    _mapReady = true;
    _checkInitialCentering();
  }

  void _checkInitialCentering() {
    if (_hasInitiallyCentered || !_mapReady || _activeCity == 'All') return;
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    if (provider.vehicles.isNotEmpty) {
      final vehicle = provider.vehicles.first;
      if (vehicle.position != null) {
        setState(() {
          _selectedVehicle = vehicle;
          _hasInitiallyCentered = true;
        });
        _mapController.move(LatLng(vehicle.position!.lat, vehicle.position!.lng), 8);
      }
    }
  }

  void _recenterOnVehicle(Vehicle vehicle) {
    if (!_mapReady || vehicle.position == null) return;
    _mapController.move(LatLng(vehicle.position!.lat, vehicle.position!.lng), 11);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TrackingProvider>(context);
    
    if (!widget.showScaffold) {
      return _buildContent(provider);
    }

    return DashboardScaffold(
      activeItem: 'Live Ops',
      title: 'Operations Control',
      subtitle: '${DateFormat('EEEE • d MMM yyyy • HH:mm').format(DateTime.now())} • Live sync ${provider.lastUpdate}',
      actions: [
        _buildSearchField(),
        const SizedBox(width: 16),
        _buildLanguageToggle(),
        const SizedBox(width: 12),
        _buildLiveStatus(provider),
        const SizedBox(width: 16),
        _buildUserAvatar(provider),
        const SizedBox(width: 16),
      ],
      children: [
        _buildContent(provider),
      ],
    );
  }

  Widget _buildContent(TrackingProvider provider) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 110,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _showTrackingSidebar ? 240 : 0,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 240,
                    maxWidth: 240,
                    alignment: Alignment.centerLeft,
                    child: _buildSidebar(),
                  ),
                ),
              ),
              Expanded(
                child: provider.isInitialLoad 
                  ? const Center(child: CircularProgressIndicator())
                  : _buildActiveView(provider),
              ),
            ],
          ),
          // Floating Toggle Button
          Positioned(
            left: _showTrackingSidebar ? 220 : 0,
            top: 12,
            child: GestureDetector(
              onTap: () => setState(() => _showTrackingSidebar = !_showTrackingSidebar),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 0),
                    )
                  ],
                ),
                child: Icon(
                  _showTrackingSidebar ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveView(TrackingProvider provider) {
    if (provider.isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    // Basic navigation logic
    final menu = _activeMenu.trim();
    if (menu == 'Live Ops') {
      return _buildMainDashboard(provider);
    } else if (menu == 'Riders') {
      return _buildRidersList(provider);
    } else if (menu == 'Incidents') {
      return _buildIncidentsPage(provider);
    } else if (['Noon', 'Keeta', 'Amazon', 'Jahez', 'Other', 'Ninja', 'Ninja Grocery'].contains(menu)) {
      return _buildPlatformDeepDive(provider, menu);
    } else if (['Riyadh', 'Jeddah', 'Taif'].contains(menu)) {
      return _buildCityDeepDive(provider, menu);
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 64, color: AppTheme.textBody.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('$menu View is under development', style: const TextStyle(color: AppTheme.textBody)),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final provider = Provider.of<TrackingProvider>(context);
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Image.asset('assets/Walim Logo.png', height: 28),
                const SizedBox(width: 12),
                const Text(
                  'Walim',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textHeading),
                ),
                const Text(' Logistics', style: TextStyle(fontSize: 16, color: AppTheme.textBody)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildSidebarCategory('OPERATIONS'),
          _buildSidebarItem('Live Ops', Icons.sensors_rounded, active: _activeMenu == 'Live Ops'),
          _buildSidebarItem('Riders', Icons.person_outline_rounded, 
            badge: provider.totalCount.toString(), active: _activeMenu == 'Riders'),
          _buildSidebarItem('Incidents', Icons.error_outline_rounded, 
            badge: provider.incidents.length.toString(), active: _activeMenu == 'Incidents'),
          
          const SizedBox(height: 24),
          _buildSidebarCategory('PLATFORMS'),
          ...provider.platforms.map((p) => _buildSidebarItem(
            p.name, 
            Icons.circle_outlined, 
            active: _activeMenu == p.name,
            badge: p.count.toString(),
          )),
          
          const SizedBox(height: 24),
          _buildSidebarCategory('LOCATIONS'),
          _buildSidebarItem(
            'All', 
            Icons.circle_outlined, 
            active: _activeCity == 'All' && _activeMenu == 'Live Ops',
            onTap: () {
              setState(() {
                _activeCity = 'All';
                _activeMenu = 'Live Ops';
              });
              _mapController.move(_cities['All']!, 5);
            },
          ),
          ...provider.cities.map((c) => _buildSidebarItem(
            c.name, 
            Icons.circle_outlined, 
            active: _activeMenu == c.name,
            badge: c.count.toString(),
            onTap: () {
              setState(() {
                _activeCity = c.name;
                _activeMenu = c.name;
              });
              _mapController.move(_cities[c.name]!, 11);
            },
          )),
          
          const SizedBox(height: 24),
          _buildSidebarCategory('PERFORMANCE'),
          _buildSidebarItem('Analytics', Icons.bar_chart_rounded, active: _activeMenu == 'Analytics'),
          _buildSidebarItem('SLA Monitor', Icons.verified_user_outlined, active: _activeMenu == 'SLA Monitor'),
        ],
      ),
    );
  }

  Widget _buildSidebarCategory(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 24, 8),
      child: Text(title, style: AppTheme.theme.textTheme.labelLarge),
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool active = false, String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => setState(() => _activeMenu = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: active ? const Border(left: BorderSide(color: AppTheme.primary, width: 3)) : null,
          color: active ? AppTheme.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: active ? AppTheme.primary : AppTheme.textBody),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: active ? AppTheme.textHeading : AppTheme.textBody,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null && badge != '0')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textBody)),
              ),
          ],
        ),
      ),
    );
  }

  // Removed _buildTopBar as it is merged into DashboardScaffold actions

  Widget _buildSearchField() {
    return Container(
      width: 320,
      height: 40,
      decoration: BoxDecoration(color: AppTheme.sidebarBg, borderRadius: BorderRadius.circular(8)),
      child: TextField(
        onChanged: (v) => Provider.of<TrackingProvider>(context, listen: false).setFilter(v),
        decoration: const InputDecoration(
          hintText: 'Search riders, vehicles, orders...',
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: AppTheme.textBody),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
      child: const Text('العربية', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildLiveStatus(TrackingProvider provider) {
    final isError = provider.error != null;
    final dot = Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        color: provider.loading
            ? AppTheme.warning
            : (isError ? AppTheme.danger : AppTheme.onlineColor),
        shape: BoxShape.circle,
      ),
    );
    final label = Text(
      provider.loading ? 'Syncing…' : (isError ? 'Sync Error' : 'Live'),
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    );
    final row = Row(children: [dot, const SizedBox(width: 8), label]);

    if (isError) {
      return Tooltip(
        message: provider.error!,
        child: InkWell(
          onTap: () => Provider.of<TrackingProvider>(context, listen: false).refresh(),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: row,
          ),
        ),
      );
    }
    return row;
  }

  Widget _buildUserAvatar(TrackingProvider provider) {
    String initials = '??';
    if (provider.userName.isNotEmpty) {
      initials = provider.userName.length >= 2 
        ? provider.userName.substring(0, 2).toUpperCase()
        : provider.userName.substring(0, 1).toUpperCase();
    }

    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(provider.userName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(provider.userBranch, style: const TextStyle(fontSize: 11, color: AppTheme.textBody)),
          ],
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primary)),
        ),
      ],
    );
  }

  Widget _buildMainDashboard(TrackingProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContentHeader(provider),
              if (provider.error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(provider),
              ],
              const SizedBox(height: 32),
              _buildStatGrid(provider),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: constraints.maxWidth * 0.65,
                          height: 600,
                          child: _buildMapSection(provider),
                        ),
                        const SizedBox(width: 24),
                        SizedBox(
                          width: constraints.maxWidth * 0.35 - 24,
                          height: 600,
                          child: SingleChildScrollView(
                            child: _buildRightPanels(provider),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildMapSection(provider),
                        const SizedBox(height: 24),
                        _buildRightPanels(provider),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(TrackingProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.error!,
              style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => Provider.of<TrackingProvider>(context, listen: false).refresh(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
          ),
        ],
      ),
    );
  }

  Widget _buildContentHeader(TrackingProvider provider) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations Control — ${provider.userBranch}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              '${DateFormat('EEEE • d MMM yyyy • HH:mm').format(DateTime.now())} • Live sync ${provider.lastUpdate}',
              style: const TextStyle(color: AppTheme.textBody, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        _buildTag('${provider.ordersInFlight} Active Orders', AppTheme.info),
        const SizedBox(width: 12),
        _buildTag('${provider.totalCount} Units Online', AppTheme.onlineColor),
        const SizedBox(width: 24),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text('WhatsApp blast'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            side: const BorderSide(color: AppTheme.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Rebalance zones'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatGrid(TrackingProvider provider) {
    return Row(
      children: [
        _buildStatusCard('MOVING', provider.movingCount.toString(), AppTheme.onlineColor, Icons.directions_run_rounded, 'moving', provider),
        _buildStatusCard('IDLE', provider.idleCount.toString(), Colors.amber, Icons.pause_circle_outline_rounded, 'idle', provider),
        _buildStatusCard('STOPPED', provider.stoppedCount.toString(), AppTheme.danger, Icons.stop_circle_outlined, 'stopped', provider),
        _buildStatusCard('OFFLINE', provider.offlineCount.toString(), Colors.grey, Icons.wifi_off_rounded, 'offline', provider),
        _buildStatusCard('NO DATA', provider.noDataCount.toString(), Colors.indigo, Icons.data_usage_rounded, 'no_data', provider),
        _buildStatusCard('TOTAL FLEET', provider.totalCount.toString(), AppTheme.info, Icons.group_rounded, 'total', provider),
      ],
    );
  }

  Widget _buildStatusCard(String label, String value, Color color, IconData icon, String statusKey, TrackingProvider provider) {
    final isActive = provider.statusFilter == statusKey || (statusKey == 'total' && provider.statusFilter == '');
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: InkWell(
          onTap: () => provider.setStatusFilter(statusKey == 'total' ? '' : statusKey),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? color : AppTheme.border, 
                width: isActive ? 2 : 1
              ),
              boxShadow: [
                 BoxShadow(
                   color: color.withValues(alpha: isActive ? 0.1 : 0.05),
                   offset: const Offset(0, 4),
                   blurRadius: 10,
                 ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Icon(icon, size: 16, color: color),
                    ),
                    const SizedBox(width: 10),
                    Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                    if (isActive && statusKey != 'total') ...[
                      const Spacer(),
                      Icon(Icons.filter_alt_rounded, size: 12, color: color),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const Text('units', style: TextStyle(fontSize: 12, color: AppTheme.textBody, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: isActive ? 48 : 32,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection(TrackingProvider provider) {
    LatLng center = _cities[_activeCity] ?? const LatLng(23.8859, 45.0792);

    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Live map — $_activeCity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                _buildTag('GPS sync 1.2s', AppTheme.info),
                const Spacer(),
                _buildCityToggle(),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _activeCity == 'All' ? 5 : 11,
                      onMapReady: _onMapReady,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.walim.tracking',
                        tileProvider: NetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: provider.vehicles.where((v) => v.position != null).map((v) {
                          final p = v.position!;
                          return Marker(
                            point: LatLng(p.lat, p.lng),
                            width: 24, // Increased size for better tap target
                            height: 24,
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedVehicle = v);
                                _mapController.move(LatLng(p.lat, p.lng), 11);
                              },
                              child: Tooltip(
                                message: v.name,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.statusColor(v.status, moving: p.moving, ignition: p.ignition, timestamp: p.timestamp),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _selectedVehicle?.id == v.id ? Colors.black : Colors.white,
                                      width: _selectedVehicle?.id == v.id ? 3 : 2,
                                    ),
                                    boxShadow: _selectedVehicle?.id == v.id 
                                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2)]
                                      : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 24,
                    left: 24,
                    child: _buildMapLegend(provider),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: _buildMapControls(),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: _buildMapScale(),
                  ),
                  // _buildHubMarker('Walim Hub • Olaya', center),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend(TrackingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RIDER STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 12),
          _legendItem('Delivering', Colors.green, provider.movingCount.toString()),
          _legendItem('Idle', Colors.amber, provider.idleCount.toString()),
          _legendItem('Offline', Colors.grey, provider.offlineCount.toString()),
          _legendItem('Alerts', Colors.red, provider.incidents.length.toString()),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textBody))),
          Text(count, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textHeading)),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: AppTheme.softShadow),
      child: Column(
        children: [
          IconButton(
            onPressed: !_mapReady ? null : () {
              _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: !_mapReady ? null : () {
              _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
            },
            icon: const Icon(Icons.remove_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildMapScale() {
    if (!_mapReady) return const SizedBox.shrink();
    final center = _mapController.camera.center;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(4)),
      child: Text(
        '${center.latitude.toStringAsFixed(2)}°N, ${center.longitude.toStringAsFixed(2)}°E • ${_mapController.camera.zoom.toStringAsFixed(1)}z',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)
      ),
    );
  }

  Widget _buildHubMarker(String name, LatLng point) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 24, height: 24, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: AppTheme.softShadow),
            child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildCityToggle() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.sidebarBg, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: _cities.keys.map((city) {
          final active = city == _activeCity;
          return GestureDetector(
            onTap: () {
              setState(() => _activeCity = city);
              _mapController.move(_cities[city]!, city == 'All' ? 5 : 11);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                city,
                style: TextStyle(
                  color: active ? Colors.white : AppTheme.textBody,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRightPanels(TrackingProvider provider) {
    return Column(
      children: [
        _buildRiderDetailPanel(provider),
        const SizedBox(height: 32),
        _buildIncidentQueue(provider),
        const SizedBox(height: 32),
        _buildPlatformPerformance(provider),
      ],
    );
  }

  Widget _buildRiderDetailPanel(TrackingProvider provider) {
    final vehicle = _selectedVehicle ?? (provider.vehicles.isNotEmpty ? provider.vehicles.first : null);
    if (vehicle == null) return const SizedBox.shrink();

    final pos = vehicle.position;
    final isMoving = pos?.moving ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(vehicle.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              _buildTag(isMoving ? 'Moving' : 'Idle', isMoving ? AppTheme.onlineColor : AppTheme.warning),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.sidebarBg,
                child: Text(vehicle.name.substring(0, 1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textBody)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _InfoSmall(label: 'Plate', value: vehicle.fullPlate),
                    _InfoSmall(label: 'Speed', value: '${pos?.speed.toStringAsFixed(0) ?? 0} km/h'),
                    _InfoSmall(label: 'Voltage', value: '${pos?.battery.toStringAsFixed(2) ?? 0} V'),
                    _InfoSmall(label: 'Power', value: '${pos?.power.toStringAsFixed(1) ?? 0} V'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _OutlineIconBtn(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
              const SizedBox(width: 8),
              _OutlineIconBtn(
                icon: Icons.my_location_rounded,
                label: 'Recenter',
                onTap: () => _recenterOnVehicle(vehicle),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
                child: const Text('View full page →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentQueue(TrackingProvider provider) {
    final incidents = provider.incidents;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Incident queue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (incidents.isNotEmpty) _buildTag('${incidents.length} open', AppTheme.danger),
              ],
            ),
          ),
          const Divider(height: 1),
          if (incidents.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Text('No active incidents', style: TextStyle(color: AppTheme.textBody, fontSize: 12))),
          ...incidents.map((inc) => _incidentItem(inc)),
        ],
      ),
    );
  }

  Widget _incidentItem(OperationalIncident inc) {
    return InkWell(
      onTap: () => _showIncidentDetail(inc),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
        child: Row(
          children: [
            Container(width: 3, height: 32, decoration: const BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.vertical(top: Radius.circular(2)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inc.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('${inc.id} • ${inc.riderId} • ${inc.platform}', style: const TextStyle(fontSize: 9, color: AppTheme.textBody), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(inc.time, style: const TextStyle(fontSize: 11, color: AppTheme.textBody, fontWeight: FontWeight.w500)),
            const SizedBox(width: 16),
            _iconAction(Icons.check_rounded, AppTheme.onlineColor, () {
              Provider.of<TrackingProvider>(context, listen: false).resolveIncident(inc.id);
            }),
            const SizedBox(width: 8),
            _iconAction(Icons.close_rounded, AppTheme.danger, () {
               Provider.of<TrackingProvider>(context, listen: false).resolveIncident(inc.id);
            }),
          ],
        ),
      ),
    );
  }

  void _showIncidentDetail(OperationalIncident inc) {
    final provider = Provider.of<TrackingProvider>(context, listen: false);
    final vehicle = provider.vehicles.where((v) => v.id == inc.vehicleId).firstOrNull;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
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
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inc.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textHeading)),
                      Text('Incident ${inc.id} • Report received ${inc.time}', style: const TextStyle(color: AppTheme.textBody, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.sidebarBg),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('AFFECTED ASSET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.sidebarBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Text(inc.riderId.substring(0, 1).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inc.riderId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('Platform: ${inc.platform}', style: const TextStyle(fontSize: 13, color: AppTheme.textBody)),
                      ],
                    ),
                  ),
                  if (vehicle != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('View Live Telemetry', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('RECOMMENDED ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _OutlineIconBtn(
                    icon: Icons.phone_rounded,
                    label: 'Call Rider',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineIconBtn(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'WhatsApp',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      provider.resolveIncident(inc.id);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.onlineColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Resolve Incident', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      provider.resolveIncident(inc.id);
                      Navigator.pop(ctx);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Dismiss Alert', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  Widget _buildPlatformPerformance(TrackingProvider provider) {
    final metrics = provider.platforms;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform performance • today', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          ...metrics.map((m) => _platformRow(m.name, m.count.toString(), 'SLA ${m.sla.toStringAsFixed(1)}%', m.sla > 95 ? AppTheme.onlineColor : AppTheme.warning)),
        ],
      ),
    );
  }

  Widget _platformRow(String name, String count, String sla, Color slaColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
          Text(count, style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
          const SizedBox(width: 12),
          Expanded(child: _buildMiniChart()),
          const SizedBox(width: 12),
          _buildTag(sla, slaColor),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(10, (i) {
        return Container(
          margin: const EdgeInsets.only(left: 2),
          width: 4,
          height: 10 + (i % 3 * 4).toDouble(),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(2)),
        );
      }),
    );
  }

  Widget _buildRidersList(TrackingProvider provider) {
    return _buildListView(
      title: 'Current Riders & Fleet',
      subtitle: '${provider.totalCount} total vehicles detected',
      items: provider.vehicles,
      itemBuilder: (vehicle) => _riderListItem(vehicle),
    );
  }

  Widget _buildIncidentsPage(TrackingProvider provider) {
    return _buildListView(
      title: 'Active Incidents',
      subtitle: '${provider.incidents.length} critical issues and signal losses',
      items: provider.incidents,
      itemBuilder: (inc) => _incidentItem(inc),
    );
  }

  Widget _buildPlatformDeepDive(TrackingProvider provider, String platformName) {
    final filtered = provider.vehicles.where((v) {
       if (platformName == 'Other') {
         return !['Noon', 'Keeta', 'Amazon', 'Jahez', 'Ninja'].any((p) => v.name.toUpperCase().contains(p.toUpperCase()));
       }
       return v.name.toUpperCase().contains(platformName.toUpperCase());
    }).toList();

    return _buildListView(
      title: '$platformName Operations',
      subtitle: '${filtered.length} active units assigned to this platform',
      items: filtered,
      itemBuilder: (vehicle) => _riderListItem(vehicle),
    );
  }
  Widget _buildCityDeepDive(TrackingProvider provider, String cityName) {
    final filtered = provider.vehicles.where((v) {
       if (v.position == null) return false;
       final lat = v.position!.lat;
       final lng = v.position!.lng;
       if (cityName == 'Riyadh') return lat > 24.0 && lat < 25.5 && lng > 46.0 && lng < 47.5;
       if (cityName == 'Jeddah') return lat > 21.0 && lat < 22.0 && lng > 38.8 && lng < 39.6;
       if (cityName == 'Taif') return lat > 20.8 && lat < 21.8 && lng > 40.0 && lng < 41.0;
       return false;
    }).toList();

    return _buildListView(
      title: '$cityName Operations',
      subtitle: '${filtered.length} active units currently in this region',
      items: filtered,
      itemBuilder: (vehicle) => _riderListItem(vehicle),
    );
  }


  Widget _buildListView({required String title, required String subtitle, required List items, required Widget Function(dynamic) itemBuilder}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textBody, fontSize: 13)),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: items.isEmpty 
                ? [const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('No data found matching this view')))]
                : items.map((item) => itemBuilder(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderListItem(Vehicle vehicle) {
    final pos = vehicle.position;
    final initials = vehicle.name.isNotEmpty ? vehicle.name.substring(0, 1).toUpperCase() : '?';
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.border))),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.sidebarBg,
              child: Text(initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textBody)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(vehicle.fullPlate, style: const TextStyle(fontSize: 12, color: AppTheme.textBody)),
                ],
              ),
            ),
            _buildTag(pos?.moving == true ? 'Moving' : 'Idle', pos?.moving == true ? AppTheme.onlineColor : AppTheme.warning),
            const SizedBox(width: 24),
            SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${pos?.speed.toStringAsFixed(0) ?? 0} km/h', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Text('${pos?.battery.toStringAsFixed(2) ?? 0} V', style: const TextStyle(fontSize: 11, color: AppTheme.textBody)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _InfoSmall extends StatelessWidget {
  final String label;
  final String value;
  const _InfoSmall({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textBody, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textHeading)),
      ],
    );
  }
}

class _OutlineIconBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _OutlineIconBtn({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textHeading),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
