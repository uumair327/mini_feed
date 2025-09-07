import 'package:flutter/material.dart';
import '../../theme/app_breakpoints.dart';

/// A responsive layout widget that adapts to different screen sizes
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return AppBreakpoints.responsive<Widget>(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }
}

/// A responsive container with maximum width constraints
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.margin,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? AppBreakpoints.getMaxContentWidth(context);
    
    return Container(
      width: double.infinity,
      margin: margin,
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Container(
          padding: padding ?? AppBreakpoints.responsivePadding(context),
          child: child,
        ),
      ),
    );
  }
}

/// A responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final columns = AppBreakpoints.getGridColumns(context);
    
    return GridView.builder(
      padding: padding ?? AppBreakpoints.responsivePadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// A responsive wrap widget that adjusts spacing based on screen size
class ResponsiveWrap extends StatelessWidget {
  const ResponsiveWrap({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
  });

  final List<Widget> children;
  final Axis direction;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final spacing = AppBreakpoints.responsive(
      context,
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
    
    return Wrap(
      direction: direction,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      runSpacing: spacing,
      children: children,
    );
  }
}

/// A responsive row that stacks vertically on mobile
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
    this.stackOnMobile = true,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool stackOnMobile;

  @override
  Widget build(BuildContext context) {
    if (stackOnMobile && AppBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [child, SizedBox(width: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

/// A responsive column that becomes horizontal on larger screens
class ResponsiveColumn extends StatelessWidget {
  const ResponsiveColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16.0,
    this.horizontalOnTablet = true,
  });

  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool horizontalOnTablet;

  @override
  Widget build(BuildContext context) {
    if (horizontalOnTablet && !AppBreakpoints.isMobile(context)) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .expand((child) => [child, SizedBox(width: spacing)])
            .take(children.length * 2 - 1)
            .toList(),
      );
    }
    
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [child, SizedBox(height: spacing)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }
}

/// A responsive card with adaptive elevation and padding
class ResponsiveCard extends StatelessWidget {
  const ResponsiveCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.elevation,
    this.color,
    this.shape,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? AppBreakpoints.responsiveMargin(context),
      elevation: elevation ?? AppBreakpoints.getCardElevation(context),
      color: color,
      shape: shape,
      child: Padding(
        padding: padding ?? AppBreakpoints.responsivePadding(context),
        child: child,
      ),
    );
  }
}

/// A responsive list view with adaptive padding
class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ?? AppBreakpoints.responsivePadding(context),
      shrinkWrap: shrinkWrap,
      physics: physics,
      scrollDirection: scrollDirection,
      children: children,
    );
  }
}

/// A responsive safe area with adaptive padding
class ResponsiveSafeArea extends StatelessWidget {
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
  });

  final Widget child;
  final EdgeInsets minimum;
  final bool maintainBottomViewPadding;

  @override
  Widget build(BuildContext context) {
    final responsivePadding = AppBreakpoints.responsivePadding(context);
    
    return SafeArea(
      minimum: minimum + responsivePadding,
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }
}

/// A responsive scaffold with adaptive app bar and body
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: ResponsiveContainer(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}