import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/core/theme/theme_provider.dart';
import 'package:walim_logistics/features/tracking/services/tracking_provider.dart';
import 'package:walim_logistics/features/tracking/screens/home_screen.dart' as walim_tracking;
import 'package:walim_logistics/features/dashboard/presentation/admin_dashboard.dart';
import 'package:walim_logistics/features/fleet/presentation/inventory_handover_screen.dart';
import 'package:walim_logistics/features/notifications/presentation/notification_settings_screen.dart';
import 'package:walim_logistics/features/tracking/theme/app_theme.dart' as tracking_theme;
import 'package:walim_logistics/features/dashboard/presentation/hr_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/finance_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/ops_manager_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/supervisor_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/it_dev_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/leader_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/rider_dashboard.dart';
import 'package:walim_logistics/features/dashboard/presentation/biz_dev_dashboard.dart';
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
  });

  @override
  ConsumerState<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends ConsumerState<DashboardScaffold> {
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlayEntry;
  bool _isSearchFocused = false;

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
            color: isDark ? AppColors.surfaceDark.withOpacity(0.95) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
                    separatorBuilder: (v, i) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.3)),
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        leading: _getSearchIcon(item.type),
                        title: Text(item.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.subtitle, style: GoogleFonts.outfit(fontSize: 12)),
                        onTap: () => _handleSearchResultTap(item),
                        hoverColor: AppColors.primary.withOpacity(0.05),
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
      // Handle navigation
      final nav = ref.read(navigationProvider.notifier);
      switch (result.route) {
        case 'Live GPS': nav.setTab(DashboardTab.liveOps); break;
        case 'Live Rider': nav.setTab(DashboardTab.liveRider); break;
        case 'HR': nav.setTab(DashboardTab.hr); break;
        case 'Assets': nav.setTab(DashboardTab.assets); break;
        case 'Finance': nav.setTab(DashboardTab.finance); break;
        case 'Performance': nav.setTab(DashboardTab.attendance); break;
        case 'Settings': 
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

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final navState = ref.watch(navigationProvider);
    final authState = ref.watch(authProvider);
    final isSidebarCollapsed = navState.isSidebarCollapsed;

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
          bottomNavigationBar: !isDesktop && !(widget.showBackButton || widget.onBack != null) 
              ? _buildBottomNavigationBar(context, authState, navState) 
              : null,
          floatingActionButton: widget.floatingActionButton,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, AuthState authState, NavigationState navState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final role = authState.profile?.role ?? 'Rider';
    final navNotifier = ref.read(navigationProvider.notifier);

    // Define items based on role (similar logic to sidebar)
    final items = <_BottomNavItem>[
      _BottomNavItem(
        icon: Icons.dashboard_rounded,
        label: 'Home',
        tab: DashboardTab.dashboard,
        isActive: navState.activeTab == DashboardTab.dashboard,
      ),
    ];

    // 1. Live GPS (High Priority for Ops roles)
    if ((role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager' || role == 'IT_Dev' || role == 'Leader') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.map_rounded,
        label: 'GPS',
        tab: DashboardTab.liveOps,
        isActive: navState.activeTab == DashboardTab.liveOps,
      ));
    }

    // 1.1 Live Rider (High Priority for Ops roles)
    if ((role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager') && items.length < 5) {
      items.add(_BottomNavItem(
        icon: Icons.motorcycle_rounded,
        label: 'Riders',
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
        label: 'Support',
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





    // 5. Assets / Documents (Fill remaining space)
    if (role != 'Rider' && role != 'Business Development' && items.length < 5) {
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
                    onTap: () => navNotifier.setTab(item.tab),
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
    final role = ref.watch(authProvider).profile?.role ?? 'Rider';
    
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
        if (role == 'Admin' || role == 'Operations Manager')
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: QuickAddMenu(),
          ),
        ...?widget.actions,
        IconButton(
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          icon: Icon(Icons.notifications_none_rounded, color: theme.textTheme.bodyLarge?.color, size: 22),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
          },
        ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.95),
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
          _buildSidebarItem(context, Icons.settings_rounded, 'Settings', widget.activeItem == 'Settings', isSidebarCollapsed, onTap: () {
            if (widget.activeItem == 'Settings') return;
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LayoutSettingsScreen()));
          }),
          const Divider(height: 32, indent: 24, endIndent: 24),
          _buildSidebarItem(
            context, 
            Icons.logout_rounded, 
            'Logout', 
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
            color: AppColors.primary.withOpacity(0.3),
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
        color: theme.scaffoldBackgroundColor.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
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
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title.toUpperCase(),
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
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 48),

          // 2. Search Bar
          Expanded(
            child: CompositedTransformTarget(
              link: _searchLayerLink,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
  
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), size: 20),
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
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
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
                      color: theme.dividerColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.keyboard_command_key_rounded, size: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'K',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
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
          
          if (profile?.role == 'Admin' || profile?.role == 'Operations Manager') ...[
            const SizedBox(width: 24),
            const QuickAddMenu(),
          ],

          const SizedBox(width: 40),
          
          // 2. Language Selector
          InkWell(
            onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
              ),

              child: Row(
                children: [
                  const Icon(Icons.language_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    ref.watch(localeProvider).languageCode == 'en' ? 'English' : 'العربية',
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
              _buildHeaderIcon(Icons.notifications_outlined, 'Notifications', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()));
              }),
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
          Container(height: 32, width: 1.5, color: theme.dividerColor.withOpacity(0.5)),
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
            color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            size: 20, 
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
          ),

        ),
      ),
    );
  }

  Widget _buildSidebarItems(BuildContext context, AuthState authState, NavigationState navState, bool isSidebarCollapsed) {
    final role = authState.profile?.role ?? 'Rider';
    final navNotifier = ref.read(navigationProvider.notifier);

    return Column(
      children: [
        _buildSidebarItem(
          context, 
          Icons.dashboard_rounded, 
          'Dashboard', 
          navState.activeTab == DashboardTab.dashboard, 
          isSidebarCollapsed,
          onTap: () => navNotifier.setTab(DashboardTab.dashboard),
        ),
        
        if (role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager' || role == 'IT_Dev' || role == 'Leader')
          _buildSidebarItem(
            context, 
            Icons.map_rounded, 
            'Live GPS', 
            navState.activeTab == DashboardTab.liveOps, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.liveOps),
          ),

        if (role == 'Admin' || role == 'Supervisor' || role == 'Operations Manager')
          _buildSidebarItem(
            context, 
            Icons.motorcycle_rounded, 
            'Live Rider', 
            navState.activeTab == DashboardTab.liveRider, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.liveRider),
          ),

        if (role == 'Admin' || role == 'Operations Manager' || role == 'Supervisor')
          _buildSidebarItem(
            context, 
            Icons.speed_rounded, 
            'Performance', 
            navState.activeTab == DashboardTab.attendance, // Reusing attendance tab for Performance Hub
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.attendance),
          ),

        if (role == 'Admin' || role == 'HR')
          _buildSidebarItem(
            context, 
            Icons.people_rounded, 
            'HR Management', 
            navState.activeTab == DashboardTab.hr, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.hr),
          ),

        if (role != 'Rider' && role != 'Business Development')
          _buildSidebarItem(
            context, 
            Icons.inventory_2_rounded, 
            'Assets', 
            navState.activeTab == DashboardTab.assets, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.assets),
          ),

        if (role == 'Admin' || role == 'Finance Manager')
          _buildSidebarItem(
            context, 
            Icons.payments_rounded, 
            'Finance', 
            navState.activeTab == DashboardTab.finance, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.finance),
          ),

        if (role == 'Rider' || role == 'Leader') ...[
          _buildSidebarItem(
            context, 
            Icons.help_outline, 
            'Support', 
            navState.activeTab == DashboardTab.support, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.support),
          ),
          _buildSidebarItem(
            context, 
            Icons.article_outlined, 
            'Documents', 
            navState.activeTab == DashboardTab.documents, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.documents),
          ),
          _buildSidebarItem(
            context, 
            Icons.history_edu_outlined, 
            'Requests', 
            navState.activeTab == DashboardTab.requests, 
            isSidebarCollapsed,
            onTap: () => navNotifier.setTab(DashboardTab.requests),
          ),
        ],
      ],
    );
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'Admin': return const AdminDashboard();
      case 'HR': return const HRDashboard();
      case 'Finance Manager': return const FinanceDashboard();
      case 'Operations Manager': return const OpsManagerDashboard();
      case 'Supervisor': return const SupervisorDashboard();
      case 'IT_Dev': return const ITDevDashboard();
      case 'Leader': return const LeaderDashboard();
      case 'Rider': return const RiderDashboard();
      case 'Business Development': return const BizDevDashboard();
      default: return const AdminDashboard();
    }
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
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withOpacity(0.1),
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
