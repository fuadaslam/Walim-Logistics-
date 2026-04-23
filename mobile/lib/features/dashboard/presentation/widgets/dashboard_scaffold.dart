import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';

class DashboardScaffold extends ConsumerWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const DashboardScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: !isDesktop ? _buildMobileAppBar(context) : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (isDesktop)
                  SliverToBoxAdapter(
                    child: _buildDesktopHeader(context),
                  ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 20,
                    vertical: isDesktop ? 30 : 20,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ...children,
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 40),
                const SizedBox(width: 16),
                Text(
                  'Logistics',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSidebarItem(context, Icons.dashboard_rounded, 'Dashboard', true),
          _buildSidebarItem(context, Icons.map_rounded, 'Live Map', false),
          _buildSidebarItem(context, Icons.people_rounded, 'Riders', false),
          _buildSidebarItem(context, Icons.inventory_2_rounded, 'Assets', false),
          _buildSidebarItem(context, Icons.payments_rounded, 'Finance', false),
          const Spacer(),
          _buildSidebarItem(context, Icons.settings_rounded, 'Settings', false),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, IconData icon, String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: () {},
      ),
    );
  }

  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: actions ?? [],
          ),
        ],
      ),
    );
  }
}
