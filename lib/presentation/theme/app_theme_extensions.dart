import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom theme extension for app-specific properties
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.favoriteActiveColor,
    required this.favoriteInactiveColor,
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
    required this.successColor,
    required this.warningColor,
    required this.infoColor,
    required this.cardShadowColor,
    required this.overlayColor,
  });

  final Color favoriteActiveColor;
  final Color favoriteInactiveColor;
  final Color shimmerBaseColor;
  final Color shimmerHighlightColor;
  final Color successColor;
  final Color warningColor;
  final Color infoColor;
  final Color cardShadowColor;
  final Color overlayColor;

  /// Light theme extension
  static const AppThemeExtension light = AppThemeExtension(
    favoriteActiveColor: AppColors.favoriteActive,
    favoriteInactiveColor: AppColors.favoriteInactive,
    shimmerBaseColor: Color(0xFFE5E7EB),
    shimmerHighlightColor: Color(0xFFF3F4F6),
    successColor: AppColors.success,
    warningColor: AppColors.warning,
    infoColor: AppColors.info,
    cardShadowColor: Color(0x1A000000),
    overlayColor: Color(0x80000000),
  );

  /// Dark theme extension
  static const AppThemeExtension dark = AppThemeExtension(
    favoriteActiveColor: AppColors.favoriteActive,
    favoriteInactiveColor: AppColors.favoriteInactive,
    shimmerBaseColor: Color(0xFF374151),
    shimmerHighlightColor: Color(0xFF4B5563),
    successColor: AppColors.success,
    warningColor: AppColors.warning,
    infoColor: AppColors.info,
    cardShadowColor: Color(0x4D000000),
    overlayColor: Color(0xB3000000),
  );

  @override
  AppThemeExtension copyWith({
    Color? favoriteActiveColor,
    Color? favoriteInactiveColor,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? successColor,
    Color? warningColor,
    Color? infoColor,
    Color? cardShadowColor,
    Color? overlayColor,
  }) {
    return AppThemeExtension(
      favoriteActiveColor: favoriteActiveColor ?? this.favoriteActiveColor,
      favoriteInactiveColor: favoriteInactiveColor ?? this.favoriteInactiveColor,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor: shimmerHighlightColor ?? this.shimmerHighlightColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      infoColor: infoColor ?? this.infoColor,
      cardShadowColor: cardShadowColor ?? this.cardShadowColor,
      overlayColor: overlayColor ?? this.overlayColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    return AppThemeExtension(
      favoriteActiveColor: Color.lerp(favoriteActiveColor, other.favoriteActiveColor, t)!,
      favoriteInactiveColor: Color.lerp(favoriteInactiveColor, other.favoriteInactiveColor, t)!,
      shimmerBaseColor: Color.lerp(shimmerBaseColor, other.shimmerBaseColor, t)!,
      shimmerHighlightColor: Color.lerp(shimmerHighlightColor, other.shimmerHighlightColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      cardShadowColor: Color.lerp(cardShadowColor, other.cardShadowColor, t)!,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t)!,
    );
  }
}

/// Extension to easily access custom theme properties
extension AppThemeExtensionGetter on ThemeData {
  AppThemeExtension get appExtension {
    return extension<AppThemeExtension>() ?? AppThemeExtension.light;
  }
}