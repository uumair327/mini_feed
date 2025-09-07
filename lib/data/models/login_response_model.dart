import 'dart:convert';
import '../../domain/entities/user.dart';
import 'user_model.dart';

/// Model for login API response
/// 
/// Represents the response from authentication endpoints including
/// user data and authentication tokens.
class LoginResponseModel {
  const LoginResponseModel({
    required this.user,
    required this.token,
    this.refreshToken,
    this.expiresIn,
    this.tokenType = 'Bearer',
  });

  /// User information
  final UserModel user;
  
  /// Access token for API authentication
  final String token;
  
  /// Refresh token for token renewal (optional)
  final String? refreshToken;
  
  /// Token expiration time in seconds (optional)
  final int? expiresIn;
  
  /// Token type (default: Bearer)
  final String tokenType;

  /// Convert to domain entity
  User toDomain() {
    return user.toDomain().copyWith(token: token);
  }

  /// Create from JSON
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      tokenType: json['token_type'] as String? ?? 'Bearer',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (expiresIn != null) 'expires_in': expiresIn,
      'token_type': tokenType,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory LoginResponseModel.fromJsonString(String jsonString) {
    return LoginResponseModel.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Create a copy with updated fields
  LoginResponseModel copyWith({
    UserModel? user,
    String? token,
    String? refreshToken,
    int? expiresIn,
    String? tokenType,
  }) {
    return LoginResponseModel(
      user: user ?? this.user,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresIn: expiresIn ?? this.expiresIn,
      tokenType: tokenType ?? this.tokenType,
    );
  }

  /// Check if token is expired based on current time
  bool get isExpired {
    if (expiresIn == null) return false;
    // This is a simplified check - in a real app you'd store the issued time
    // and calculate expiration based on that
    return false;
  }

  /// Get token with type prefix for Authorization header
  String get authorizationHeader => '$tokenType $token';

  @override
  String toString() {
    return 'LoginResponseModel(user: ${user.email}, tokenType: $tokenType, expiresIn: $expiresIn)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginResponseModel &&
        other.user == user &&
        other.token == token &&
        other.refreshToken == refreshToken &&
        other.expiresIn == expiresIn &&
        other.tokenType == tokenType;
  }

  @override
  int get hashCode {
    return Object.hash(
      user,
      token,
      refreshToken,
      expiresIn,
      tokenType,
    );
  }
}