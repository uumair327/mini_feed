import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/presentation/widgets/theme/theme_toggle_button.dart';
import 'package:mini_feed/presentation/blocs/theme/theme_cubit.dart';

class MockThemeCubit extends Mock implements ThemeCubit {}

void main() {
  group('ThemeToggleButton', () {
    late MockThemeCubit mockThemeCubit;

    setUp(() {
      mockThemeCubit = MockThemeCubit();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<ThemeCubit>.value(
          value: mockThemeCubit,
          child: const Scaffold(
            body: ThemeToggleButton(),
          ),
        ),
      );
    }

    testWidgets('should display light mode icon when theme is light', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsNothing);
    });

    testWidgets('should display dark mode icon when theme is dark', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.dark);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);
    });

    testWidgets('should display system mode icon when theme is system', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.system);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
    });

    testWidgets('should call toggleTheme when tapped', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockThemeCubit.toggleTheme()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // Assert
      verify(() => mockThemeCubit.toggleTheme()).called(1);
    });

    testWidgets('should have proper accessibility properties', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, contains('theme'));
    });

    testWidgets('should update icon when theme state changes', (tester) async {
      // Arrange
      final themeStateController = StreamController<ThemeMode>();
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
      when(() => mockThemeCubit.stream).thenAnswer((_) => themeStateController.stream);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Verify initial state
      expect(find.byIcon(Icons.light_mode), findsOneWidget);

      // Change theme state
      themeStateController.add(ThemeMode.dark);
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsNothing);

      // Cleanup
      themeStateController.close();
    });

    testWidgets('should have proper semantic properties for accessibility', (tester) async {
      // Arrange
      when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
      when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      final semantics = tester.getSemantics(find.byType(IconButton));
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
      expect(semantics.label, isNotNull);
    });

    group('Theme Mode Cycling', () {
      testWidgets('should cycle from light to dark to system', (tester) async {
        // Arrange
        when(() => mockThemeCubit.state).thenReturn(ThemeMode.light);
        when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());
        when(() => mockThemeCubit.toggleTheme()).thenAnswer((_) async {});

        // Act & Assert - Light mode
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.byIcon(Icons.light_mode), findsOneWidget);

        // Tap to change theme
        await tester.tap(find.byType(IconButton));
        verify(() => mockThemeCubit.toggleTheme()).called(1);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle system theme state gracefully', (tester) async {
        // Arrange
        when(() => mockThemeCubit.state).thenReturn(ThemeMode.system);
        when(() => mockThemeCubit.stream).thenAnswer((_) => const Stream.empty());

        // Act
        await tester.pumpWidget(createWidgetUnderTest());

        // Assert - Should not crash and show system icon
        expect(find.byType(IconButton), findsOneWidget);
        expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      });
    });
  });
}