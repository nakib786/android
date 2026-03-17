import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_initialTheme());

  static ThemeMode _initialTheme() {
    final String? theme = prefs.getString('theme_mode');
    if (theme == 'light') return ThemeMode.light;
    if (theme == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    prefs.setString('theme_mode', mode.toString().split('.').last);
  }
}
