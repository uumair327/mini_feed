import 'package:hive/hive.dart';

part 'cache_metadata.g.dart';

/// Hive model for cache metadata
/// 
/// This model stores metadata about cached data including expiration times,
/// sync status, and cache statistics for efficient cache management.
@HiveType(typeId: 2)
class CacheMetadata extends HiveObject {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String dataType;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final DateTime lastAccessedAt;

  @HiveField(4)
  final DateTime? expiresAt;

  @HiveField(5)
  final int accessCount;

  @HiveField(6)
  final int sizeInBytes;

  @HiveField(7)
  final Map<String, dynamic> tags;

  @HiveField(8)
  final bool isPersistent;

  @HiveField(9)
  final int version;

  CacheMetadata({
    required this.key,
    required this.dataType,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    this.expiresAt,
    this.accessCount = 0,
    this.sizeInBytes = 0,
    Map<String, dynamic>? tags,
    this.isPersistent = false,
    this.version = 1,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastAccessedAt = lastAccessedAt ?? DateTime.now(),
       tags = tags ?? {};

  /// Check if cache entry is expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if cache entry is stale (should be refreshed)
  bool isStale(Duration staleThreshold) {
    final now = DateTime.now();
    final age = now.difference(lastAccessedAt);
    return age > staleThreshold;
  }

  /// Get cache age
  Duration get age {
    return DateTime.now().difference(createdAt);
  }

  /// Get time since last access
  Duration get timeSinceLastAccess {
    return DateTime.now().difference(lastAccessedAt);
  }

  /// Create a copy with updated fields
  CacheMetadata copyWith({
    String? key,
    String? dataType,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
    DateTime? expiresAt,
    int? accessCount,
    int? sizeInBytes,
    Map<String, dynamic>? tags,
    bool? isPersistent,
    int? version,
  }) {
    return CacheMetadata(
      key: key ?? this.key,
      dataType: dataType ?? this.dataType,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      accessCount: accessCount ?? this.accessCount,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      tags: tags ?? Map<String, dynamic>.from(this.tags),
      isPersistent: isPersistent ?? this.isPersistent,
      version: version ?? this.version,
    );
  }

  /// Update access information
  CacheMetadata updateAccess() {
    return copyWith(
      lastAccessedAt: DateTime.now(),
      accessCount: accessCount + 1,
    );
  }

  /// Update expiration time
  CacheMetadata updateExpiration(DateTime newExpiresAt) {
    return copyWith(expiresAt: newExpiresAt);
  }

  /// Add or update a tag
  CacheMetadata addTag(String key, dynamic value) {
    final newTags = Map<String, dynamic>.from(tags);
    newTags[key] = value;
    return copyWith(tags: newTags);
  }

  /// Remove a tag
  CacheMetadata removeTag(String key) {
    final newTags = Map<String, dynamic>.from(tags);
    newTags.remove(key);
    return copyWith(tags: newTags);
  }

  /// Check if has specific tag
  bool hasTag(String key) {
    return tags.containsKey(key);
  }

  /// Get tag value
  T? getTag<T>(String key) {
    return tags[key] as T?;
  }

  /// Create for posts cache
  factory CacheMetadata.forPosts({
    required String key,
    Duration? maxAge,
    Map<String, dynamic>? tags,
    bool isPersistent = false,
  }) {
    return CacheMetadata(
      key: key,
      dataType: 'posts',
      expiresAt: maxAge != null ? DateTime.now().add(maxAge) : null,
      tags: tags,
      isPersistent: isPersistent,
    );
  }

  /// Create for comments cache
  factory CacheMetadata.forComments({
    required String key,
    Duration? maxAge,
    Map<String, dynamic>? tags,
    bool isPersistent = false,
  }) {
    return CacheMetadata(
      key: key,
      dataType: 'comments',
      expiresAt: maxAge != null ? DateTime.now().add(maxAge) : null,
      tags: tags,
      isPersistent: isPersistent,
    );
  }

  /// Create for users cache
  factory CacheMetadata.forUsers({
    required String key,
    Duration? maxAge,
    Map<String, dynamic>? tags,
    bool isPersistent = false,
  }) {
    return CacheMetadata(
      key: key,
      dataType: 'users',
      expiresAt: maxAge != null ? DateTime.now().add(maxAge) : null,
      tags: tags,
      isPersistent: isPersistent,
    );
  }

  /// Create for search results cache
  factory CacheMetadata.forSearch({
    required String key,
    required String query,
    Duration? maxAge,
    bool isPersistent = false,
  }) {
    return CacheMetadata(
      key: key,
      dataType: 'search',
      expiresAt: maxAge != null ? DateTime.now().add(maxAge) : null,
      tags: {'query': query},
      isPersistent: isPersistent,
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'key': key,
      'dataType': dataType,
      'age': age.inMinutes,
      'timeSinceLastAccess': timeSinceLastAccess.inMinutes,
      'accessCount': accessCount,
      'sizeInBytes': sizeInBytes,
      'isExpired': isExpired,
      'isPersistent': isPersistent,
      'version': version,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'CacheMetadata(key: $key, dataType: $dataType, '
           'age: ${age.inMinutes}min, accessCount: $accessCount, '
           'isExpired: $isExpired)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheMetadata &&
        other.key == key &&
        other.dataType == dataType &&
        other.createdAt == createdAt &&
        other.lastAccessedAt == lastAccessedAt &&
        other.expiresAt == expiresAt &&
        other.accessCount == accessCount &&
        other.sizeInBytes == sizeInBytes &&
        other.isPersistent == isPersistent &&
        other.version == version;
  }

  @override
  int get hashCode {
    return Object.hash(
      key,
      dataType,
      createdAt,
      lastAccessedAt,
      expiresAt,
      accessCount,
      sizeInBytes,
      isPersistent,
      version,
    );
  }
}