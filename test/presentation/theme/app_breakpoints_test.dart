import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/theme/app_breakpoints.dart';

void main() {
  group('AppBreakpoints', () {
    Widget createTestWidget({required double width, required Widget child}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: child,
        ),
      );
    }

    group('screen size detection', () {
      testWidgets('should detect mobile screen size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 400,
            child: Builder(
              builder: (context) {
                expect(AppBreakpoints.isMobile(context), isTrue);
                expect(AppBreakpoints.isTablet(context), isFalse);
                expect(AppBreakpoints.isDesktop(context), isFalse);
                expect(AppBreakpoints.isLargeDesktop(context), isFalse);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should detect tablet screen size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 600,
            child: Builder(
              builder: (context) {
                expect(AppBreakpoints.isMobile(context), isFalse);
                expect(AppBreakpoints.isTablet(context), isTrue);
                expect(AppBreakpoints.isDesktop(context), isFalse);
                expect(AppBreakpoints.isLargeDesktop(context), isFalse);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should detect desktop screen size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1200,
            child: Builder(
              builder: (context) {
                expect(AppBreakpoints.isMobile(context), isFalse);
                expect(AppBreakpoints.isTablet(context), isFalse);
                expect(AppBreakpoints.isDesktop(context), isTrue);
                expect(AppBreakpoints.isLargeDesktop(context), isFalse);
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should detect large desktop screen size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1600,
            child: Builder(
              builder: (context) {
                expect(AppBreakpoints.isMobile(context), isFalse);
                expect(AppBreakpoints.isTablet(context), isFalse);
                expect(AppBreakpoints.isDesktop(context), isTrue);
                expect(AppBreakpoints.isLargeDesktop(context), isTrue);
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('responsive values', () {
      testWidgets('should return mobile value for mobile screen', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 400,
            child: Builder(
              builder: (context) {
                final value = AppBreakpoints.responsive<String>(
                  context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  desktop: 'desktop',
                  largeDesktop: 'largeDesktop',
                );
                expect(value, equals('mobile'));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return tablet value for tablet screen', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 600,
            child: Builder(
              builder: (context) {
                final value = AppBreakpoints.responsive<String>(
                  context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  desktop: 'desktop',
                  largeDesktop: 'largeDesktop',
                );
                expect(value, equals('tablet'));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return desktop value for desktop screen', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1200,
            child: Builder(
              builder: (context) {
                final value = AppBreakpoints.responsive<String>(
                  context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  desktop: 'desktop',
                  largeDesktop: 'largeDesktop',
                );
                expect(value, equals('desktop'));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return large desktop value for large desktop screen', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1600,
            child: Builder(
              builder: (context) {
                final value = AppBreakpoints.responsive<String>(
                  context,
                  mobile: 'mobile',
                  tablet: 'tablet',
                  desktop: 'desktop',
                  largeDesktop: 'largeDesktop',
                );
                expect(value, equals('largeDesktop'));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should fallback to mobile value when optional values are null', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1200,
            child: Builder(
              builder: (context) {
                final value = AppBreakpoints.responsive<String>(
                  context,
                  mobile: 'mobile',
                  // tablet, desktop, largeDesktop are null
                );
                expect(value, equals('mobile'));
                return Container();
              },
            ),
          ),
        );
      });
    });

    group('responsive utilities', () {
      testWidgets('should return correct responsive padding', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 400,
            child: Builder(
              builder: (context) {
                final padding = AppBreakpoints.responsivePadding(context);
                expect(padding.horizontal, equals(32.0)); // 16.0 * 2
                expect(padding.vertical, equals(32.0)); // 16.0 * 2
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct responsive margin', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 600,
            child: Builder(
              builder: (context) {
                final margin = AppBreakpoints.responsiveMargin(context);
                expect(margin.horizontal, equals(24.0)); // 12.0 * 2
                expect(margin.vertical, equals(20.0)); // 10.0 * 2
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct responsive font size', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1200,
            child: Builder(
              builder: (context) {
                final fontSize = AppBreakpoints.responsiveFontSize(context);
                expect(fontSize, equals(1.2));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct max content width', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1600,
            child: Builder(
              builder: (context) {
                final maxWidth = AppBreakpoints.getMaxContentWidth(context);
                expect(maxWidth, equals(1000.0));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct grid columns', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 600,
            child: Builder(
              builder: (context) {
                final columns = AppBreakpoints.getGridColumns(context);
                expect(columns, equals(2));
                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct card elevation', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            width: 1200,
            child: Builder(
              builder: (context) {
                final elevation = AppBreakpoints.getCardElevation(context);
                expect(elevation, equals(3.0));
                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}