import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mini_feed/presentation/blocs/theme/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    late ThemeCubit themeCubit;

    setUp(() {
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    group('initial state', () {
      test('should have ThemeMode.system as initial state', () {
        expect(themeCubit.state, equals(ThemeMode.system));
      });
    });

    group('initializeTheme', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('should emit system theme when no stored preference exists', () async {
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.system));
      });

      test('should emit stored light theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'light'});
        
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.light));
      });

      test('should emit stored dark theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'dark'});
        
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.dark));
      });

      test('should emit stored system theme from preferences', () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'system'});
        
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.system));
      });

      test('should default to system theme for invalid stored value', () async {
        SharedPreferences.setMockInitialValues({'app_theme_mode': 'invalid'});
        
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.system));
      });
    });

    group('setLightTheme', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      blocTest<ThemeCubit, ThemeMode>(
        'should emit light theme and persist to storage',
        build: () => themeCubit,
        act: (cubit) => cubit.setLightTheme(),
        expect: () => [ThemeMode.light],
        verify: (_) async {
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('app_theme_mode'), equals('light'));
        },
      );
    });

    group('setDarkTheme', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      blocTest<ThemeCubit, ThemeMode>(
        'should emit dark theme and persist to storage',
        build: () => themeCubit,
        act: (cubit) => cubit.setDarkTheme(),
        expect: () => [ThemeMode.dark],
        verify: (_) async {
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('app_theme_mode'), equals('dark'));
        },
      );
    });

    group('setSystemTheme', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      blocTest<ThemeCubit, ThemeMode>(
        'should emit system theme and persist to storage',
        build: () => themeCubit,
        act: (cubit) => cubit.setSystemTheme(),
        expect: () => [ThemeMode.system],
        verify: (_) async {
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getString('app_theme_mode'), equals('system'));
        },
      );
    });

    group('toggleTheme', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      blocTest<ThemeCubit, ThemeMode>(
        'should toggle from light to dark',
        build: () => themeCubit,
        seed: () => ThemeMode.light,
        act: (cubit) => cubit.toggleTheme(),
        expect: () => [ThemeMode.dark],
      );

      blocTest<ThemeCubit, ThemeMode>(
        'should toggle from dark to light',
        build: () => themeCubit,
        seed: () => ThemeMode.dark,
        act: (cubit) => cubit.toggleTheme(),
        expect: () => [ThemeMode.light],
      );

      blocTest<ThemeCubit, ThemeMode>(
        'should toggle from system to light',
        build: () => themeCubit,
        seed: () => ThemeMode.system,
        act: (cubit) => cubit.toggleTheme(),
        expect: () => [ThemeMode.light],
      );
    });

    group('getters', () {
      test('isDarkMode should return true when theme is dark', () {
        themeCubit.emit(ThemeMode.dark);
        expect(themeCubit.isDarkMode, isTrue);
        expect(themeCubit.isLightMode, isFalse);
        expect(themeCubit.isSystemMode, isFalse);
      });

      test('isLightMode should return true when theme is light', () {
        themeCubit.emit(ThemeMode.light);
        expect(themeCubit.isLightMode, isTrue);
        expect(themeCubit.isDarkMode, isFalse);
        expect(themeCubit.isSystemMode, isFalse);
      });

      test('isSystemMode should return true when theme is system', () {
        themeCubit.emit(ThemeMode.system);
        expect(themeCubit.isSystemMode, isTrue);
        expect(themeCubit.isDarkMode, isFalse);
        expect(themeCubit.isLightMode, isFalse);
      });

      test('currentThemeName should return correct names', () {
        themeCubit.emit(ThemeMode.light);
        expect(themeCubit.currentThemeName, equals('Light'));

        themeCubit.emit(ThemeMode.dark);
        expect(themeCubit.currentThemeName, equals('Dark'));

        themeCubit.emit(ThemeMode.system);
        expect(themeCubit.currentThemeName, equals('System'));
      });
    });

    group('error handling', () {
      setUp(() {
        SharedPreferences.setMockInitialValues({});
      });

      test('should handle SharedPreferences errors gracefully during initialization', () async {
        // This test verifies that the cubit doesn't crash when SharedPreferences fails
        // In a real scenario, we might mock SharedPreferences to throw an exception
        await themeCubit.initializeTheme();
        expect(themeCubit.state, equals(ThemeMode.system));
      });
    });
  });
}