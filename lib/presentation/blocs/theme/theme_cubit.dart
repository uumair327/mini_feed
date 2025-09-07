import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

/// Cubit for managing app theme state and persistence
class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeCubit() : super(ThemeMode.system);

  /// Initialize theme from stored preferences
  Future<void> initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTheme = prefs.getString(_themeKey);
      
      if (storedTheme != null) {
        final themeMode = _parseThemeMode(storedTheme);
        Logger.info('Loaded theme from preferences: $themeMode');
        emit(themeMode);
      } else {
        Logger.info('No stored theme found, using system default');
        emit(ThemeMode.system);
      }
    } catch (e) {
      Logger.error('Failed to load theme from preferences', e);
      emit(ThemeMode.system);
    }
  }

  /// Switch to light theme
  Future<void> setLightTheme() async {
    await _updateTheme(ThemeMode.light);
  }

  /// Switch to dark theme
  Future<void> setDarkTheme() async {
    await _updateTheme(ThemeMode.dark);
  }

  /// Switch to system theme (follows device setting)
  Future<void> setSystemTheme() async {
    await _updateTheme(ThemeMode.system);
  }

  /// Toggle between light and dark theme
  /// If currently system, switches to light
  Future<void> toggleTheme() async {
    switch (state) {
      case ThemeMode.light:
        await setDarkTheme();
        break;
      case ThemeMode.dark:
        await setLightTheme();
        break;
      case ThemeMode.system:
        await setLightTheme();
        break;
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode {
    return state == ThemeMode.dark;
  }

  /// Check if current theme is light
  bool get isLightMode {
    return state == ThemeMode.light;
  }

  /// Check if current theme follows system
  bool get isSystemMode {
    return state == ThemeMode.system;
  }

  /// Get theme mode display name
  String get currentThemeName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Update theme and persist to storage
  Future<void> _updateTheme(ThemeMode themeMode) async {
    try {
      Logger.info('Switching theme to: $themeMode');
      
      // Update state
      emit(themeMode);
      
      // Persist to storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeName(themeMode));
      
      Logger.info('Theme updated and saved successfully');
    } catch (e) {
      Logger.error('Failed to update theme', e);
    }
  }

  /// Convert ThemeMode to string for storage
  String _themeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Parse string to ThemeMode
  ThemeMode _parseThemeMode(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }
}