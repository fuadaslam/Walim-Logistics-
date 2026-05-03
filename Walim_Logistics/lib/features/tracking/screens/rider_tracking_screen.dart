import 'package:flutter/material.dart';
import 'package:walim_logistics/features/dashboard/presentation/widgets/dashboard_scaffold.dart';
import 'package:walim_logistics/features/tracking/presentation/widgets/live_rider_map.dart';

class RiderTrackingScreen extends StatelessWidget {
  const RiderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardScaffold(
      title: 'LIVE RIDER TRACKING',
      subtitle: 'Real-time location monitoring for all active riders',
      showBackButton: true,
      body: LiveRiderMap(),
    );
  }
}
