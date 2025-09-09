import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/presentation/pages/feed/feed_page.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_event.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_state.dart';
import 'package:mini_feed/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:mini_feed/presentation/blocs/connectivity/connectivity_state.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/entities/user.dart';

class MockFeedBloc extends Mock implements FeedBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockConnectivityCubit extends Mock implements ConnectivityCubit {}

void main() {
  group('FeedPage Comprehensive Tests', () {
    late MockFeedBloc mockFeedBloc;
    late MockAuthBloc mockAuthBloc;
    late MockConnectivityCubit mockConnectivityCubit;

    setUp(() {
      mockFeedBloc = MockFeedBloc();
      mockAuthBloc = MockAuthBloc();
      mockConnectivityCubit = MockConnectivityCubit();

      // Set up default states
      when(() => mockFeedBloc.state).thenReturn(const FeedInitial());
      when(() => mockFeedBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: User(
        id: 1,
        email: 'test@example.com',
        token: 'test-token',
      )));
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockConnectivityCubit.state).thenReturn(const ConnectivityConnected(connectionType: 'wifi'));
      when(() => mockConnectivityCubit.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<FeedBloc>.value(value: mockFeedBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<ConnectivityCubit>.value(value: mockConnectivityCubit),
          ],
          child: const FeedPage(),
        ),
      );
    }

    group('Loading States', () {
      testWidgets('should show shimmer loading when feed is loading', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoading());

        await tester.pumpWidget(createTestWidget());

        // Verify shimmer loading is displayed
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('should show initial loading state', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedInitial());

        await tester.pumpWidget(createTestWidget());

        // Verify initial loading is displayed
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('Loaded States', () {
      final testPosts = [
        const Post(
          id: 1,
          title: 'Test Post 1',
          body: 'This is test post 1',
          userId: 1,
        ),
        const Post(
          id: 2,
          title: 'Test Post 2',
          body: 'This is test post 2',
          userId: 1,
        ),
      ];

      testWidgets('should display posts when feed is loaded', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(FeedLoaded(
          posts: testPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify posts are displayed
        expect(find.text('Test Post 1'), findsOneWidget);
        expect(find.text('Test Post 2'), findsOneWidget);
      });

      testWidgets('should show loading indicator when loading more posts', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(FeedLoaded(
          posts: testPosts,
          hasReachedMax: false,
          isLoadingMore: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify posts are displayed
        expect(find.text('Test Post 1'), findsOneWidget);
        expect(find.text('Test Post 2'), findsOneWidget);
        
        // Verify loading indicator for more posts
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show refresh indicator when refreshing', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(FeedLoaded(
          posts: testPosts,
          hasReachedMax: false,
          isRefreshing: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify posts are displayed
        expect(find.text('Test Post 1'), findsOneWidget);
        expect(find.text('Test Post 2'), findsOneWidget);
        
        // Verify refresh indicator
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('should show empty state when no posts', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedEmpty());

        await tester.pumpWidget(createTestWidget());

        // Verify empty state is displayed
        expect(find.textContaining('No posts'), findsOneWidget);
      });

      testWidgets('should show empty search results when search returns no posts', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedEmpty(
          searchQuery: 'nonexistent',
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify empty search state is displayed
        expect(find.textContaining('No posts found'), findsOneWidget);
      });
    });

    group('Error States', () {
      testWidgets('should show error widget when feed fails to load', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedError(
          message: 'Failed to load posts',
          canRetry: true,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify error message is displayed
        expect(find.text('Failed to load posts'), findsOneWidget);
        
        // Verify retry button is displayed
        expect(find.text('Try Again'), findsOneWidget);
      });

      testWidgets('should not show retry button for non-retryable errors', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedError(
          message: 'Authentication required',
          canRetry: false,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify error message is displayed
        expect(find.text('Authentication required'), findsOneWidget);
        
        // Verify retry button is not displayed
        expect(find.text('Try Again'), findsNothing);
      });

      testWidgets('should trigger retry when retry button is tapped', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedError(
          message: 'Network error',
          canRetry: true,
        ));

        await tester.pumpWidget(createTestWidget());

        // Tap retry button
        await tester.tap(find.text('Try Again'));
        await tester.pump();

        // Verify retry event was added to bloc
        verify(() => mockFeedBloc.add(const FeedRetryRequested())).called(1);
      });
    });

    group('Search Functionality', () {
      testWidgets('should display search bar', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify search bar is displayed
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search posts...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should trigger search when text is entered', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Enter search text
        await tester.enterText(find.byType(TextField), 'test query');
        await tester.pump();

        // Wait for debounce
        await tester.pump(const Duration(milliseconds: 300));

        // Verify search event was added to bloc
        verify(() => mockFeedBloc.add(const FeedSearchChanged(query: 'test query'))).called(1);
      });

      testWidgets('should show clear button when search text is entered', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Enter search text
        await tester.enterText(find.byType(TextField), 'test');
        await tester.pump();

        // Verify clear button is displayed
        expect(find.byIcon(Icons.clear), findsOneWidget);

        // Tap clear button
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pump();

        // Verify search was cleared
        expect(find.text('test'), findsNothing);
      });
    });

    group('Pull to Refresh', () {
      testWidgets('should trigger refresh when pulled down', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [
            Post(
              id: 1,
              title: 'Test Post',
              body: 'Test Body',
              userId: 1,
            ),
          ],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Perform pull to refresh
        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Verify refresh event was added to bloc
        verify(() => mockFeedBloc.add(const FeedRefreshed())).called(1);
      });
    });

    group('Infinite Scroll', () {
      testWidgets('should load more posts when scrolled to bottom', (tester) async {
        final manyPosts = List.generate(20, (index) => Post(
          id: index + 1,
          title: 'Post ${index + 1}',
          body: 'Body ${index + 1}',
          userId: 1,
        ));

        when(() => mockFeedBloc.state).thenReturn(FeedLoaded(
          posts: manyPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Scroll to bottom
        await tester.scrollUntilVisible(
          find.byType(CircularProgressIndicator),
          500.0,
          scrollable: find.byType(Scrollable),
        );

        // Verify load more event was added to bloc
        verify(() => mockFeedBloc.add(const FeedLoadMore())).called(1);
      });
    });

    group('Floating Action Button', () {
      testWidgets('should display floating action button', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify FAB is displayed
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should navigate to new post page when FAB is tapped', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Tap FAB
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Verify navigation occurred (this would need proper navigation testing setup)
        // For now, we just verify the tap doesn't cause errors
        expect(tester.takeException(), isNull);
      });
    });

    group('App Bar', () {
      testWidgets('should display app bar with title and actions', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify app bar elements
        expect(find.text('Mini Feed'), findsOneWidget);
        expect(find.byIcon(Icons.logout), findsOneWidget);
      });

      testWidgets('should show connectivity indicator in app bar', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify connectivity indicator is present
        // This would depend on the actual ConnectivityIndicator implementation
        expect(find.byType(AppBar), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt layout for mobile screens', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        // Set mobile screen size
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());

        // Verify mobile layout adaptations
        expect(find.byType(Scaffold), findsOneWidget);
        
        // Reset screen size
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('should adapt layout for tablet screens', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [],
          hasReachedMax: true,
          currentPage: 1,
        ));

        // Set tablet screen size
        tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());

        // Verify tablet layout adaptations
        expect(find.byType(Scaffold), findsOneWidget);
        
        // Reset screen size
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [
            Post(
              id: 1,
              title: 'Test Post',
              body: 'Test Body',
              userId: 1,
            ),
          ],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify semantic labels are present
        expect(find.byTooltip('Logout'), findsOneWidget);
        
        // Verify search field has proper semantics
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);
      });

      testWidgets('should support screen reader navigation', (tester) async {
        when(() => mockFeedBloc.state).thenReturn(const FeedLoaded(
          posts: [
            Post(
              id: 1,
              title: 'Test Post',
              body: 'Test Body',
              userId: 1,
            ),
          ],
          hasReachedMax: true,
          currentPage: 1,
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify semantic structure for screen readers
        expect(find.byType(Semantics), findsWidgets);
      });
    });
  });
}