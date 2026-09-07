import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and emits the user's preferred [ThemeMode].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_read(_prefs));

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_key, value);
    emit(mode);
  }
}
