import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/feed/search_highlight_text.dart';

void main() {
  group('SearchHighlightText', () {
    testWidgets('should display plain text when search query is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: '',
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should highlight matching text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: 'World',
            ),
          ),
        ),
      );

      // Should find the RichText widget with highlighted content
      expect(find.byType(RichText), findsOneWidget);
      
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Should have multiple spans (before, highlighted, after)
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, greaterThan(1));
    });

    testWidgets('should handle case-insensitive search', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: 'world',
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('should handle multiple matches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World Hello Universe',
              searchQuery: 'Hello',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Should have multiple spans for multiple matches
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, greaterThan(3)); // Multiple Hello matches
    });

    testWidgets('should apply custom styles', (tester) async {
      const customStyle = TextStyle(fontSize: 20, color: Colors.blue);
      const highlightStyle = TextStyle(backgroundColor: Colors.yellow);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: 'World',
              style: customStyle,
              highlightStyle: highlightStyle,
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Check that custom styles are applied
      expect(textSpan.children, isNotNull);
      
      // Find the highlighted span
      final highlightedSpan = textSpan.children!
          .cast<TextSpan>()
          .firstWhere((span) => span.text == 'World');
      
      expect(highlightedSpan.style?.backgroundColor, equals(Colors.yellow));
    });

    testWidgets('should handle maxLines and overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'This is a very long text that should be truncated',
              searchQuery: 'long',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.maxLines, equals(1));
      expect(richText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should handle no matches gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: 'xyz',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Should have only one span with the original text
      expect(textSpan.children, isNotNull);
      expect(textSpan.children!.length, equals(1));
      
      final onlySpan = textSpan.children!.first as TextSpan;
      expect(onlySpan.text, equals('Hello World'));
    });

    testWidgets('should handle empty text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: '',
              searchQuery: 'test',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Should handle empty text gracefully
      expect(textSpan.children, isNotNull);
    });

    testWidgets('should use theme colors when no custom highlight style provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primaryContainer: Colors.blue,
              onPrimaryContainer: Colors.white,
            ),
          ),
          home: const Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchQuery: 'World',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      
      // Find the highlighted span
      final highlightedSpan = textSpan.children!
          .cast<TextSpan>()
          .firstWhere((span) => span.text == 'World');
      
      expect(highlightedSpan.style?.backgroundColor, equals(Colors.blue));
      expect(highlightedSpan.style?.color, equals(Colors.white));
    });
  });
}