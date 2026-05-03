import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';
import 'package:walim_logistics/features/hr/presentation/hr_notifier.dart';

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

    // 1. Search Vehicles / Live Riders
    final tracking = _ref.read(trackingProvider);
    final vehicles = tracking.vehicles;
    for (final v in vehicles) {
      if (v.name.toLowerCase().contains(q) || v.fullPlate.toLowerCase().contains(q)) {
        results.add(SearchResult(
          title: v.name,
          subtitle: 'Vehicle: ${v.fullPlate} • ${v.status.toUpperCase()}',
          type: SearchResultType.rider,
          data: v,
        ));
      }
    }

    // 2. Search Staff
    final staffAsync = _ref.read(allStaffProvider);
    staffAsync.whenData((staffList) {
      for (final staff in staffList) {
        final name = (staff['full_name'] ?? '').toString();
        final role = (staff['role'] ?? '').toString();
        if (name.toLowerCase().contains(q) || role.toLowerCase().contains(q)) {
          results.add(SearchResult(
            title: name,
            subtitle: 'Staff • $role',
            type: SearchResultType.staff,
            data: staff,
          ));
        }
      }
    });

    // 3. Static Screens / Navigation
    const screens = [
      {'title': 'Live GPS', 'subtitle': 'Real-time tracking', 'route': 'Live GPS'},
      {'title': 'Live Rider Tracking', 'subtitle': 'Rider positioning', 'route': 'Live Rider'},
      {'title': 'HR Management', 'subtitle': 'Staff and Leaves', 'route': 'HR'},
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
