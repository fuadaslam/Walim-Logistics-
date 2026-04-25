import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/tracking_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TrackingProvider(),
      child: const WalimTrackingApp(),
    ),
  );
}

class WalimTrackingApp extends StatelessWidget {
  const WalimTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walim Tracking',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
