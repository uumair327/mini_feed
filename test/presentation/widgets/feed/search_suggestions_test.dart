import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/feed/search_suggestions.dart';

void main() {
  group('SearchSuggestions', () {
    testWidgets('should display nothing when no suggestions provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const [],
              popularSearches: const [],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(SearchSuggestions), findsOneWidget);
      expect(find.text('Recent Searches'), findsNothing);
      expect(find.text('Popular Searches'), findsNothing);
    });

    testWidgets('should display recent searches section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter', 'dart'],
              popularSearches: const [],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsAtLeastNWidgets(1));
    });

    testWidgets('should display popular searches section', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const [],
              popularSearches: const ['mobile', 'development'],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Popular Searches'), findsOneWidget);
      expect(find.text('mobile'), findsOneWidget);
      expect(find.text('development'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsAtLeastNWidgets(1));
    });

    testWidgets('should display both sections when both have data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter'],
              popularSearches: const ['mobile'],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('Popular Searches'), findsOneWidget);
      expect(find.text('flutter'), findsOneWidget);
      expect(find.text('mobile'), findsOneWidget);
    });

    testWidgets('should call onSuggestionTap when suggestion is tapped', (tester) async {
      String? tappedSuggestion;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter'],
              popularSearches: const [],
              onSuggestionTap: (suggestion) {
                tappedSuggestion = suggestion;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('flutter'));
      await tester.pump();

      expect(tappedSuggestion, equals('flutter'));
    });

    testWidgets('should display clear history button when onClearHistory provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter'],
              popularSearches: const [],
              onSuggestionTap: (_) {},
              onClearHistory: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.clear_all), findsOneWidget);
      expect(find.byTooltip('Clear search history'), findsOneWidget);
    });

    testWidgets('should call onClearHistory when clear button is tapped', (tester) async {
      bool clearHistoryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter'],
              popularSearches: const [],
              onSuggestionTap: (_) {},
              onClearHistory: () {
                clearHistoryCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.clear_all));
      await tester.pump();

      expect(clearHistoryCalled, isTrue);
    });

    testWidgets('should limit suggestions to 5 items', (tester) async {
      final manySearches = List.generate(10, (index) => 'search$index');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: manySearches,
              popularSearches: const [],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      // Should only show first 5 items
      for (int i = 0; i < 5; i++) {
        expect(find.text('search$i'), findsOneWidget);
      }
      
      // Should not show items beyond 5
      for (int i = 5; i < 10; i++) {
        expect(find.text('search$i'), findsNothing);
      }
    });

    testWidgets('should display north_west icon for suggestions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchSuggestions(
              recentSearches: const ['flutter'],
              popularSearches: const [],
              onSuggestionTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.north_west), findsOneWidget);
    });
  });

  group('SearchHistoryManager', () {
    setUp(() {
      SearchHistoryManager.clearHistory();
    });

    test('should add search query to history', () {
      SearchHistoryManager.addToHistory('flutter');
      
      final history = SearchHistoryManager.getHistory();
      expect(history, contains('flutter'));
      expect(history.first, equals('flutter'));
    });

    test('should not add empty or whitespace-only queries', () {
      SearchHistoryManager.addToHistory('');
      SearchHistoryManager.addToHistory('   ');
      
      final history = SearchHistoryManager.getHistory();
      expect(history, isEmpty);
    });

    test('should trim whitespace from queries', () {
      SearchHistoryManager.addToHistory('  flutter  ');
      
      final history = SearchHistoryManager.getHistory();
      expect(history.first, equals('flutter'));
    });

    test('should remove duplicates and move to front', () {
      SearchHistoryManager.addToHistory('flutter');
      SearchHistoryManager.addToHistory('dart');
      SearchHistoryManager.addToHistory('flutter'); // Duplicate
      
      final history = SearchHistoryManager.getHistory();
      expect(history.length, equals(2));
      expect(history.first, equals('flutter')); // Should be at front
      expect(history.last, equals('dart'));
    });

    test('should limit history to maximum items', () {
      // Add more than max items
      for (int i = 0; i < 15; i++) {
        SearchHistoryManager.addToHistory('search$i');
      }
      
      final history = SearchHistoryManager.getHistory();
      expect(history.length, equals(10)); // Should be limited to max
      expect(history.first, equals('search14')); // Most recent first
    });

    test('should clear history', () {
      SearchHistoryManager.addToHistory('flutter');
      SearchHistoryManager.addToHistory('dart');
      
      SearchHistoryManager.clearHistory();
      
      final history = SearchHistoryManager.getHistory();
      expect(history, isEmpty);
    });

    test('should return popular searches', () {
      final popular = SearchHistoryManager.getPopularSearches();
      
      expect(popular, isNotEmpty);
      expect(popular, contains('flutter'));
      expect(popular, contains('development'));
    });

    test('should return copy of history list', () {
      SearchHistoryManager.addToHistory('flutter');
      
      final history1 = SearchHistoryManager.getHistory();
      final history2 = SearchHistoryManager.getHistory();
      
      // Should be different instances
      expect(identical(history1, history2), isFalse);
      
      // But same content
      expect(history1, equals(history2));
    });
  });
}