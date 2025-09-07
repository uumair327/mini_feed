import 'dart:convert';
import '../../domain/entities/comment.dart';

/// Data model for Comment entity with JSON serialization
/// 
/// Extends the domain Comment entity with JSON serialization capabilities
/// for API communication and local storage.
class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.postId,
    required super.name,
    required super.email,
    required super.body,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert to domain entity
  Comment toDomain() {
    return Comment(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory CommentModel.fromDomain(Comment comment) {
    return CommentModel(
      id: comment.id,
      postId: comment.postId,
      name: comment.name,
      email: comment.email,
      body: comment.body,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    );
  }

  /// Create from JSON (API response format)
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['postId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Convert to JSON (API request format)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postId': postId,
      'name': name,
      'email': email,
      'body': body,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory CommentModel.fromJsonString(String jsonString) {
    return CommentModel.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Create from JSONPlaceholder API response format
  factory CommentModel.fromJsonPlaceholder(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['postId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
      // JSONPlaceholder doesn't include timestamps, so we don't set them
    );
  }

  /// Convert to JSONPlaceholder API request format
  Map<String, dynamic> toJsonPlaceholder() {
    return {
      'id': id,
      'postId': postId,
      'name': name,
      'email': email,
      'body': body,
    };
  }

  /// Create a copy with updated fields
  @override
  CommentModel copyWith({
    int? id,
    int? postId,
    String? name,
    String? email,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      name: name ?? this.name,
      email: email ?? this.email,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create a comment for a specific post
  factory CommentModel.forPost({
    required int id,
    required int postId,
    required String name,
    required String email,
    required String body,
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: DateTime.now(),
    );
  }

  /// Create a mock comment for testing
  factory CommentModel.mock({
    int id = 1,
    int postId = 1,
    String name = 'Test Commenter',
    String email = 'test@example.com',
    String body = 'This is a test comment.',
  }) {
    return CommentModel(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: DateTime.now(),
    );
  }

  /// Create for local storage (includes all metadata)
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': id,
      'postId': postId,
      'name': name,
      'email': email,
      'body': body,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from local storage format
  factory CommentModel.fromLocalStorageJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as int,
      postId: json['postId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }

  /// Create for API request (new comment creation)
  Map<String, dynamic> toCreateRequestJson() {
    return {
      'postId': postId,
      'name': name,
      'email': email,
      'body': body,
    };
  }

  /// Validate comment data for creation
  bool get isValidForCreation {
    return hasValidContent && 
           name.trim().isNotEmpty && 
           email.trim().isNotEmpty && 
           body.trim().isNotEmpty;
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, postId: $postId, name: $name, email: $email)';
  }
}