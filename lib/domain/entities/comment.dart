import 'package:equatable/equatable.dart';

/// Comment entity representing a comment on a post
class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the comment
  final int id;
  
  /// ID of the post this comment belongs to
  final int postId;
  
  /// Name of the commenter
  final String name;
  
  /// Email of the commenter
  final String email;
  
  /// Comment content/body
  final String body;
  
  /// When the comment was created (optional)
  final DateTime? createdAt;
  
  /// When the comment was last updated (optional)
  final DateTime? updatedAt;

  /// Get a preview of the comment body (first 80 characters)
  String get bodyPreview {
    if (body.length <= 80) {
      return body;
    }
    return '${body.substring(0, 80)}...';
  }

  /// Check if this comment has valid content
  bool get hasValidContent => 
      name.isNotEmpty && 
      email.isNotEmpty && 
      body.isNotEmpty &&
      email.contains('@');

  /// Get commenter initials for avatar display
  String get commenterInitials {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';
    
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '?';
    }
    
    final firstInitial = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
    final lastInitial = nameParts[nameParts.length - 1].isNotEmpty 
        ? nameParts[nameParts.length - 1][0] 
        : '';
    
    return (firstInitial + lastInitial).toUpperCase();
  }

  /// Get formatted commenter info (name and email)
  String get commenterInfo => '$name ($email)';

  /// Create a copy of this comment with updated fields
  Comment copyWith({
    int? id,
    int? postId,
    String? name,
    String? email,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
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
  factory Comment.forPost({
    required int id,
    required int postId,
    required String name,
    required String email,
    required String body,
  }) {
    return Comment(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        name,
        email,
        body,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Comment(id: $id, postId: $postId, name: $name, email: $email)';
  }
}
