import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';
import 'package:mini_feed/presentation/pages/feed/feed_page.dart';
import 'package:mini_feed/presentation/widgets/common/empty_state_widgets.dart';

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  void add(event) {}
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isClosed => false;
}

class MockFeedBloc extends Mock implements FeedBloc {
  @override
  FeedState get state => const FeedInitial();
  
  @override
  Stream<FeedState> get stream => Stream.value(const FeedInitial());
  
  @override
  void add(event) {}
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isClosed => false;
}

void main() {
  group('FeedPage', () {
    late MockAuthBloc mockAuthBloc;
    late MockFeedBloc mockFeedBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      mockFeedBloc = MockFeedBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(create: (_) => mockAuthBloc),
            BlocProvider<FeedBloc>(create: (_) => mockFeedBloc),
          ],
          child: const FeedPage(),
        ),
      );
    }

    testWidgets('should display app bar with title and actions', (tester) async {
      when(() => mockFeedBloc.state).thenReturn(const FeedInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Mini Feed'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byType(PopupMenuButton), findsOneWidget);
    });

    testWidgets('should display loading indicator when feed is loading', (tester) async {
      when(() => mockFeedBloc.state).thenReturn(const FeedLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Loading posts...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no posts', (tester) async {
      when(() => mockFeedBloc.state).thenReturn(
        const FeedLoaded(posts: [], hasReachedMax: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(EmptyPostsWidget), findsOneWidget);
    });

    testWidgets('should display posts when loaded', (tester) async {
      final testPosts = [
        Post(
          id: 1,
          title: 'Test Post 1',
          body: 'This is a test post',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Post(
          id: 2,
          title: 'Test Post 2',
          body: 'This is another test post',
          userId: 2,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(() => mockFeedBloc.state).thenReturn(
        FeedLoaded(posts: testPosts, hasReachedMax: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(PostListItem), findsNWidgets(2));
      expect(find.text('Test Post 1'), findsOneWidget);
      expect(find.text('Test Post 2'), findsOneWidget);
    });

    testWidgets('should display error widget when feed fails to load', (tester) async {
      when(() => mockFeedBloc.state).thenReturn(
        const FeedError(message: 'Failed to load posts'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Failed to load posts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display floating action button on mobile', (tester) async {
      when(() => mockFeedBloc.state).thenReturn(const FeedInitial());

      // Set mobile screen size
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Reset screen size
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });

  group('PostListItem', () {
    late Post testPost;

    setUp(() {
      testPost = Post(
        id: 1,
        title: 'Test Post',
        body: 'This is a test post body',
        userId: 1,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );
    });

    Widget createPostListItem({
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PostListItem(
            post: testPost,
            onTap: onTap ?? () {},
            onFavoriteToggle: onFavoriteToggle ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display post content', (tester) async {
      await tester.pumpWidget(createPostListItem());

      expect(find.text('Test Post'), findsOneWidget);
      expect(find.text('This is a test post body'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
    });

    testWidgets('should display favorite button', (tester) async {
      await tester.pumpWidget(createPostListItem());

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(createPostListItem(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('should call onFavoriteToggle when favorite button is tapped', (tester) async {
      bool favoriteToggled = false;
      
      await tester.pumpWidget(createPostListItem(
        onFavoriteToggle: () => favoriteToggled = true,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(favoriteToggled, isTrue);
    });
  });
}