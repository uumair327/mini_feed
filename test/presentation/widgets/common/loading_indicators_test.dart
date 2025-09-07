import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/loading_indicators.dart';

void main() {
  group('Loading Indicators', () {
    testWidgets('AppLoadingIndicator should render with default properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('AppLoadingIndicator should render with custom size', (tester) async {
      const customSize = 48.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLoadingIndicator(size: customSize),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(customSize));
      expect(sizedBox.height, equals(customSize));
    });

    testWidgets('CenteredLoadingIndicator should render centered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenteredLoadingIndicator(),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
    });

    testWidgets('CenteredLoadingIndicator should show message when provided', (tester) async {
      const message = 'Loading posts...';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CenteredLoadingIndicator(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('ShimmerText should render with correct dimensions', (tester) async {
      const width = 150.0;
      const height = 20.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerText(
              width: width,
              height: height,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, equals(width));
    });

    testWidgets('ShimmerCircle should render with correct size', (tester) async {
      const size = 60.0;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShimmerCircle(size: size),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, equals(size));
      expect(container.constraints?.maxHeight, equals(size));
    });

    testWidgets('PostShimmerItem should render card structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostShimmerItem(),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(ShimmerText), findsAtLeastNWidgets(1));
      expect(find.byType(ShimmerBox), findsAtLeastNWidgets(1));
    });

    testWidgets('PostShimmerList should render multiple shimmer items', (tester) async {
      const itemCount = 3;
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostShimmerList(itemCount: itemCount),
          ),
        ),
      );

      expect(find.byType(PostShimmerItem), findsNWidgets(itemCount));
    });
  });
}