import 'dart:convert';
import '../../domain/entities/user.dart';

/// Data model for User entity with JSON serialization
/// 
/// Extends the domain User entity with JSON serialization capabilities
/// for API communication and local storage.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.token,
    super.firstName,
    super.lastName,
    super.avatar,
  });

  /// Convert to domain entity
  User toDomain() {
    return User(
      id: id,
      email: email,
      token: token,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }

  /// Create from domain entity
  factory UserModel.fromDomain(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      token: user.token,
      firstName: user.firstName,
      lastName: user.lastName,
      avatar: user.avatar,
    );
  }

  /// Create from JSON (API response format)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      token: json['token'] as String?,
      firstName: json['first_name'] as String? ?? json['firstName'] as String?,
      lastName: json['last_name'] as String? ?? json['lastName'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// Convert to JSON (API request format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (token != null) 'token': token,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatar != null) 'avatar': avatar,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Create a copy with updated fields
  @override
  UserModel copyWith({
    int? id,
    String? email,
    String? token,
    String? firstName,
    String? lastName,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
    );
  }

  /// Create a copy without the authentication token (for logout)
  @override
  UserModel copyWithoutToken() {
    return UserModel(
      id: id,
      email: email,
      token: null,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }

  /// Create from reqres.in API response format
  factory UserModel.fromReqresJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  /// Convert to reqres.in API request format
  Map<String, dynamic> toReqresJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (avatar != null) 'avatar': avatar,
    };
  }

  /// Create a mock user for testing
  factory UserModel.mock({
    int id = 1,
    String email = 'test@example.com',
    String? token,
    String? firstName = 'Test',
    String? lastName = 'User',
    String? avatar,
  }) {
    return UserModel(
      id: id,
      email: email,
      token: token,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, fullName: $fullName, isAuthenticated: $isAuthenticated)';
  }
}