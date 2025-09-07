import 'package:flutter/material.dart';
import '../../theme/app_breakpoints.dart';

/// A reusable empty state widget with helpful messaging
class AppEmptyStateWidget extends StatelessWidget {
  const AppEmptyStateWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: AppBreakpoints.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or icon
            if (illustration != null)
              illustration!
            else
              Icon(
                icon,
                size: AppBreakpoints.responsive(
                  context,
                  mobile: 80.0,
                  tablet: 96.0,
                  desktop: 112.0,
                ),
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            
            SizedBox(
              height: AppBreakpoints.responsive(
                context,
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
            ),
            
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Action button
            if (actionText != null && onAction != null) ...[
              SizedBox(
                height: AppBreakpoints.responsive(
                  context,
                  mobile: 32.0,
                  tablet: 36.0,
                  desktop: 40.0,
                ),
              ),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for when no posts are available
class EmptyPostsWidget extends StatelessWidget {
  const EmptyPostsWidget({
    super.key,
    this.onRefresh,
    this.isSearchResult = false,
    this.searchQuery,
  });

  final VoidCallback? onRefresh;
  final bool isSearchResult;
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    if (isSearchResult) {
      return AppEmptyStateWidget(
        icon: Icons.search_off,
        title: 'No results found',
        subtitle: searchQuery != null
            ? 'No posts found for "$searchQuery".\nTry adjusting your search terms.'
            : 'No posts match your search criteria.\nTry different keywords.',
        actionText: 'Clear Search',
        onAction: onRefresh,
      );
    }
    
    return AppEmptyStateWidget(
      icon: Icons.article_outlined,
      title: 'No posts yet',
      subtitle: 'There are no posts to display at the moment.\nCheck back later or try refreshing.',
      actionText: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
    );
  }
}

/// Empty state for when no comments are available
class EmptyCommentsWidget extends StatelessWidget {
  const EmptyCommentsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyStateWidget(
      icon: Icons.comment_outlined,
      title: 'No comments yet',
      subtitle: 'Be the first to share your thoughts on this post.',
    );
  }
}

/// Empty state for when no favorites are available
class EmptyFavoritesWidget extends StatelessWidget {
  const EmptyFavoritesWidget({
    super.key,
    this.onBrowsePosts,
  });

  final VoidCallback? onBrowsePosts;

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateWidget(
      icon: Icons.favorite_outline,
      title: 'No favorites yet',
      subtitle: 'Posts you mark as favorites will appear here.\nStart exploring to find interesting content!',
      actionText: onBrowsePosts != null ? 'Browse Posts' : null,
      onAction: onBrowsePosts,
    );
  }
}

/// Empty state for offline mode
class OfflineEmptyWidget extends StatelessWidget {
  const OfflineEmptyWidget({
    super.key,
    this.onRetry,
  });

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyStateWidget(
      icon: Icons.cloud_off,
      title: 'You\'re offline',
      subtitle: 'No cached content available.\nConnect to the internet to load posts.',
      actionText: onRetry != null ? 'Try Again' : null,
      onAction: onRetry,
    );
  }
}

/// Empty state with custom illustration
class IllustratedEmptyState extends StatelessWidget {
  const IllustratedEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
    this.illustrationPath,
    this.illustrationWidget,
  });

  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final String? illustrationPath;
  final Widget? illustrationWidget;

  @override
  Widget build(BuildContext context) {
    Widget? illustration;
    
    if (illustrationWidget != null) {
      illustration = illustrationWidget;
    } else if (illustrationPath != null) {
      illustration = Image.asset(
        illustrationPath!,
        width: AppBreakpoints.responsive(
          context,
          mobile: 200.0,
          tablet: 240.0,
          desktop: 280.0,
        ),
        height: AppBreakpoints.responsive(
          context,
          mobile: 150.0,
          tablet: 180.0,
          desktop: 210.0,
        ),
        fit: BoxFit.contain,
      );
    }
    
    return AppEmptyStateWidget(
      title: title,
      subtitle: subtitle,
      actionText: actionText,
      onAction: onAction,
      illustration: illustration,
    );
  }
}

/// Compact empty state for smaller spaces
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionText,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state for list items with pull-to-refresh
class RefreshableEmptyState extends StatelessWidget {
  const RefreshableEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.refresh,
    required this.onRefresh,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: AppEmptyStateWidget(
            title: title,
            subtitle: subtitle,
            icon: icon,
            actionText: 'Pull to refresh',
          ),
        ),
      ),
    );
  }
}