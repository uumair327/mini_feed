class CacheConstants {
  // Hive box names
  static const String postsBox = 'posts_box';
  static const String favoritesBox = 'favorites_box';
  static const String userBox = 'user_box';
  
  // SharedPreferences keys
  static const String themeKey = 'theme_mode';
  static const String authTokenKey = 'auth_token';
  
  // Cache settings
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCacheSize = 1000; // Maximum number of cached posts
  static const int defaultTtlHours = 24;
  static const String defaultVersion = '1.0.0';
}
