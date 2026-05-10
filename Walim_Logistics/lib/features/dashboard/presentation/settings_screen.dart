import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/core/theme/theme_provider.dart';
import 'package:walim_logistics/core/localization/locale_provider.dart';
import 'package:walim_logistics/features/auth/presentation/auth_notifier.dart';
import 'package:walim_logistics/features/dashboard/presentation/layout_settings_screen.dart';
import 'package:walim_logistics/features/notifications/presentation/notification_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);
    final role = profile?.role ?? 'Rider';
    final isAdminOrOps = role == 'Admin' || role == 'Operations Manager';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width < 900 ? 16 : 40,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileCard(context, profile),
              const SizedBox(height: 32),
              _buildSectionLabel('Preferences'),
              const SizedBox(height: 12),
              _buildSettingsCard(context, [
                _buildLanguageTile(context, ref, currentLocale),
                _buildDivider(),
                _buildThemeTile(context, ref, themeMode),
              ]),
              const SizedBox(height: 24),
              _buildSectionLabel('Dashboard'),
              const SizedBox(height: 12),
              _buildSettingsCard(context, [
                _buildNavTile(
                  context,
                  icon: Icons.dashboard_customize_rounded,
                  iconColor: Colors.indigo,
                  title: 'Dashboard Layout',
                  subtitle: 'Reorder and toggle dashboard sections',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LayoutSettingsScreen()),
                  ),
                ),
                if (isAdminOrOps) ...[
                  _buildDivider(),
                  _buildNavTile(
                    context,
                    icon: Icons.notifications_active_rounded,
                    iconColor: Colors.green,
                    title: 'WhatsApp Alerts',
                    subtitle: 'Configure automated staff notifications',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 24),
              _buildSectionLabel('Account'),
              const SizedBox(height: 12),
              _buildSettingsCard(context, [
                _buildNavTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: 'App Version',
                  subtitle: '1.0.0 — Phase 1',
                  onTap: null,
                  showChevron: false,
                ),
                _buildDivider(),
                _buildNavTile(
                  context,
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'Sign Out',
                  subtitle: 'You will be returned to the login screen',
                  onTap: () => _confirmSignOut(context, ref),
                  titleColor: AppColors.error,
                  showChevron: false,
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic profile) {
    final name = profile?.fullName ?? 'User';
    final role = profile?.role ?? '';
    final email = profile?.email ?? '';
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: (profile?.avatarUrl == null || profile!.avatarUrl!.isEmpty)
                ? Text(
                    initials,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 64, endIndent: 0, color: AppColors.divider);
  }

  Widget _buildLanguageTile(BuildContext context, WidgetRef ref, Locale currentLocale) {
    const languages = [
      {'code': 'en', 'label': 'English', 'flag': '🇬🇧'},
      {'code': 'ar', 'label': 'العربية', 'flag': '🇸🇦'},
      {'code': 'hi', 'label': 'हिन्दी', 'flag': '🇮🇳'},
    ];
    final current = languages.firstWhere(
      (l) => l['code'] == currentLocale.languageCode,
      orElse: () => languages.first,
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.language_rounded, color: Colors.orange, size: 20),
      ),
      title: Text(
        'Language',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        current['label']!,
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: languages.map((lang) {
          final isSelected = lang['code'] == currentLocale.languageCode;
          return GestureDetector(
            onTap: () => ref.read(localeProvider.notifier).setLocale(Locale(lang['code']!)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                lang['code']!.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, WidgetRef ref, ThemeMode themeMode) {
    final options = [
      {'mode': ThemeMode.light, 'icon': Icons.light_mode_rounded, 'label': 'Light'},
      {'mode': ThemeMode.dark, 'icon': Icons.dark_mode_rounded, 'label': 'Dark'},
      {'mode': ThemeMode.system, 'icon': Icons.brightness_auto_rounded, 'label': 'Auto'},
    ];
    final currentLabel = options
        .firstWhere((o) => o['mode'] == themeMode, orElse: () => options.last)['label'] as String;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: Colors.purple,
          size: 20,
        ),
      ),
      title: Text('Appearance', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      subtitle: Text(
        currentLabel,
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt['mode'] == themeMode;
          return GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).setThemeMode(opt['mode'] as ThemeMode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Icon(
                opt['icon'] as IconData,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNavTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          color: titleColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary)
          : null,
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.outfit(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
