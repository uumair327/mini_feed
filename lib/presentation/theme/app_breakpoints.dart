import 'package:flutter/material.dart';

/// Responsive breakpoints for different screen sizes
class AppBreakpoints {
  // Breakpoint values
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobile;
  }

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobile && width < desktop;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktop;
  }

  /// Check if screen is large desktop size
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeDesktop;
  }

  /// Get responsive value based on screen size
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= AppBreakpoints.largeDesktop && largeDesktop != null) {
      return largeDesktop;
    } else if (width >= AppBreakpoints.desktop && desktop != null) {
      return desktop;
    } else if (width >= AppBreakpoints.mobile && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsive(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        largeDesktop: 48.0,
      ),
      vertical: responsive(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
        largeDesktop: 32.0,
      ),
    );
  }

  /// Get responsive margin based on screen size
  static EdgeInsets responsiveMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsive(
        context,
        mobile: 8.0,
        tablet: 12.0,
        desktop: 16.0,
        largeDesktop: 24.0,
      ),
      vertical: responsive(
        context,
        mobile: 8.0,
        tablet: 10.0,
        desktop: 12.0,
        largeDesktop: 16.0,
      ),
    );
  }

  /// Get responsive font size multiplier
  static double responsiveFontSize(BuildContext context) {
    return responsive(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
      largeDesktop: 1.3,
    );
  }

  /// Get maximum content width for centering on large screens
  static double getMaxContentWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 800.0,
      largeDesktop: 1000.0,
    );
  }

  /// Get responsive grid columns count
  static int getGridColumns(BuildContext context) {
    return responsive(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }

  /// Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    return responsive(
      context,
      mobile: 1.0,
      tablet: 2.0,
      desktop: 3.0,
      largeDesktop: 4.0,
    );
  }
}