import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_theme_extensions.dart';

/// A circular loading indicator with consistent styling
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
}

/// A centered loading indicator with optional message
class CenteredLoadingIndicator extends StatelessWidget {
  const CenteredLoadingIndicator({
    super.key,
    this.message,
    this.size = 32.0,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoadingIndicator(size: size),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A linear loading indicator for progress indication
class AppLinearProgressIndicator extends StatelessWidget {
  const AppLinearProgressIndicator({
    super.key,
    this.value,
    this.backgroundColor,
    this.valueColor,
    this.minHeight = 4.0,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? valueColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: backgroundColor,
      valueColor: valueColor != null
          ? AlwaysStoppedAnimation<Color>(valueColor!)
          : null,
      minHeight: minHeight,
    );
  }
}

/// Shimmer effect for loading placeholders
class AppShimmer extends StatelessWidget {
  const AppShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final theme = Theme.of(context);
    final appExtension = theme.appExtension;

    return Shimmer.fromColors(
      baseColor: appExtension.shimmerBaseColor,
      highlightColor: appExtension.shimmerHighlightColor,
      child: child,
    );
  }
}

/// Shimmer placeholder for text content
class ShimmerText extends StatelessWidget {
  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 16,
    this.enabled = true,
  });

  final double width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for circular content (avatars, icons)
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({
    super.key,
    this.size = 40,
    this.enabled = true,
  });

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      enabled: enabled,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Shimmer placeholder for rectangular content (images, cards)
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 8.0,
    this.enabled = true,
  });

  final double width;
  final double height;
  final double borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer loading placeholder for post list items
class PostShimmerItem extends StatelessWidget {
  const PostShimmerItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppBreakpoints.responsiveMargin(context),
      child: Padding(
        padding: AppBreakpoints.responsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title shimmer
            ShimmerText(
              width: AppBreakpoints.responsive(
                context,
                mobile: 200,
                tablet: 250,
                desktop: 300,
              ),
              height: 20,
            ),
            const SizedBox(height: 8),
            // Body shimmer lines
            ShimmerText(
              width: double.infinity,
              height: 16,
            ),
            const SizedBox(height: 4),
            ShimmerText(
              width: AppBreakpoints.responsive(
                context,
                mobile: 150,
                tablet: 200,
                desktop: 250,
              ),
              height: 16,
            ),
            const SizedBox(height: 12),
            // Action buttons shimmer
            Row(
              children: [
                ShimmerBox(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
                const SizedBox(width: 8),
                ShimmerText(width: 60, height: 14),
                const Spacer(),
                ShimmerBox(
                  width: 80,
                  height: 32,
                  borderRadius: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading list for multiple items
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Predefined shimmer list for posts
class PostShimmerList extends StatelessWidget {
  const PostShimmerList({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ShimmerList(
      itemCount: itemCount,
      itemBuilder: (context, index) => const PostShimmerItem(),
    );
  }
}