import 'package:equatable/equatable.dart';

/// User entity representing an authenticated user
class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.token,
    this.firstName,
    this.lastName,
    this.avatar,
  });

  /// Unique identifier for the user
  final int id;
  
  /// User's email address
  final String email;
  
  /// Authentication token (optional, may be null if not authenticated)
  final String? token;
  
  /// User's first name (optional)
  final String? firstName;
  
  /// User's last name (optional)
  final String? lastName;
  
  /// User's avatar URL (optional)
  final String? avatar;

  /// Get user's full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return email;
    }
  }

  /// Check if user has a valid authentication token
  bool get isAuthenticated => token != null && token!.isNotEmpty;

  /// Create a copy of this user with updated fields
  User copyWith({
    int? id,
    String? email,
    String? token,
    String? firstName,
    String? lastName,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatar: avatar ?? this.avatar,
    );
  }

  /// Create a copy without the authentication token (for logout)
  User copyWithoutToken() {
    return User(
      id: id,
      email: email,
      token: null,
      firstName: firstName,
      lastName: lastName,
      avatar: avatar,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        token,
        firstName,
        lastName,
        avatar,
      ];

  @override
  String toString() {
    return 'User(id: $id, email: $email, fullName: $fullName, isAuthenticated: $isAuthenticated)';
  }
}
