import 'package:flutter/material.dart';
import '../../../domain/entities/comment.dart';
import '../../theme/app_breakpoints.dart';
import '../common/loading_indicators.dart';

/// Widget that displays the comments section
/// 
/// Shows a list of comments with proper styling, loading states,
/// and empty state handling. Supports accessibility and responsive design.
class CommentsSection extends StatelessWidget {
  final List<Comment> comments;
  final bool isLoading;

  const CommentsSection({
    super.key,
    required this.comments,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return _buildHeader(context);
          }
          
          if (isLoading && index == 1) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: AppLoadingIndicator()),
            );
          }
          
          if (comments.isEmpty && !isLoading) {
            return _buildEmptyState(context);
          }
          
          final commentIndex = index - 1;
          if (commentIndex >= comments.length) {
            return null;
          }
          
          return _buildCommentItem(context, comments[commentIndex]);
        },
        childCount: isLoading 
            ? 2 
            : (comments.isEmpty ? 2 : comments.length + 1),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
        vertical: 16.0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.comment_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Comments (${comments.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
      ),
      child: const EmptyCommentsWidget(),
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
        vertical: 8.0,
      ),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommentHeader(context, comment),
          const SizedBox(height: 12),
          _buildCommentBody(context, comment),
        ],
      ),
    );
  }

  Widget _buildCommentHeader(BuildContext context, Comment comment) {
    return Row(
      children: [
        // Commenter avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        
        // Commenter info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                comment.email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        
        // Comment ID
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '#${comment.id}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentBody(BuildContext context, Comment comment) {
    return SelectableText(
      comment.body,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        height: 1.5,
      ),
    );
  }
}

/// Empty state widget for when there are no comments
class EmptyCommentsWidget extends StatelessWidget {
  const EmptyCommentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.comment_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'No Comments Yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be the first to share your thoughts on this post.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}