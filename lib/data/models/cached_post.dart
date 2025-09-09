import 'package:hive/hive.dart';
import '../../domain/entities/post.dart';
import 'post_model.dart';

part 'cached_post.g.dart';

/// Hive model for caching posts locally
/// 
/// This model is used to store posts in Hive database for offline access
/// and improved performance. It includes cache metadata for managing
/// expiration and synchronization status.
@HiveType(typeId: 0)
class CachedPost extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final int userId;

  @HiveField(4)
  final bool isFavorite;

  @HiveField(5)
  final bool isOptimistic;

  @HiveField(6)
  final DateTime? createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  @HiveField(8)
  final DateTime cachedAt;

  @HiveField(9)
  final bool needsSync;

  @HiveField(10)
  final String? syncError;

  @HiveField(11)
  final int syncAttempts;

  CachedPost({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
    this.isFavorite = false,
    this.isOptimistic = false,
    this.createdAt,
    this.updatedAt,
    DateTime? cachedAt,
    this.needsSync = false,
    this.syncError,
    this.syncAttempts = 0,
  }) : cachedAt = cachedAt ?? DateTime.now();

  /// Convert to domain Post entity
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

  /// Convert to PostModel
  PostModel toModel() {
    return PostModel(
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

  /// Create from domain Post entity
  factory CachedPost.fromDomain(Post post, {
    bool needsSync = false,
    String? syncError,
    int syncAttempts = 0,
  }) {
    return CachedPost(
      id: post.id,
      title: post.title,
      body: post.body,
      userId: post.userId,
      isFavorite: post.isFavorite,
      isOptimistic: post.isOptimistic,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt,
      needsSync: needsSync,
      syncError: syncError,
      syncAttempts: syncAttempts,
    );
  }

  /// Create from PostModel
  factory CachedPost.fromModel(PostModel model, {
    bool needsSync = false,
    String? syncError,
    int syncAttempts = 0,
  }) {
    return CachedPost(
      id: model.id,
      title: model.title,
      body: model.body,
      userId: model.userId,
      isFavorite: model.isFavorite,
      isOptimistic: model.isOptimistic,
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
  CachedPost copyWith({
    int? id,
    String? title,
    String? body,
    int? userId,
    bool? isFavorite,
    bool? isOptimistic,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? cachedAt,
    bool? needsSync,
    String? syncError,
    int? syncAttempts,
  }) {
    return CachedPost(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      needsSync: needsSync ?? this.needsSync,
      syncError: syncError ?? this.syncError,
      syncAttempts: syncAttempts ?? this.syncAttempts,
    );
  }

  /// Mark as needing sync
  CachedPost markForSync({String? error}) {
    return copyWith(
      needsSync: true,
      syncError: error,
      syncAttempts: error != null ? syncAttempts + 1 : syncAttempts,
    );
  }

  /// Mark as synced successfully
  CachedPost markAsSynced() {
    return CachedPost(
      id: id,
      title: title,
      body: body,
      userId: userId,
      isFavorite: isFavorite,
      isOptimistic: isOptimistic,
      createdAt: createdAt,
      updatedAt: updatedAt,
      cachedAt: DateTime.now(),
      needsSync: false,
      syncError: null,
      syncAttempts: 0,
    );
  }

  /// Toggle favorite status
  CachedPost toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      needsSync: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Update cache timestamp
  CachedPost refreshCache() {
    return copyWith(cachedAt: DateTime.now());
  }

  /// Check if sync should be retried
  bool shouldRetrySync({int maxAttempts = 3}) {
    if (!needsSync) return false;
    if (syncAttempts >= maxAttempts) return false;
    
    // Don't retry if the last attempt was too recent (less than 5 minutes ago)
    if (syncError != null && cacheAgeInMinutes < 5) {
      return false;
    }
    
    return true;
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
    return 'CachedPost(id: $id, title: $title, isFavorite: $isFavorite, '
           'isOptimistic: $isOptimistic, needsSync: $needsSync, '
           'cacheAge: ${cacheAgeInMinutes}min)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedPost &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.userId == userId &&
        other.isFavorite == isFavorite &&
        other.isOptimistic == isOptimistic &&
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
      title,
      body,
      userId,
      isFavorite,
      isOptimistic,
      createdAt,
      updatedAt,
      cachedAt,
      needsSync,
      syncError,
      syncAttempts,
    );
  }
}