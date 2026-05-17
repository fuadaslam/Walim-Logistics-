import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/core/localization/locale_provider.dart';
import 'widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
              Color(0xFFE2E8F0),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background Decorations (Subtle circles)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            SafeArea(
              child: Stack(
                children: [
                  // Language Switcher (EN)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: PopupMenuButton<String>(
                        tooltip: 'Select Language',
                        onSelected: (String code) {
                          ref.read(localeProvider.notifier).setLocale(Locale(code));
                        },
                        offset: const Offset(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                Text('English', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                                if (currentLocale.languageCode == 'en') ...[
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
                                if (currentLocale.languageCode == 'ar') ...[
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
                                if (currentLocale.languageCode == 'hi') ...[
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
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language_rounded, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                currentLocale.languageCode.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width > 600 ? 24.0 : 16.0,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Login Card
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 450),
                          padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 40 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Logo
                              Image.asset(
                                'assets/images/logo.png',
                                height: MediaQuery.of(context).size.width > 600 ? 80 : 70,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 32),

                              // Headers
                              Text(
                                l10n.fleetOperations.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Walim Logistics',
                                style: GoogleFonts.outfit(
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 32 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.signInPrompt,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Login Form
                              const LoginForm(),

                              const SizedBox(height: 32),

                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${l10n.dontHaveAccount} ",
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Navigate to Sign Up
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      l10n.signUp,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Footer
                        Text(
                          '© 2024 Walim Logistics • All Rights Reserved',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
