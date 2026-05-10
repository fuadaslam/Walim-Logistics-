import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';

enum SearchResultType {
  rider,
  vehicle,
  staff,
  screen,
  asset,
}

class SearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final dynamic data;
  final String? route;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    this.data,
    this.route,
  });
}

class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isSearching;

  SearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isSearching,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;

  SearchNotifier(this._ref) : super(SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query, isSearching: query.isNotEmpty);
    if (query.isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }
    _performSearch(query);
  }

  void _performSearch(String query) {
    final q = query.toLowerCase();
    final results = <SearchResult>[];

    // 1. Search Staff
    final staffAsync = _ref.read(allStaffProvider);
    final currentUserRole = _ref.read(authProvider).profile?.role;

    staffAsync.whenData((staffList) {
      for (final staff in staffList) {
        final role = (staff['role'] ?? '').toString();
        
        // Apply role-based visibility restrictions
        bool isVisibleByRole = true;
        if (currentUserRole == 'Supervisor') {
          isVisibleByRole = role == 'Rider';
        } else if (currentUserRole == 'Operations Manager') {
          isVisibleByRole = role == 'Rider' || role == 'Supervisor';
        }

        if (!isVisibleByRole) continue;

        final name = (staff['full_name'] ?? '').toString();
        final phone = (staff['phone_number'] ?? '').toString();
        final iqama = (staff['iqama_number'] ?? '').toString();
        final id = (staff['id'] ?? '').toString();
        
        if (name.toLowerCase().contains(q) || 
            role.toLowerCase().contains(q) || 
            phone.contains(q) || 
            iqama.contains(q) ||
            id.toLowerCase().contains(q)) {
          results.add(SearchResult(
            title: name,
            subtitle: 'Staff • $role',
            type: SearchResultType.staff,
            data: staff,
          ));
        }
      }
    });

    // 2. Search Vehicles
    try {
      final vehicles = _ref.read(trackingProvider).vehicles;
      for (final v in vehicles) {
        final plate = v.plateNumber.toLowerCase();
        final name = v.name.toLowerCase();
        final make = v.make.toLowerCase();
        final model = v.model.toLowerCase();
        final vin = v.vin.toLowerCase();

        if (plate.contains(q) ||
            name.contains(q) ||
            make.contains(q) ||
            model.contains(q) ||
            vin.contains(q)) {
          results.add(SearchResult(
            title: v.fullPlate,
            subtitle: 'Vehicle • ${v.make.isNotEmpty ? '${v.make} ${v.model}' : v.name}',
            type: SearchResultType.vehicle,
            data: v,
          ));
        }
      }
    } catch (e) {
      // Ignore if trackingProvider is not initialized or fails
    }

    // 3. Static Screens / Navigation
    const screens = [
      {'title': 'Live GPS', 'subtitle': 'Real-time tracking', 'route': 'Live GPS'},
      {'title': 'Live Rider Tracking', 'subtitle': 'Rider positioning', 'route': 'Live Rider'},
      {'title': 'HR Management', 'subtitle': 'Staff and Leaves', 'route': 'HR'},
      {'title': 'Vehicles', 'subtitle': 'Vehicle Registry & Fleet Assets', 'route': 'Vehicles'},
      {'title': 'Asset Registry', 'subtitle': 'Fleet and Equipment', 'route': 'Assets'},
      {'title': 'Finance Hub', 'subtitle': 'Payroll and Invoicing', 'route': 'Finance'},
      {'title': 'Performance Hub', 'subtitle': 'SLA Analytics', 'route': 'Performance'},
      {'title': 'Settings', 'subtitle': 'App Preferences', 'route': 'Settings'},
    ];

    for (final s in screens) {
      if (s['title']!.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: s['title']!,
          subtitle: s['subtitle']!,
          type: SearchResultType.screen,
          route: s['route'],
        ));
      }
    }

    state = state.copyWith(results: results, isSearching: false);
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref);
});
