import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/core/theme/theme_provider.dart';
import 'package:walim_logistics/features/notifications/presentation/notifications_notifier.dart';
import 'package:walim_logistics/features/notifications/presentation/notifications_screen.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/navigation_provider.dart';
import 'package:walim_logistics/features/hr/presentation/rider_detail_screen.dart';
import 'package:walim_logistics/core/localization/locale_provider.dart';
import 'package:walim_logistics/features/dashboard/presentation/layout_settings_screen.dart';
import 'package:flutter/services.dart';
import 'package:walim_logistics/features/dashboard/presentation/providers/search_provider.dart';
import 'package:walim_logistics/shared/widgets/quick_add_menu.dart';
import 'package:walim_logistics/features/tracking/screens/vehicle_detail_screen.dart';
import 'package:walim_logistics/shared/models/profile.dart';
import 'package:walim_logistics/features/tracking/models/vehicle.dart';

class DashboardScaffold extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;
  final bool showBackButton;
  final String activeItem;
  final Widget? endDrawer;
  final Widget? body;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final List<Widget>? headerActions;
  final bool? showBottomNavigationBar;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    this.children = const [],
    this.actions,
    this.floatingActionButton,
    this.onBack,
    this.showBackButton = false,
    this.activeItem = 'Dashboard',
    this.endDrawer,
    this.body,
    this.onSearchChanged,
    this.searchHint,
    this.headerActions,
    this.showBottomNavigationBar,
  });

  @override
  ConsumerState<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends ConsumerState<DashboardScaffold> {
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;
  bool _isSearchFocused = false;
  bool? _isStaffsExpanded;

  bool get _staffsExpanded {
    if (_isStaffsExpanded != null) return _isStaffsExpanded!;
    return widget.activeItem == 'Riders' || 
           widget.activeItem == 'Supervisors';
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _removeSearchOverlay();
    super.dispose();
  }

  void _onSearchFocusChange() {
    setState(() {
      _isSearchFocused = _searchFocusNode.hasFocus;
    });
    if (_isSearchFocused) {
      _showSearchOverlay();
    } else {
      // Delay removal to allow tapping results
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_searchFocusNode.hasFocus) {
          _removeSearchOverlay();
        }
      });
    }
  }

  void _showSearchOverlay() {
    _removeSearchOverlay();
    if (widget.onSearchChanged != null) return; // Don't show global overlay if specific handler exists

    final overlay = Overlay.of(context);
    _searchOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 600, // Matching search bar max width
        child: CompositedTransformFollower(
          link: _searchLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 52),
          child: Material(
            color: Colors.transparent,
            child: _buildSearchResultsOverlay(),
          ),
        ),
      ),
    );
    overlay.insert(_searchOverlayEntry!);
  }

  void _removeSearchOverlay() {
    _searchOverlayEntry?.remove();
    _searchOverlayEntry = null;
  }

  Widget _buildSearchResultsOverlay() {
    return Consumer(
      builder: (context, ref, child) {
        final searchState = ref.watch(searchProvider);
        final results = searchState.results;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (results.isEmpty && searchState.query.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: results.isEmpty 
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          'No results found for "${searchState.query}"',
                          style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: results.length,
                    separatorBuilder: (v, i) => Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        leading: _getSearchIcon(item.type),
                        title: Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.subtitle, style: GoogleFonts.outfit(fontSize: 12)),
                        onTap: () => _handleSearchResultTap(item),
                        hoverColor: AppColors.primary.withValues(alpha: 0.05),
                      );
                    },
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _getSearchIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.rider: return const Icon(Icons.motorcycle_rounded, color: Colors.blue);
      case SearchResultType.staff: return const Icon(Icons.people_rounded, color: Colors.teal);
      case SearchResultType.screen: return const Icon(Icons.launch_rounded, color: Colors.orange);
      case SearchResultType.vehicle: return const Icon(Icons.local_shipping_rounded, color: Colors.indigo);
      default: return const Icon(Icons.search_rounded);
    }
  }

  void _handleSearchResultTap(SearchResult result) {
    _searchFocusNode.unfocus();
    _removeSearchOverlay();
    
    if (result.type == SearchResultType.screen && result.route != null) {
      final role = ref.read(authProvider).profile?.role ?? 'Rider';
      // Handle navigation
      switch (result.route) {
        case 'Live GPS': _navigateToTab(DashboardTab.liveOps); break;
        case 'Live Rider': 
          if (role == 'Admin') {
            _navigateToTab(DashboardTab.liveRider);
          }
          break;
        case 'HR': _navigateToTab(DashboardTab.hr); break;
        case 'Vehicles': _navigateToTab(DashboardTab.vehicles); break;
        case 'Assets': _navigateToTab(DashboardTab.assets); break;
        case 'Finance': _navigateToTab(DashboardTab.finance); break;
        case 'Performance': _navigateToTab(DashboardTab.attendance); break;
        case 'Settings': 
          if (Navigator.canPop(context)) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LayoutSettingsScreen()));
          break;
      }
    } else if (result.type == SearchResultType.staff || result.type == SearchResultType.rider) {
      if (result.data != null) {
        final profile = UserProfile.fromJson(result.data as Map<String, dynamic>);
        Navigator.push(context, MaterialPageRoute(builder: (_) => RiderDetailScreen(profile: profile)));
      }
    } else if (result.type == SearchResultType.vehicle) {
      if (result.data is Vehicle) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: result.data as Vehicle)));
      }
    }
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).signOut();
    }
  }

  void _navigateToTab(DashboardTab tab) {
    ref.read(navigationProvider.notifier).setTab(tab);
    if (Navigator.canPop(context)) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final navState = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final isSidebarCollapsed = navState.isSidebarCollapsed;

    final showBottomNav = !isDesktop && (widget.showBottomNavigationBar ?? !(widget.showBackButton || widget.onBack != null));

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): const _SearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): const _SearchIntent(),
      },
      child: Actions(
        actions: {
          _SearchIntent: CallbackAction<_SearchIntent>(
            onInvoke: (intent) {
              _searchFocusNode.requestFocus();
              return null;
            },
          ),
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: !isDesktop ? _buildMobileAppBar(context) : null,
          drawer: !isDesktop ? Drawer(child: _buildSidebar(context, isSidebarCollapsed, authState, navState)) : null,
          endDrawer: widget.endDrawer,
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(context, isSidebarCollapsed, authState, navState),
              Expanded(
                child: Column(
                  children: [
                    if (isDesktop) _buildDesktopHeaderWidget(context, isSidebarCollapsed),
                    Expanded(
                      child: widget.body != null 
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 10 : 20,
                              vertical: 20,
                            ),
                            child: widget.body!,
                          )
                        : CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 10 : 20,
                              vertical: 20,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                ...widget.children,
                                const SizedBox(height: 40),
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: showBottomNav
              ? _buildBottomNavigationBar(context, authState, navState) 
              : null,
          floatingActionButton: widget.floatingActionButton ?? 
              ((authState.profile?.role == 'Admin' || authState.profile?.role == 'Operations Manager') 
                ? Padding(
                    padding: EdgeInsets.only(bottom: isDesktop ? 75.0 : 0.0),
                    child: const QuickAddMenu(),
                  ) 
                : null),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, AuthState authState, NavigationState navState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final role = authState.profile?.role ?? 'Rider';
    final l10n = AppLocalizations.of(context)!;

    // Define items based on role (similar logic to sidebar)
    final items = <_BottomNavItem>[
      _BottomNavItem(
        icon: Icons.dashboard_rounded,
        label: l10n.home,
        tab: DashboardTab.dashboard,
        isActive: navState.activeTab == DashboardTab.dashboard,
      ),
    ];

    // 1. Live GPS (High Priority for Ops roles)
    if ((role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager' || role == 'IT_Dev' || role == 'Leader') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.map_rounded,
        label: l10n.gps,
        tab: DashboardTab.liveOps,
        isActive: navState.activeTab == DashboardTab.liveOps,
      ));
    }

    // 1.1 Live Rider (High Priority for Ops roles)
    if (role == 'Admin' && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.motorcycle_rounded,
        label: l10n.riders,
        tab: DashboardTab.liveRider,
        isActive: navState.activeTab == DashboardTab.liveRider,
      ));
    }

    // 2. Inspections removed (not required)





    // 3. HR / Support
    if ((role == 'Admin' || role == 'HR') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.people_rounded,
        label: 'HR',
        tab: DashboardTab.hr,
        isActive: navState.activeTab == DashboardTab.hr,
      ));
    } else if ((role == 'Rider' || role == 'Leader') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.contact_support_rounded,
        label: l10n.support,
        tab: DashboardTab.support,
        isActive: navState.activeTab == DashboardTab.support,
      ));
    }


    // 4. Assets / Finance / Requests
    if ((role == 'Admin' || role == 'Finance Manager') && items.length < 5) {
       items.add(_BottomNavItem(
        icon: Icons.payments_rounded,
        label: 'Finance',
        tab: DashboardTab.finance,
        isActive: navState.activeTab == DashboardTab.finance,
      ));
    } else if ((role == 'Rider' || role == 'Leader') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.history_edu_rounded,
        label: 'Requests',
        tab: DashboardTab.requests,
        isActive: navState.activeTab == DashboardTab.requests,
      ));
    }

    if ((role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.assessment_rounded,
        label: 'Reports',
        tab: DashboardTab.reports,
        isActive: navState.activeTab == DashboardTab.reports,
      ));
    }





    // 5. Vehicles / Assets / Documents (Fill remaining space)
    if ((role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.directions_car_rounded,
        label: 'Vehicles',
        tab: DashboardTab.vehicles,
        isActive: navState.activeTab == DashboardTab.vehicles,
      ));
      if (items.length < 5) {
        items.add(_BottomNavItem(
          icon: Icons.inventory_2_rounded,
          label: 'Assets',
          tab: DashboardTab.assets,
          isActive: navState.activeTab == DashboardTab.assets,
        ));
      }
    } else if (role != 'Rider' && role != 'Business Development' && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.inventory_2_rounded,
        label: 'Assets',
        tab: DashboardTab.assets,
        isActive: navState.activeTab == DashboardTab.assets,
      ));
    } else if ((role == 'Rider' || role == 'Leader') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.description_rounded,
        label: 'Docs',
        tab: DashboardTab.documents,
        isActive: navState.activeTab == DashboardTab.documents,
      ));
    }




    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: isDark ? 0.8 : 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                return Expanded(
                  child: InkWell(
                    onTap: () => _navigateToTab(item.tab),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.elasticOut,
                          padding: EdgeInsets.symmetric(
                            horizontal: item.isActive ? 20 : 12, 
                            vertical: 8
                          ),
                          decoration: BoxDecoration(
                            color: item.isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.isActive 
                                ? AppColors.primary 
                                : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.35)),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (!item.isActive)
                          Text(
                            item.label,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.35),
                              letterSpacing: 0.2,
                            ),
                          )
                        else
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: theme.cardColor.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      automaticallyImplyLeading: false,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/images/logo.png', height: 16),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              widget.title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
      leading: widget.showBackButton || widget.onBack != null
          ? IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.textTheme.bodyLarge?.color),
              onPressed: widget.onBack ?? () => Navigator.pop(context),
            )
          : null,
      actions: [
        ...?widget.actions,
        _buildNotificationBell(context),
        IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            color: theme.textTheme.bodyLarge?.color,
            size: 22,
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        _buildUserAvatar(context),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, bool isSidebarCollapsed, AuthState authState, NavigationState navState) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 30,
            offset: const Offset(4, 0),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: isSidebarCollapsed 
                ? const EdgeInsets.symmetric(vertical: 32) 
                : const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: Row(
              mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                if (!isSidebarCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Walim Logistics',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          color: AppColors.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: _buildSidebarItems(context, authState, navState, isSidebarCollapsed),
            ),
          ),
          _buildSidebarItem(context, Icons.settings_rounded, l10n.settings, widget.activeItem == 'Settings', isSidebarCollapsed, onTap: () {
            if (widget.activeItem == 'Settings') return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LayoutSettingsScreen()));
          }),
          const Divider(height: 32, indent: 24, endIndent: 24),
          _buildSidebarItem(
            context, 
            Icons.logout_rounded, 
            l10n.logout, 
            false, 
            isSidebarCollapsed,
            onTap: _handleLogout,
            color: AppColors.error,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label, bool isActive, bool isSidebarCollapsed, {VoidCallback? onTap, Color? color}) {
    final itemColor = color ?? (isActive ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color);
    final titleColor = color ?? (isActive ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),

      child: ListTile(
        minLeadingWidth: isSidebarCollapsed ? 0 : null,
        contentPadding: EdgeInsets.symmetric(horizontal: isSidebarCollapsed ? 12 : 16, vertical: 4),
        leading: Icon(
          icon,
          color: itemColor,
          size: 22,
        ),
        title: isSidebarCollapsed ? null : Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: titleColor,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDesktopHeaderWidget(BuildContext context, bool isSidebarCollapsed) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(

        children: [
          // 0. Back Button for Desktop Detail Screens
          if (widget.showBackButton || widget.onBack != null) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: theme.textTheme.bodyLarge?.color),
              onPressed: widget.onBack ?? () => Navigator.pop(context),
            ),
            const SizedBox(width: 16),
          ],

          // 1. Title & Subtitle
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.titleLarge?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                if (widget.subtitle.isNotEmpty)
                  Text(
                    widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // 2. Search Bar
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 500),
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
  
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        focusNode: _searchFocusNode,
                        onChanged: (v) {
                          if (widget.onSearchChanged != null) {
                            widget.onSearchChanged!(v);
                          } else {
                            ref.read(searchProvider.notifier).setQuery(v);
                          }
                        },
                        style: GoogleFonts.outfit(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: widget.searchHint ?? 'Search inventory, staff or screens (Cmd+K)',
                          hintStyle: GoogleFonts.outfit(
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
  
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_command_key_rounded, size: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'K',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
          if (widget.headerActions != null) ...[
            const SizedBox(width: 24),
            ...widget.headerActions!,
          ],
          
          const SizedBox(width: 40),
          
          // 2. Language Selector
          PopupMenuButton<String>(
            tooltip: 'Select Language',
            onSelected: (String code) {
              ref.read(localeProvider.notifier).setLocale(Locale(code));
            },
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    Text('English', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                    if (ref.read(localeProvider).languageCode == 'en') ...[
                      const Spacer(),
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'ar',
                child: Row(
                  children: [
                    Text('العربية', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                    if (ref.read(localeProvider).languageCode == 'ar') ...[
                      const Spacer(),
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Row(
                  children: [
                    Text('हिन्दी', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                    if (ref.read(localeProvider).languageCode == 'hi') ...[
                      const Spacer(),
                      const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    ref.watch(localeProvider).languageCode == 'en' 
                        ? 'English' 
                        : ref.watch(localeProvider).languageCode == 'ar' 
                            ? 'العربية' 
                            : 'हिन्दी',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),

          // 3. Icons
          Row(
            children: [
              _buildNotificationBellDesktop(context),
              const SizedBox(width: 8),
              _buildHeaderIcon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, 
                'Toggle Theme', 
                () => ref.read(themeProvider.notifier).toggleTheme()
              ),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.settings_outlined, 'Settings', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LayoutSettingsScreen()));
              }),
            ],
          ),
          
          const SizedBox(width: 24),
          Container(height: 32, width: 1.5, color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(width: 24),


          // 4. User Info
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                profile?.fullName ?? 'User',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                profile?.role ?? 'Role',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          _buildUserAvatar(context),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, String tooltip, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            size: 20, 
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
          ),

        ),
      ),
    );
  }

  Widget _buildExpandableStaffsItem(BuildContext context, AuthState authState, NavigationState navState, bool isSidebarCollapsed) {
    final theme = Theme.of(context);
    final isExpanded = _staffsExpanded;
    final isAnySubActive = widget.activeItem == 'Riders' || 
                           widget.activeItem == 'Supervisors';

    final role = authState.profile?.role ?? 'Rider';

    if (isSidebarCollapsed) {
      return Theme(
        data: theme.copyWith(cardColor: theme.cardColor),
        child: PopupMenuButton<DashboardTab>(
          tooltip: 'Staffs',
          offset: const Offset(70, 0),
          onSelected: (tab) => _navigateToTab(tab),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: DashboardTab.riders,
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, size: 18),
                  SizedBox(width: 12),
                  Text('Riders'),
                ],
              ),
            ),
            if (role != 'Supervisor')
              const PopupMenuItem(
                value: DashboardTab.supervisors,
                child: Row(
                  children: [
                    Icon(Icons.supervisor_account_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('Supervisors'),
                  ],
                ),
              ),
          ],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isAnySubActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.people_rounded,
              color: isAnySubActive ? AppColors.primary : theme.textTheme.bodyMedium?.color,
              size: 22,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isStaffsExpanded = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAnySubActive && !isExpanded ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  color: isAnySubActive ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Staffs',
                    style: GoogleFonts.outfit(
                      fontWeight: isAnySubActive ? FontWeight.bold : FontWeight.w500,
                      color: isAnySubActive ? (theme.brightness == Brightness.dark ? Colors.white : AppColors.textPrimary) : theme.textTheme.bodyLarge?.color,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                  color: isAnySubActive ? AppColors.primary : theme.textTheme.bodyMedium?.color,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    children: [
                      _buildSidebarItem(
                        context,
                        Icons.people_outline_rounded,
                        'Riders',
                        widget.activeItem == 'Riders',
                        isSidebarCollapsed,
                        onTap: () => _navigateToTab(DashboardTab.riders),
                      ),
                      if (role != 'Supervisor')
                        _buildSidebarItem(
                          context,
                          Icons.supervisor_account_rounded,
                          'Supervisors',
                          widget.activeItem == 'Supervisors',
                          isSidebarCollapsed,
                          onTap: () => _navigateToTab(DashboardTab.supervisors),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSidebarItems(BuildContext context, AuthState authState, NavigationState navState, bool isSidebarCollapsed) {
    final role = authState.profile?.role ?? 'Rider';
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _buildSidebarItem(
          context, 
          Icons.dashboard_rounded, 
          l10n.dashboard, 
          widget.activeItem == 'Dashboard', 
          isSidebarCollapsed,
          onTap: () => _navigateToTab(DashboardTab.dashboard),
        ),
        
        if (role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager' || role == 'IT_Dev' || role == 'Leader')
          _buildSidebarItem(
            context, 
            Icons.map_rounded, 
            l10n.liveGPS, 
            widget.activeItem == 'Live GPS', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.liveOps),
          ),

        if (role == 'Admin')
          _buildSidebarItem(
            context, 
            Icons.motorcycle_rounded, 
            l10n.liveRiderTracking, 
            widget.activeItem == 'Live Rider', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.liveRider),
          ),

        if (role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor')
          _buildSidebarItem(
            context, 
            Icons.speed_rounded, 
            l10n.performance, 
            widget.activeItem == 'Performance', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.attendance),
          ),

        if (role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor')
          _buildSidebarItem(
            context, 
            Icons.assessment_rounded, 
            'Reports', 
            widget.activeItem == 'Reports', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.reports),
          ),

        if (role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor') ...[
          _buildExpandableStaffsItem(context, authState, navState, isSidebarCollapsed),
          _buildSidebarItem(
            context, 
            Icons.business_rounded, 
            'Platforms', 
            widget.activeItem == 'Platforms', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.platforms),
          ),
        ],

        if (role == 'Admin' || role == 'HR')
          _buildSidebarItem(
            context, 
            Icons.badge_rounded, 
            l10n.hrManagement, 
            widget.activeItem == 'HR', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.hr),
          ),

        if (role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor') ...[
          _buildSidebarItem(
            context,
            Icons.directions_car_rounded,
            'Vehicles',
            widget.activeItem == 'Vehicles',
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.vehicles),
          ),
          _buildSidebarItem(
            context,
            Icons.inventory_2_rounded,
            'Assets',
            widget.activeItem == 'Assets',
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.assets),
          ),
        ],

        if (role != 'Rider' && role != 'Business Development' && role != 'Admin' && role != 'Operations Manager' && role != 'Supervisor')
          _buildSidebarItem(
            context,
            Icons.inventory_2_rounded,
            l10n.assetManagement,
            widget.activeItem == 'Assets',
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.assets),
          ),

        if (role == 'Admin' || role == 'Finance Manager')
          _buildSidebarItem(
            context, 
            Icons.payments_rounded, 
            l10n.financialManagement, 
            widget.activeItem == 'Finance', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.finance),
          ),

        if (role == 'Rider' || role == 'Leader') ...[
          _buildSidebarItem(
            context, 
            Icons.help_outline, 
            l10n.support, 
            widget.activeItem == 'Support', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.support),
          ),
          _buildSidebarItem(
            context, 
            Icons.article_outlined, 
            l10n.documentVault, 
            widget.activeItem == 'Documents', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.documents),
          ),
          _buildSidebarItem(
            context, 
            Icons.history_edu_outlined, 
            l10n.myRequests, 
            widget.activeItem == 'Requests', 
            isSidebarCollapsed,
            onTap: () => _navigateToTab(DashboardTab.requests),
          ),
        ],
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final initials = profile?.fullName
            .split(' ')
            .where((e) => e.isNotEmpty)
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase() ??
        'U';

    return InkWell(
      onTap: () {
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != '/rider_detail') {
          Navigator.push(
            context, 
            MaterialPageRoute(
              settings: const RouteSettings(name: '/rider_detail'),
              builder: (_) => RiderDetailScreen(profile: profile),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: Text(
            initials,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    final unread = ref.watch(unreadNotificationCountProvider);
    final theme = Theme.of(context);
    return Stack(
      children: [
        IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          icon: Icon(
            unread > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: theme.textTheme.bodyLarge?.color,
            size: 22,
          ),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration:
                  const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationBellDesktop(BuildContext context) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return Stack(
      children: [
        _buildHeaderIcon(
          unread > 0
              ? Icons.notifications_rounded
              : Icons.notifications_outlined,
          'Notifications',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        ),
        if (unread > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration:
                  const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints:
                  const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _BottomNavItem {
  final IconData icon;
  final String label;
  final DashboardTab tab;
  final bool isActive;

  _BottomNavItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.isActive,
  });
}

class _SearchIntent extends Intent {
  const _SearchIntent();
}
