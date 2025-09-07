import '../constants/error_messages.dart';

/// Utility class for input validation
class Validators {
  /// Validates email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return ErrorMessages.emailRequired;
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return ErrorMessages.emailInvalid;
    }
    
    return null;
  }
  
  /// Validates password
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return ErrorMessages.passwordRequired;
    }
    
    if (password.length < 6) {
      return ErrorMessages.passwordTooShort;
    }
    
    return null;
  }
  
  /// Validates post title
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return ErrorMessages.titleRequired;
    }
    
    return null;
  }
  
  /// Validates post body
  static String? validateBody(String? body) {
    if (body == null || body.trim().isEmpty) {
      return ErrorMessages.bodyRequired;
    }
    
    return null;
  }
  
  /// Validates that a string is not empty
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }
  
  /// Validates minimum length
  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }
}
