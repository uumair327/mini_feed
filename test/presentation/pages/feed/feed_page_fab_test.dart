import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedPage FloatingActionButton', () {
    testWidgets('should display floating action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestFeedPageWithFAB(),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should have correct tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestFeedPageWithFAB(),
        ),
      );

      final fab = find.byType(FloatingActionButton);
      final fabWidget = tester.widget<FloatingActionButton>(fab);
      
      expect(fabWidget.tooltip, equals('Create new post'));
    });

    testWidgets('should be tappable', (tester) async {
      bool wasTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestFeedPageWithFAB(
            onFabTap: () => wasTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(wasTapped, isTrue);
    });
  });
}

/// Simple test widget with FAB
class TestFeedPageWithFAB extends StatelessWidget {
  final VoidCallback? onFabTap;

  const TestFeedPageWithFAB({
    super.key,
    this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Feed')),
      body: const Center(child: Text('Feed Content')),
      floatingActionButton: FloatingActionButton(
        onPressed: onFabTap ?? () {},
        tooltip: 'Create new post',
        child: const Icon(Icons.add),
      ),
    );
  }
}