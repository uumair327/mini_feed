import 'package:hive/hive.dart';

part 'favorite_post.g.dart';

/// Hive model for storing favorite posts
/// 
/// This model stores the relationship between users and their favorite posts
/// for quick lookup and offline access.
@HiveType(typeId: 1)
class FavoritePost extends HiveObject {
  @HiveField(0)
  final int postId;

  @HiveField(1)
  final int userId;

  @HiveField(2)
  final DateTime favoriteAt;

  @HiveField(3)
  final bool needsSync;

  @HiveField(4)
  final String? syncError;

  @HiveField(5)
  final int syncAttempts;

  FavoritePost({
    required this.postId,
    required this.userId,
    DateTime? favoriteAt,
    this.needsSync = false,
    this.syncError,
    this.syncAttempts = 0,
  }) : favoriteAt = favoriteAt ?? DateTime.now();

  /// Create a copy with updated fields
  FavoritePost copyWith({
    int? postId,
    int? userId,
    DateTime? favoriteAt,
    bool? needsSync,
    String? syncError,
    int? syncAttempts,
  }) {
    return FavoritePost(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      favoriteAt: favoriteAt ?? this.favoriteAt,
      needsSync: needsSync ?? this.needsSync,
      syncError: syncError ?? this.syncError,
      syncAttempts: syncAttempts ?? this.syncAttempts,
    );
  }

  /// Mark as needing sync
  FavoritePost markForSync({String? error}) {
    return copyWith(
      needsSync: true,
      syncError: error,
      syncAttempts: error != null ? syncAttempts + 1 : syncAttempts,
    );
  }

  /// Mark as synced successfully
  FavoritePost markAsSynced() {
    return FavoritePost(
      postId: postId,
      userId: userId,
      favoriteAt: favoriteAt,
      needsSync: false,
      syncError: null,
      syncAttempts: 0,
    );
  }

  /// Check if sync should be retried
  bool shouldRetrySync({int maxAttempts = 3}) {
    return needsSync && syncAttempts < maxAttempts;
  }

  /// Get unique key for this favorite relationship
  String get uniqueKey => '${userId}_$postId';

  /// Create from user and post IDs
  factory FavoritePost.create({
    required int postId,
    required int userId,
    bool needsSync = true,
  }) {
    return FavoritePost(
      postId: postId,
      userId: userId,
      needsSync: needsSync,
    );
  }

  @override
  String toString() {
    return 'FavoritePost(postId: $postId, userId: $userId, '
           'favoriteAt: $favoriteAt, needsSync: $needsSync)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoritePost &&
        other.postId == postId &&
        other.userId == userId &&
        other.favoriteAt == favoriteAt &&
        other.needsSync == needsSync &&
        other.syncError == syncError &&
        other.syncAttempts == syncAttempts;
  }

  @override
  int get hashCode {
    return Object.hash(
      postId,
      userId,
      favoriteAt,
      needsSync,
      syncError,
      syncAttempts,
    );
  }
}