import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/feed/feed_bloc.dart';
import '../../blocs/feed/feed_event.dart';
import '../../blocs/feed/feed_state.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/loading_indicators.dart';
import '../../widgets/common/error_widgets.dart';
import '../../widgets/common/comprehensive_error_widget.dart';
import '../../widgets/common/empty_state_widgets.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/offline_indicators.dart';
import '../../widgets/feed/post_list_item.dart';
import '../../widgets/feed/search_suggestions.dart';
import '../../theme/app_breakpoints.dart';
import '../post_details/post_details_page.dart';
import '../post_creation/new_post_page.dart';
import '../../../core/di/injection_container.dart' as di;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  late FeedBloc _feedBloc;
  bool _showSearchSuggestions = false;

  @override
  void initState() {
    super.initState();
    _feedBloc = di.sl<FeedBloc>();
    _feedBloc.add(const FeedRequested());
    
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _feedBloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _feedBloc.add(const FeedLoadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearchChanged(String query) {
    _feedBloc.add(FeedSearchChanged(query: query));
    setState(() {
      _showSearchSuggestions = query.isEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onSearchFocusChanged() {
    setState(() {
      _showSearchSuggestions = _searchController.text.isEmpty && _searchFocusNode.hasFocus;
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();
    _onSearchChanged(suggestion);
    // Add to search history (in a real app, this would be persisted)
    // SearchHistoryManager.addToHistory(suggestion);
  }

  void _onRefresh() {
    _feedBloc.add(const FeedRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _feedBloc,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: OfflineBanner(
          child: ResponsiveContainer(
            child: Column(
              children: [
                _buildSearchBar(),
                if (_showSearchSuggestions) _buildSearchSuggestions(),
                Expanded(
                  child: BlocBuilder<FeedBloc, FeedState>(
                    builder: (context, state) {
                      return _buildBody(state);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Mini Feed'),
      actions: [
        const ConnectivityIndicator(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => AppNavigation.logout(context),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(
        AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search posts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state is FeedInitial || state is FeedLoading) {
      return const PostShimmerList(itemCount: 10);
    }

    if (state is FeedError) {
      return ComprehensiveErrorWidget(
        message: state.message,
        details: state.details,
        canRetry: state.canRetry,
        onRetry: state.canRetry ? () => _feedBloc.add(const FeedRetryRequested()) : null,
      );
    }

    if (state is FeedLoaded) {
      if (state.posts.isEmpty) {
        return EmptyPostsWidget(
          isSearchResult: _searchController.text.isNotEmpty,
          searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
          onRefresh: _onRefresh,
        );
      }

      return RefreshIndicator(
        onRefresh: () async => _onRefresh(),
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(
            AppBreakpoints.isMobile(context) ? 8.0 : 16.0,
          ),
          itemCount: state.hasReachedMax 
              ? state.posts.length 
              : state.posts.length + 1,
          itemBuilder: (context, index) {
            if (index >= state.posts.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: AppLoadingIndicator(),
              );
            }

            final post = state.posts[index];
            return PostListItem(
              post: post,
              onTap: () => _navigateToPostDetails(post.id),
              onFavoriteToggle: () => _toggleFavorite(post.id),
              onComment: () => _navigateToPostDetails(post.id),
              onShare: () => _sharePost(post),
              searchQuery: state.searchQuery,
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _navigateToPostDetails(int postId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PostDetailsPage(postId: postId),
      ),
    );
  }

  void _toggleFavorite(int postId) {
    // TODO: Implement favorite toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Toggle favorite for post $postId')),
    );
  }

  void _sharePost(dynamic post) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share post: ${post.title}')),
    );
  }

  Widget _buildSearchSuggestions() {
    return SearchSuggestions(
      recentSearches: SearchHistoryManager.getHistory(),
      popularSearches: SearchHistoryManager.getPopularSearches(),
      onSuggestionTap: _onSuggestionTap,
      onClearHistory: () {
        SearchHistoryManager.clearHistory();
        setState(() {});
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _navigateToNewPost,
      tooltip: 'Create new post',
      child: const Icon(Icons.add),
    );
  }

  void _navigateToNewPost() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewPostPage(feedBloc: _feedBloc),
      ),
    );

    // Note: With optimistic updates, we don't need to refresh the feed
    // The optimistic post is already added and will be replaced with the real post
    // Only refresh if there was an error and we need to sync
    if (result == false) {
      _feedBloc.add(const FeedRefreshed());
    }
  }
}

