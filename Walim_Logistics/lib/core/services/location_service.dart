import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';

final locationServiceProvider = Provider((ref) => LocationService(ref));

class LocationService {
  final Ref _ref;
  StreamSubscription<Position>? _positionSubscription;
  final _supabase = Supabase.instance.client;

  LocationService(this._ref) {
    _ref.onDispose(stopTracking);
  }

  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startTracking() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return;

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _updateLocation(position);
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _updateLocation(Position position) async {
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    try {
      await _supabase.from('profiles').update({
        'last_lat': position.latitude,
        'last_lng': position.longitude,
        'last_location_update': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

}
