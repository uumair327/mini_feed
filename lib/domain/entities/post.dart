import 'package:equatable/equatable.dart';

/// Post entity representing a blog post or feed item
class Post extends Equatable {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.isFavorite = false,
    this.isOptimistic = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the post
  final int id;
  
  /// Post title
  final String title;
  
  /// Post content/body
  final String body;
  
  /// ID of the user who created this post
  final int userId;
  
  /// Whether this post is marked as favorite by the current user
  final bool isFavorite;
  
  /// Whether this is an optimistic post (created locally, not yet synced)
  final bool isOptimistic;
  
  /// When the post was created (optional)
  final DateTime? createdAt;
  
  /// When the post was last updated (optional)
  final DateTime? updatedAt;

  /// Get a preview of the post body (first 100 characters)
  String get bodyPreview {
    if (body.length <= 100) {
      return body;
    }
    return '${body.substring(0, 100)}...';
  }

  /// Check if this post has content
  bool get hasContent => title.isNotEmpty && body.isNotEmpty;

  /// Check if this post is valid for creation
  bool get isValidForCreation => 
      hasContent && title.trim().isNotEmpty && body.trim().isNotEmpty;

  /// Create a copy of this post with updated fields
  Post copyWith({
    int? id,
    String? title,
    String? body,
    int? userId,
    bool? isFavorite,
    bool? isOptimistic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
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
  Post toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  /// Mark this post as synced (no longer optimistic)
  Post markAsSynced({int? syncedId}) {
    return copyWith(
      id: syncedId ?? id,
      isOptimistic: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Create an optimistic post for immediate UI updates
  factory Post.optimistic({
    required String title,
    required String body,
    required int userId,
    int? tempId,
  }) {
    return Post(
      id: tempId ?? DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      userId: userId,
      isOptimistic: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        userId,
        isFavorite,
        isOptimistic,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Post(id: $id, title: $title, userId: $userId, isFavorite: $isFavorite, isOptimistic: $isOptimistic)';
  }
}
