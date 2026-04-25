import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')); // Default to English

  void toggleLocale() {
    if (state.languageCode == 'en') {
      state = const Locale('ar');
    } else {
      state = const Locale('en');
    }
  }

  void setLocale(Locale locale) {
    state = locale;
  }
}
