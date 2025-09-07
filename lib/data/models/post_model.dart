import 'dart:convert';
import '../../domain/entities/post.dart';

/// Data model for Post entity with JSON serialization
/// 
/// Extends the domain Post entity with JSON serialization capabilities
/// for API communication and local storage.
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.title,
    required super.body,
    required super.userId,
    super.isFavorite = false,
    super.isOptimistic = false,
    super.createdAt,
    super.updatedAt,
  });

  /// Convert to domain entity
  Post toDomain() {
    return Post(
      id: id,
      title: title,
      body: body,
      userId: userId,
      isFavorite: isFavorite,
      isOptimistic: isOptimistic,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain entity
  factory PostModel.fromDomain(Post post) {
    return PostModel(
      id: post.id,
      title: post.title,
      body: post.body,
      userId: post.userId,
      isFavorite: post.isFavorite,
      isOptimistic: post.isOptimistic,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
    );
  }

  /// Create from JSON (API response format)
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      userId: json['userId'] as int,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isOptimistic: json['isOptimistic'] as bool? ?? false,
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
      'title': title,
      'body': body,
      'userId': userId,
      'isFavorite': isFavorite,
      'isOptimistic': isOptimistic,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());

  /// Create from JSON string
  factory PostModel.fromJsonString(String jsonString) {
    return PostModel.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );
  }

  /// Create from JSONPlaceholder API response format
  factory PostModel.fromJsonPlaceholder(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      userId: json['userId'] as int,
      // JSONPlaceholder doesn't include these fields, so we use defaults
      isFavorite: false,
      isOptimistic: false,
    );
  }

  /// Convert to JSONPlaceholder API request format
  Map<String, dynamic> toJsonPlaceholder() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'userId': userId,
    };
  }

  /// Create a copy with updated fields
  @override
  PostModel copyWith({
    int? id,
    String? title,
    String? body,
    int? userId,
    bool? isFavorite,
    bool? isOptimistic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Toggle the favorite status of this post
  @override
  PostModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// Mark this post as synced (no longer optimistic)
  @override
  PostModel markAsSynced({int? syncedId}) {
    return copyWith(
      id: syncedId ?? id,
      isOptimistic: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Create an optimistic post for immediate UI updates
  factory PostModel.optimistic({
    required String title,
    required String body,
    required int userId,
    int? tempId,
  }) {
    return PostModel(
      id: tempId ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      userId: userId,
      isOptimistic: true,
      createdAt: DateTime.now(),
    );
  }

  /// Create a mock post for testing
  factory PostModel.mock({
    int id = 1,
    String title = 'Test Post',
    String body = 'This is a test post body.',
    int userId = 1,
    bool isFavorite = false,
    bool isOptimistic = false,
  }) {
    return PostModel(
      id: id,
      title: title,
      body: body,
      userId: userId,
      isFavorite: isFavorite,
      isOptimistic: isOptimistic,
      createdAt: DateTime.now(),
    );
  }

  /// Create for local storage (includes all metadata)
  Map<String, dynamic> toLocalStorageJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'userId': userId,
      'isFavorite': isFavorite,
      'isOptimistic': isOptimistic,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from local storage format
  factory PostModel.fromLocalStorageJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
      userId: json['userId'] as int,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isOptimistic: json['isOptimistic'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : null,
    );
  }

  @override
  String toString() {
    return 'PostModel(id: $id, title: $title, userId: $userId, isFavorite: $isFavorite, isOptimistic: $isOptimistic)';
  }
}