import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/post_details/post_details_bloc.dart';
import '../../blocs/post_details/post_details_event.dart';
import '../../blocs/post_details/post_details_state.dart';
import '../../widgets/common/loading_indicators.dart';
import '../../widgets/common/error_widgets.dart';
import '../../widgets/common/responsive_layout.dart';
import '../../widgets/common/offline_indicators.dart';
import '../../widgets/post_details/post_content_widget.dart';
import '../../widgets/post_details/comments_section.dart';
import '../../theme/app_breakpoints.dart';
import '../../../core/di/injection_container.dart' as di;

/// Post details page that displays full post content and comments
/// 
/// Shows the complete post with title, body, author information,
/// favorite toggle, and comments section. Supports pull-to-refresh
/// and proper error handling.
class PostDetailsPage extends StatefulWidget {
  final int postId;

  const PostDetailsPage({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  late PostDetailsBloc _postDetailsBloc;

  @override
  void initState() {
    super.initState();
    _postDetailsBloc = di.sl<PostDetailsBloc>();
    _postDetailsBloc.add(PostDetailsRequested(postId: widget.postId));
  }

  @override
  void dispose() {
    _postDetailsBloc.close();
    super.dispose();
  }

  void _onRefresh() {
    _postDetailsBloc.add(PostDetailsRefreshed(postId: widget.postId));
  }

  void _onFavoriteToggle(bool isFavorite) {
    _postDetailsBloc.add(FavoriteToggled(
      postId: widget.postId,
      isFavorite: isFavorite,
    ));
  }

  void _onRetry() {
    _postDetailsBloc.add(PostDetailsRetryRequested(postId: widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _postDetailsBloc,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: OfflineBanner(
          child: ResponsiveContainer(
            child: BlocBuilder<PostDetailsBloc, PostDetailsState>(
              builder: (context, state) {
                return _buildBody(state);
              },
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Post Details'),
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        const ConnectivityIndicator(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(PostDetailsState state) {
    if (state is PostDetailsLoading) {
      return const Center(
        child: AppLoadingIndicator(),
      );
    }

    if (state is PostDetailsError) {
      return AppErrorWidget(
        message: state.message,
        onRetry: state.canRetry ? _onRetry : null,
      );
    }

    if (state is PostDetailsLoaded) {
      return RefreshIndicator(
        onRefresh: () async => _onRefresh(),
        child: CustomScrollView(
          slivers: [
            // Post content
            SliverToBoxAdapter(
              child: PostContentWidget(
                post: state.post,
                onFavoriteToggle: _onFavoriteToggle,
                isTogglingFavorite: state.isTogglingFavorite,
              ),
            ),
            
            // Divider
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
                  vertical: 16.0,
                ),
                height: 1,
                color: Theme.of(context).dividerColor,
              ),
            ),
            
            // Comments section
            CommentsSection(
              comments: state.comments,
              isLoading: state.isRefreshing,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}