import 'package:hive/hive.dart';
import '../../domain/entities/comment.dart';
import 'comment_model.dart';

part 'cached_comment.g.dart';

/// Hive model for caching comments locally
/// 
/// This model is used to store comments in Hive database for offline access
/// and improved performance. It includes cache metadata for managing
/// expiration and synchronization status.
@HiveType(typeId: 3)
class CachedComment extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int postId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String body;

  @HiveField(5)
  final DateTime? createdAt;

  @HiveField(6)
  final DateTime? updatedAt;

  @HiveField(7)
  final DateTime cachedAt;

  @HiveField(8)
  final bool needsSync;

  @HiveField(9)
  final String? syncError;

  @HiveField(10)
  final int syncAttempts;

  CachedComment({
    required this.id,
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
    this.createdAt,
    this.updatedAt,
    DateTime? cachedAt,
    this.needsSync = false,
    this.syncError,
    this.syncAttempts = 0,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Convert to domain Comment entity
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

  /// Convert to CommentModel
  CommentModel toModel() {
    return CommentModel(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from domain Comment entity
  factory CachedComment.fromDomain(Comment comment, {
    bool needsSync = false,
    String? syncError,
    int syncAttempts = 0,
  }) {
    return CachedComment(
      id: comment.id,
      postId: comment.postId,
      name: comment.name,
      email: comment.email,
      body: comment.body,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      needsSync: needsSync,
      syncError: syncError,
      syncAttempts: syncAttempts,
    );
  }

  /// Create from CommentModel
  factory CachedComment.fromModel(CommentModel model, {
    bool needsSync = false,
    String? syncError,
    int syncAttempts = 0,
  }) {
    return CachedComment(
      id: model.id,
      postId: model.postId,
      name: model.name,
      email: model.email,
      body: model.body,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      needsSync: needsSync,
      syncError: syncError,
      syncAttempts: syncAttempts,
    );
  }

  /// Check if cache entry is expired
  bool isExpired(Duration maxAge) {
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    return age > maxAge;
  }

  /// Check if cache entry is stale (needs refresh)
  bool isStale(Duration staleThreshold) {
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    return age > staleThreshold;
  }

  /// Create a copy with updated fields
  CachedComment copyWith({
    int? id,
    int? postId,
    String? name,
    String? email,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? needsSync,
    String? syncError,
    int? syncAttempts,
  }) {
    return CachedComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      name: name ?? this.name,
      email: email ?? this.email,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      needsSync: needsSync ?? this.needsSync,
      syncError: syncError ?? this.syncError,
      syncAttempts: syncAttempts ?? this.syncAttempts,
    );
  }

  /// Mark as needing sync
  CachedComment markForSync({String? error}) {
    return copyWith(
      needsSync: true,
      syncError: error,
      syncAttempts: error != null ? syncAttempts + 1 : syncAttempts,
    );
  }

  /// Mark as synced successfully
  CachedComment markAsSynced() {
    return CachedComment(
      id: id,
      postId: postId,
      name: name,
      email: email,
      body: body,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cachedAt: DateTime.now(),
      needsSync: false,
      syncError: null,
      syncAttempts: 0,
    );
  }

  /// Update cache timestamp
  CachedComment refreshCache() {
    return copyWith(cachedAt: DateTime.now());
  }

  /// Check if sync should be retried
  bool shouldRetrySync({int maxAttempts = 3}) {
    return needsSync && syncAttempts < maxAttempts;
  }

  /// Get cache age in minutes
  int get cacheAgeInMinutes {
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    return age.inMinutes;
  }

  /// Get cache age in hours
  int get cacheAgeInHours {
    final now = DateTime.now();
    final age = now.difference(cachedAt);
    return age.inHours;
  }

  @override
  String toString() {
    return 'CachedComment(id: $id, postId: $postId, name: $name, '
           'needsSync: $needsSync, cacheAge: ${cacheAgeInMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedComment &&
        other.id == id &&
        other.postId == postId &&
        other.name == name &&
        other.email == email &&
        other.body == body &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.cachedAt == cachedAt &&
        other.needsSync == needsSync &&
        other.syncError == syncError &&
        other.syncAttempts == syncAttempts;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      postId,
      name,
      email,
      body,
      createdAt,
      updatedAt,
      cachedAt,
      needsSync,
      syncError,
      syncAttempts,
    );
  }
}