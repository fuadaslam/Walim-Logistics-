import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:walim_logistics/l10n/app_localizations.dart';
import 'package:walim_logistics/core/constants/constants.dart';
import 'package:walim_logistics/core/theme/app_theme.dart';
import 'package:walim_logistics/core/theme/theme_provider.dart';
import 'package:walim_logistics/core/localization/locale_provider.dart';
import 'package:walim_logistics/features/auth/presentation/auth_gate.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:walim_logistics/core/providers/shared_prefs_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const WalimLogisticsApp(),
    ),
  );
}

class WalimLogisticsApp extends ConsumerWidget {
  const WalimLogisticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Walim Logistics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      locale: currentLocale,
      home: const AuthGate(),
    );
  }
}
