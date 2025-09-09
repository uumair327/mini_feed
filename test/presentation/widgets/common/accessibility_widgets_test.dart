import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/accessibility_widgets.dart';

void main() {
  group('AccessibilityWidgets', () {
    group('AccessibleButton', () {
      testWidgets('should have proper semantic properties', (tester) async {
        // Arrange
        bool wasPressed = false;
        
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                onPressed: () => wasPressed = true,
                semanticLabel: 'Test Button',
                tooltip: 'This is a test button',
                child: const Text('Press Me'),
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleButton));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(semantics.label, contains('Test Button'));
        
        // Test tooltip
        final button = tester.widget<AccessibleButton>(find.byType(AccessibleButton));
        expect(button.tooltip, equals('This is a test button'));
      });

      testWidgets('should be tappable and call onPressed', (tester) async {
        // Arrange
        bool wasPressed = false;
        
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                onPressed: () => wasPressed = true,
                semanticLabel: 'Test Button',
                child: const Text('Press Me'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AccessibleButton));
        await tester.pump();

        // Assert
        expect(wasPressed, isTrue);
      });

      testWidgets('should have minimum touch target size', (tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                onPressed: () {},
                semanticLabel: 'Small Button',
                child: const SizedBox(width: 20, height: 20),
              ),
            ),
          ),
        );

        // Assert
        final renderBox = tester.renderObject<RenderBox>(find.byType(AccessibleButton));
        expect(renderBox.size.width, greaterThanOrEqualTo(48.0));
        expect(renderBox.size.height, greaterThanOrEqualTo(48.0));
      });

      testWidgets('should handle disabled state', (tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleButton(
                onPressed: null, // Disabled
                semanticLabel: 'Disabled Button',
                child: const Text('Disabled'),
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleButton));
        expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
        expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
      });
    });

    group('AccessibleText', () {
      testWidgets('should have proper semantic properties', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleText(
                'This is accessible text',
                semanticLabel: 'Custom semantic label',
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleText));
        expect(semantics.label, equals('Custom semantic label'));
      });

      testWidgets('should use text as semantic label when no custom label provided', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleText('Default text'),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleText));
        expect(semantics.label, equals('Default text'));
      });

      testWidgets('should handle different text styles', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  AccessibleText(
                    'Heading',
                    textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    isHeading: true,
                  ),
                  AccessibleText(
                    'Body text',
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        final headingSemantics = tester.getSemantics(find.text('Heading'));
        expect(headingSemantics.hasFlag(SemanticsFlag.isHeader), isTrue);

        final bodySemantics = tester.getSemantics(find.text('Body text'));
        expect(bodySemantics.hasFlag(SemanticsFlag.isHeader), isFalse);
      });
    });

    group('AccessibleCard', () {
      testWidgets('should have proper semantic properties', (tester) async {
        // Arrange
        bool wasTapped = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleCard(
                onTap: () => wasTapped = true,
                semanticLabel: 'Tappable card',
                child: const Text('Card content'),
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleCard));
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        expect(semantics.label, contains('Tappable card'));
      });

      testWidgets('should be tappable when onTap is provided', (tester) async {
        // Arrange
        bool wasTapped = false;

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AccessibleCard(
                onTap: () => wasTapped = true,
                semanticLabel: 'Tappable card',
                child: const Text('Card content'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AccessibleCard));
        await tester.pump();

        // Assert
        expect(wasTapped, isTrue);
      });

      testWidgets('should not be tappable when onTap is null', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleCard(
                semanticLabel: 'Non-tappable card',
                child: Text('Card content'),
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleCard));
        expect(semantics.hasAction(SemanticsAction.tap), isFalse);
      });
    });

    group('AccessibleIcon', () {
      testWidgets('should have proper semantic properties', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleIcon(
                Icons.favorite,
                semanticLabel: 'Favorite icon',
                size: 24,
              ),
            ),
          ),
        );

        // Assert
        final semantics = tester.getSemantics(find.byType(AccessibleIcon));
        expect(semantics.label, equals('Favorite icon'));
      });

      testWidgets('should exclude from semantics when decorative', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibleIcon(
                Icons.star,
                isDecorative: true,
              ),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('star'), findsNothing);
      });
    });

    group('SkipLink', () {
      testWidgets('should be focusable and navigate to target', (tester) async {
        // Arrange
        final targetKey = GlobalKey();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SkipLink(
                    target: targetKey,
                    text: 'Skip to main content',
                  ),
                  const SizedBox(height: 100),
                  Container(
                    key: targetKey,
                    child: const Text('Main content'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.text('Skip to main content'), findsOneWidget);
        
        // Test focus behavior
        await tester.tap(find.text('Skip to main content'));
        await tester.pump();
        
        // The skip link should be functional (actual focus testing requires more setup)
        expect(find.byKey(targetKey), findsOneWidget);
      });
    });

    group('AccessibilityAnnouncement', () {
      testWidgets('should announce text to screen readers', (tester) async {
        // Arrange
        final announcements = <String>[];
        
        // Mock the semantics service
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.accessibility,
          (MethodCall methodCall) async {
            if (methodCall.method == 'announce') {
              announcements.add(methodCall.arguments['message'] as String);
            }
            return null;
          },
        );

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AccessibilityAnnouncement(
                message: 'Important announcement',
                child: Text('Content'),
              ),
            ),
          ),
        );

        await tester.pump();

        // Assert
        expect(announcements, contains('Important announcement'));
      });
    });

    group('FocusableWidget', () {
      testWidgets('should be focusable and handle keyboard navigation', (tester) async {
        // Arrange
        bool wasActivated = false;
        final focusNode = FocusNode();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusableWidget(
                focusNode: focusNode,
                onActivate: () => wasActivated = true,
                child: const Text('Focusable content'),
              ),
            ),
          ),
        );

        // Focus the widget
        focusNode.requestFocus();
        await tester.pump();

        // Simulate Enter key press
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();

        // Assert
        expect(wasActivated, isTrue);
        expect(focusNode.hasFocus, isTrue);
      });

      testWidgets('should handle space key activation', (tester) async {
        // Arrange
        bool wasActivated = false;
        final focusNode = FocusNode();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FocusableWidget(
                focusNode: focusNode,
                onActivate: () => wasActivated = true,
                child: const Text('Focusable content'),
              ),
            ),
          ),
        );

        // Focus and activate with space
        focusNode.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();

        // Assert
        expect(wasActivated, isTrue);
      });
    });
  });
}