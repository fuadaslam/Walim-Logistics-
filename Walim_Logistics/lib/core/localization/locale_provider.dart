import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walim_logistics/core/providers/shared_prefs_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const _localeKey = 'language_code';

  LocaleNotifier(this._prefs) : super(const Locale('en')) {
    _loadLocale();
  }

  void _loadLocale() {
    final languageCode = _prefs.getString(_localeKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> toggleLocale() async {
    if (state.languageCode == 'en') {
      await setLocale(const Locale('ar'));
    } else if (state.languageCode == 'ar') {
      await setLocale(const Locale('hi'));
    } else {
      await setLocale(const Locale('en'));
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_localeKey, locale.languageCode);
  }
}
