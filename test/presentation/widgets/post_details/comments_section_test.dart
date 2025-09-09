import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/presentation/widgets/post_details/comments_section.dart';
import 'package:mini_feed/presentation/widgets/common/loading_indicators.dart';

void main() {
  group('CommentsSection', () {
    late List<Comment> testComments;

    setUp(() {
      testComments = [
        Comment(
          id: 1,
          postId: 1,
          name: 'John Doe',
          email: 'john@example.com',
          body: 'This is a test comment with some content.',
        ),
        Comment(
          id: 2,
          postId: 1,
          name: 'Jane Smith',
          email: 'jane@example.com',
          body: 'Another test comment with different content.',
        ),
        Comment(
          id: 3,
          postId: 1,
          name: 'Bob Johnson',
          email: 'bob@example.com',
          body: 'A third comment to test multiple comments display.',
        ),
      ];
    });

    Widget createCommentsSection({
      List<Comment>? comments,
      bool isLoading = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              CommentsSection(
                comments: comments ?? testComments,
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('should display comments header with correct count', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      expect(find.text('Comments (${testComments.length})'), findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets('should display all comments', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      for (final comment in testComments) {
        expect(find.text(comment.name), findsOneWidget);
        expect(find.text(comment.email), findsOneWidget);
        expect(find.text(comment.body), findsOneWidget);
        expect(find.text('#${comment.id}'), findsOneWidget);
      }
    });

    testWidgets('should display loading indicator when loading', (tester) async {
      await tester.pumpWidget(createCommentsSection(
        comments: [],
        isLoading: true,
      ));

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('Comments (0)'), findsOneWidget);
    });

    testWidgets('should display empty state when no comments', (tester) async {
      await tester.pumpWidget(createCommentsSection(
        comments: [],
        isLoading: false,
      ));

      expect(find.byType(EmptyCommentsWidget), findsOneWidget);
      expect(find.text('No Comments Yet'), findsOneWidget);
      expect(find.text('Be the first to share your thoughts on this post.'), findsOneWidget);
    });

    testWidgets('should display comment avatars', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      // Should have one avatar per comment
      expect(find.byIcon(Icons.person), findsNWidgets(testComments.length));
      expect(find.byType(CircleAvatar), findsNWidgets(testComments.length));
    });

    testWidgets('should display comment IDs as badges', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      for (final comment in testComments) {
        expect(find.text('#${comment.id}'), findsOneWidget);
      }
    });

    testWidgets('should allow text selection in comment bodies', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      expect(find.byType(SelectableText), findsNWidgets(testComments.length));
    });

    testWidgets('should handle long comment names with ellipsis', (tester) async {
      final longNameComment = Comment(
        id: 99,
        postId: 1,
        name: 'This is a very long name that should be truncated with ellipsis',
        email: 'long@example.com',
        body: 'Comment body',
      );

      await tester.pumpWidget(createCommentsSection(
        comments: [longNameComment],
      ));

      expect(find.text(longNameComment.name), findsOneWidget);
    });

    testWidgets('should handle long email addresses with ellipsis', (tester) async {
      final longEmailComment = Comment(
        id: 99,
        postId: 1,
        name: 'John Doe',
        email: 'this.is.a.very.long.email.address@example.com',
        body: 'Comment body',
      );

      await tester.pumpWidget(createCommentsSection(
        comments: [longEmailComment],
      ));

      expect(find.text(longEmailComment.email), findsOneWidget);
    });

    testWidgets('should display proper spacing between comments', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      // Should have proper containers for each comment
      expect(find.byType(Container), findsAtLeastNWidgets(testComments.length));
    });

    testWidgets('should use proper theme colors', (tester) async {
      await tester.pumpWidget(createCommentsSection());

      // Should render without theme errors
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyCommentsWidget', () {
    Widget createEmptyCommentsWidget() {
      return const MaterialApp(
        home: Scaffold(
          body: EmptyCommentsWidget(),
        ),
      );
    }

    testWidgets('should display empty state message', (tester) async {
      await tester.pumpWidget(createEmptyCommentsWidget());

      expect(find.text('No Comments Yet'), findsOneWidget);
      expect(find.text('Be the first to share your thoughts on this post.'), findsOneWidget);
    });

    testWidgets('should display comment icon', (tester) async {
      await tester.pumpWidget(createEmptyCommentsWidget());

      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets('should center content properly', (tester) async {
      await tester.pumpWidget(createEmptyCommentsWidget());

      expect(find.byType(Column), findsOneWidget);
      
      final column = tester.widget<Column>(find.byType(Column));
      expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
    });

    testWidgets('should use proper text alignment', (tester) async {
      await tester.pumpWidget(createEmptyCommentsWidget());

      final descriptionText = tester.widget<Text>(
        find.text('Be the first to share your thoughts on this post.'),
      );
      expect(descriptionText.textAlign, equals(TextAlign.center));
    });
  });
}