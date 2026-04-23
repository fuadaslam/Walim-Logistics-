import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:last_mile_fleet/l10n/app_localizations.dart';
import 'package:last_mile_fleet/core/theme/app_theme.dart';
import 'package:last_mile_fleet/core/localization/locale_provider.dart';
import 'widgets/login_form.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Match the light blue/grey background
      body: Stack(
        children: [
          // Background Decorations (Subtle circles)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextButton.icon(
                      onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
                      icon: const Icon(Icons.language, size: 18, color: AppColors.textSecondary),
                      label: Text(
                        currentLocale.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ),

                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Login Card
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 450),
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Logo
                              Image.asset(
                                'assets/images/logo.png',
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 32),

                              // Headers
                              Text(
                                'Fleet Operations',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Walim Logistics',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Enter your credentials to access the performance dashboard',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary.withOpacity(0.8),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Login Form
                              const LoginForm(),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Footer
                        Text(
                          '© 2024 Walim Logistics • All Rights Reserved',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
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
    );
  }
}
