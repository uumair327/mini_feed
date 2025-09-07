import 'package:flutter/material.dart';
import '../../../domain/entities/post.dart';
import 'post_list_item.dart';

/// Grid view variant of post list item for tablet/desktop layouts
class PostGridItem extends StatelessWidget {
  const PostGridItem({
    super.key,
    required this.post,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onShare,
    this.onComment,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and favorite
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      post.title.isNotEmpty ? post.title[0].toUpperCase() : 'P',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      post.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: post.isFavorite 
                          ? Theme.of(context).colorScheme.error
                          : null,
                      size: 20,
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: post.isFavorite 
                        ? 'Remove from favorites' 
                        : 'Add to favorites',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        post.body,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Footer with user info and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ${post.userId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
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
                  if (onComment != null)
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: onComment,
                      iconSize: 18,
                      tooltip: 'View comments',
                    ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: onShare,
                      iconSize: 18,
                      tooltip: 'Share post',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Minimal post list item for search results or dense lists
class MinimalPostListItem extends StatelessWidget {
  const MinimalPostListItem({
    super.key,
    required this.post,
    required this.onTap,
    this.showFavorite = true,
    this.onFavoriteToggle,
  });

  final Post post;
  final VoidCallback onTap;
  final bool showFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Post by User ${post.userId}: ${post.title}',
      hint: 'Tap to view full post',
      button: true,
      child: ListTile(
        onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          post.title.isNotEmpty ? post.title[0].toUpperCase() : 'P',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(
        post.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.bodyPreview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'User ${post.userId}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (post.createdAt != null) ...[
                Text(
                  ' • ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDate(post.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (post.isOptimistic) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.sync,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ],
          ),
        ],
      ),
        trailing: showFavorite && onFavoriteToggle != null
            ? Semantics(
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
                    size: 20,
                  ),
                  onPressed: onFavoriteToggle,
                  tooltip: post.isFavorite 
                      ? 'Remove from favorites' 
                      : 'Add to favorites',
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

/// Featured post item with larger display for important posts
class FeaturedPostListItem extends StatelessWidget {
  const FeaturedPostListItem({
    super.key,
    required this.post,
    required this.onTap,
    required this.onFavoriteToggle,
    this.onShare,
    this.onComment,
  });

  final Post post;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onShare;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Featured badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'FEATURED',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      post.title.isNotEmpty ? post.title[0].toUpperCase() : 'P',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User ${post.userId}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (post.createdAt != null)
                          Text(
                            _formatDate(post.createdAt!),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
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
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Content
              Text(
                post.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 20),
              
              // Actions
              Row(
                children: [
                  if (onComment != null) ...[
                    TextButton.icon(
                      onPressed: onComment,
                      icon: const Icon(Icons.comment_outlined),
                      label: const Text('Comments'),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (onShare != null) ...[
                    TextButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                  ],
                  const Spacer(),
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
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}