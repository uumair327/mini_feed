import 'package:flutter/material.dart';
import '../../../domain/entities/post.dart';
import '../../theme/app_breakpoints.dart';
import 'search_highlight_text.dart';

/// Individual post list item widget for the feed
/// 
/// Displays a post card with title, body preview, favorite indicator,
/// and handles different states (normal, optimistic, error).
class PostListItem extends StatelessWidget {
  const PostListItem({
    super.key,
    required this.post,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onShare,
    this.onComment,
    this.showActions = true,
    this.isCompact = false,
    this.searchQuery,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onComment;
  final bool showActions;
  final bool isCompact;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 2 : 4,
        horizontal: 0,
      ),
      child: Semantics(
        label: 'Post by User ${post.userId}: ${post.title}',
        hint: 'Tap to view full post',
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                if (!isCompact) const SizedBox(height: 12),
                _buildContent(context),
                if (showActions) ...[
                  const SizedBox(height: 16),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // User avatar
        Semantics(
          label: 'User ${post.userId} avatar',
          child: CircleAvatar(
            radius: isCompact ? 16 : 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              post.title.isNotEmpty ? post.title[0].toUpperCase() : 'P',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 14 : 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'User ${post.userId}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (post.isOptimistic) ...[
                    Icon(
                      Icons.sync,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Syncing...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
              if (post.createdAt != null)
                Text(
                  _formatDate(post.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        // Favorite button in header for compact mode
        if (isCompact)
          Semantics(
            label: post.isFavorite 
                ? 'Remove ${post.title} from favorites' 
                : 'Add ${post.title} to favorites',
            button: true,
            child: IconButton(
              icon: Icon(
                post.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: post.isFavorite 
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
              onPressed: onFavoriteToggle,
              tooltip: post.isFavorite 
                  ? 'Remove from favorites' 
                  : 'Add to favorites',
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Post title
        searchQuery != null && searchQuery!.isNotEmpty
            ? SearchHighlightText(
                text: post.title,
                searchQuery: searchQuery!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
        const SizedBox(height: 8),
        // Post body preview
        searchQuery != null && searchQuery!.isNotEmpty
            ? SearchHighlightText(
                text: post.bodyPreview,
                searchQuery: searchQuery!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                post.bodyPreview,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
              ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (isCompact) return const SizedBox.shrink();
    
    return Row(
      children: [
        // Favorite button
        Semantics(
          label: post.isFavorite 
              ? 'Remove ${post.title} from favorites' 
              : 'Add ${post.title} to favorites',
          button: true,
          child: IconButton(
            icon: Icon(
              post.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: post.isFavorite 
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            onPressed: onFavoriteToggle,
            tooltip: post.isFavorite 
                ? 'Remove from favorites' 
                : 'Add to favorites',
          ),
        ),
        const SizedBox(width: 8),
        
        // Comment button
        if (onComment != null) ...[
          Semantics(
            label: 'View comments for ${post.title}',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.comment_outlined),
              onPressed: onComment,
              tooltip: 'View comments',
            ),
          ),
          const SizedBox(width: 8),
        ],
        
        const Spacer(),
        
        // Share button
        if (onShare != null)
          Semantics(
            label: 'Share ${post.title}',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: onShare,
              tooltip: 'Share post',
            ),
          ),
        
        // More options button
        Semantics(
          label: 'More options for ${post.title}',
          button: true,
          child: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy_link':
                  // TODO: Implement copy link
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied to clipboard')),
                  );
                  break;
                case 'report':
                  // TODO: Implement report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Post reported')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_link',
                child: ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Copy link'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: ListTile(
                  leading: Icon(Icons.report_outlined),
                  title: Text('Report'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            tooltip: 'More options',
            child: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Compact version of post list item for dense layouts
class CompactPostListItem extends StatelessWidget {
  const CompactPostListItem({
    super.key,
    required this.post,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return PostListItem(
      post: post,
      onTap: onTap,
      onFavoriteToggle: onFavoriteToggle,
      isCompact: true,
      showActions: false,
    );
  }
}

/// Post list item with shimmer loading effect
class PostListItemShimmer extends StatelessWidget {
  const PostListItemShimmer({
    super.key,
    this.isCompact = false,
  });

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 2 : 4,
        horizontal: 0,
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header shimmer
            Row(
              children: [
                Container(
                  width: isCompact ? 32 : 40,
                  height: isCompact ? 32 : 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (!isCompact) const SizedBox(height: 12),
            
            // Content shimmer
            Container(
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            
            if (!isCompact) ...[
              const SizedBox(height: 16),
              // Actions shimmer
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}