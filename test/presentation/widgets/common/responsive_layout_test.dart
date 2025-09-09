import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/responsive_layout.dart';
import 'package:mini_feed/presentation/theme/app_breakpoints.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('should display mobile layout on small screens', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(350, 600)); // Mobile size
      
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: mobileWidget,
            tablet: tabletWidget,
            desktop: desktopWidget,
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('should display tablet layout on medium screens', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet size
      
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: mobileWidget,
            tablet: tabletWidget,
            desktop: desktopWidget,
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('should display desktop layout on large screens', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size
      
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');
      const desktopWidget = Text('Desktop Layout');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: mobileWidget,
            tablet: tabletWidget,
            desktop: desktopWidget,
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsOneWidget);
    });

    testWidgets('should fallback to mobile when tablet is null', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet size
      
      const mobileWidget = Text('Mobile Layout');
      const desktopWidget = Text('Desktop Layout');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: mobileWidget,
            desktop: desktopWidget,
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);
    });

    testWidgets('should fallback to tablet when desktop is null', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size
      
      const mobileWidget = Text('Mobile Layout');
      const tabletWidget = Text('Tablet Layout');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: mobileWidget,
            tablet: tabletWidget,
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsOneWidget);
    });

    testWidgets('should use correct breakpoints', (tester) async {
      // Test mobile breakpoint boundary
      await tester.binding.setSurfaceSize(Size(AppBreakpoints.mobile - 1, 600));
      
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);

      // Test tablet breakpoint boundary
      await tester.binding.setSurfaceSize(Size(AppBreakpoints.mobile + 1, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);

      // Test desktop breakpoint boundary
      await tester.binding.setSurfaceSize(Size(AppBreakpoints.desktop + 1, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile'),
            tablet: Text('Tablet'),
            desktop: Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Desktop'), findsOneWidget);
    });

    group('ResponsiveContainer', () {
      testWidgets('should apply max width constraints', (tester) async {
        // Arrange
        await tester.binding.setSurfaceSize(const Size(1200, 800)); // Large screen
        
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveContainer(
              maxWidth: 800,
              child: Text('Constrained content'),
            ),
          ),
        );

        // Assert
        expect(find.text('Constrained content'), findsOneWidget);
        final container = tester.widget<ResponsiveContainer>(find.byType(ResponsiveContainer));
        expect(container.maxWidth, equals(800));
      });

      testWidgets('should center content by default', (tester) async {
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveContainer(
              child: Text('Centered content'),
            ),
          ),
        );

        // Assert
        final container = tester.widget<ResponsiveContainer>(find.byType(ResponsiveContainer));
        expect(container.alignment, equals(Alignment.center));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle very small screens', (tester) async {
        // Arrange
        await tester.binding.setSurfaceSize(const Size(100, 100));
        
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveLayout(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        );

        // Assert
        expect(find.text('Mobile'), findsOneWidget);
      });

      testWidgets('should handle very large screens', (tester) async {
        // Arrange
        await tester.binding.setSurfaceSize(const Size(2000, 1200));
        
        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: ResponsiveLayout(
              mobile: Text('Mobile'),
              tablet: Text('Tablet'),
              desktop: Text('Desktop'),
            ),
          ),
        );

        // Assert
        expect(find.text('Desktop'), findsOneWidget);
      });
    });
  });
}