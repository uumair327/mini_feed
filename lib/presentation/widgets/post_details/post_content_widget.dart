import 'package:flutter/material.dart';
import '../../../domain/entities/post.dart';
import '../../theme/app_breakpoints.dart';

/// Widget that displays the full post content
/// 
/// Shows the post title, body, author information, metadata,
/// and favorite toggle button with proper styling and accessibility.
class PostContentWidget extends StatelessWidget {
  final Post post;
  final Function(bool) onFavoriteToggle;
  final bool isTogglingFavorite;

  const PostContentWidget({
    super.key,
    required this.post,
    required this.onFavoriteToggle,
    this.isTogglingFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(
        AppBreakpoints.isMobile(context) ? 16.0 : 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          _buildTitle(context),
          const SizedBox(height: 16),
          _buildBody(context),
          const SizedBox(height: 24),
          _buildMetadata(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Author avatar
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        
        // Author info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User ${post.userId}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                post.createdAt != null 
                    ? _formatDate(post.createdAt!) 
                    : 'Unknown date',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Favorite button
        _buildFavoriteButton(context),
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Semantics(
      label: post.isFavorite 
          ? 'Remove from favorites' 
          : 'Add to favorites',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isTogglingFavorite 
              ? null 
              : () => onFavoriteToggle(!post.isFavorite),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: isTogglingFavorite
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    post.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: post.isFavorite 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        post.title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SelectableText(
      post.body,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post Information',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetadataRow(
            context,
            'Post ID',
            '#${post.id}',
            Icons.tag,
          ),
          const SizedBox(height: 4),
          _buildMetadataRow(
            context,
            'Author',
            'User ${post.userId}',
            Icons.person_outline,
          ),
          const SizedBox(height: 4),
          _buildMetadataRow(
            context,
            'Created',
            post.createdAt != null 
                ? _formatDate(post.createdAt!) 
                : 'Unknown date',
            Icons.schedule,
          ),
          if (post.updatedAt != null && 
              post.createdAt != null && 
              post.updatedAt != post.createdAt) ...[
            const SizedBox(height: 4),
            _buildMetadataRow(
              context,
              'Updated',
              _formatDate(post.updatedAt!),
              Icons.edit_outlined,
            ),
          ],
          if (post.isOptimistic) ...[
            const SizedBox(height: 4),
            _buildMetadataRow(
              context,
              'Status',
              'Syncing...',
              Icons.sync,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final textColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: textColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}