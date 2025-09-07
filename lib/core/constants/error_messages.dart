class ErrorMessages {
  // Network errors
  static const String noInternetConnection = 
      'No internet connection available';
  static const String connectionTimeout = 
      'Connection timeout. Please try again';
  static const String serverError = 
      'Server error occurred. Please try again later';
  static const String requestCancelled = 'Request was cancelled';
  static const String unexpectedError = 'An unexpected error occurred';
  
  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password';
  static const String authTokenExpired = 'Session expired. Please login again';
  static const String authTokenNotFound = 'Authentication token not found';
  static const String loginRequired = 'Please login to continue';
  
  // Cache errors
  static const String cacheReadError = 'Failed to read from cache';
  static const String cacheWriteError = 'Failed to write to cache';
  static const String cacheNotFound = 'Data not found in cache';
  static const String cacheCorrupted = 'Cache data is corrupted';
  
  // Validation errors
  static const String emailRequired = 'Email is required';
  static const String emailInvalid = 'Please enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 
      'Password must be at least 6 characters';
  static const String titleRequired = 'Title is required';
  static const String bodyRequired = 'Body is required';
  
  // Data errors
  static const String dataParsingError = 'Failed to parse response data';
  static const String dataNotFound = 'Requested data not found';
  static const String dataCorrupted = 'Data is corrupted or invalid';
  
  // Post errors
  static const String postNotFound = 'Post not found';
  static const String postCreateFailed = 'Failed to create post';
  static const String postUpdateFailed = 'Failed to update post';
  static const String commentsLoadFailed = 'Failed to load comments';
  
  // Search errors
  static const String searchFailed = 'Search operation failed';
  static const String noSearchResults = 'No results found for your search';
  
  // Generic messages
  static const String tryAgain = 'Please try again';
  static const String checkConnection = 'Please check your internet connection';
  static const String contactSupport = 
      'Please contact support if the problem persists';
}
