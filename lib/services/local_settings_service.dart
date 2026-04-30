import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSettingsService {
  static const String _turmaKey = 'selected_turma_id';
  static const String _themeModeKey = 'app_theme_mode';

  Future<String?> getTurmaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_turmaKey);
  }

  Future<void> setTurmaId(String turmaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_turmaKey, turmaId);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeModeKey);

    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, value);
  }
}
