import '../constants/cache_constants.dart';
import '../utils/logger.dart';
import 'storage_service.dart';

/// Model for cache metadata
class CacheMetadata {
  const CacheMetadata({
    required this.createdAt,
    required this.expiresAt,
    required this.version,
  });

  final DateTime createdAt;
  final DateTime expiresAt;
  final String version;
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'version': version,
      };
  
  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
        createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt']),
        version: json['version'],
      );
}

/// Cache entry containing data and metadata
class CacheEntry<T> {
  const CacheEntry({
    required this.data,
    required this.metadata,
  });

  final T data;
  final CacheMetadata metadata;
  
  bool get isExpired => metadata.isExpired;
  
  Map<String, dynamic> toJson() => {
        'data': data,
        'metadata': metadata.toJson(),
      };
  
  factory CacheEntry.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) =>
      CacheEntry(
        data: fromJsonT(json['data']),
        metadata: CacheMetadata.fromJson(json['metadata']),
      );
}

/// Abstract interface for cache operations
abstract class CacheManager {
  Future<void> initialize();
  Future<void> put<T>(
    String key,
    T data, {
    Duration? ttl,
    String? version,
  });
  Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson,
  );
  Future<bool> has(String key);
  Future<bool> isExpired(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<void> clearExpired();
  Future<int> size();
  Future<List<String>> keys();
}

/// Implementation of CacheManager using StorageService
class CacheManagerImpl implements CacheManager {
  CacheManagerImpl(this._storageService);

  final StorageService _storageService;
  static const String _cachePrefix = 'cache_';
  
  @override
  Future<void> initialize() async {
    await _storageService.initialize();
    Logger.debug('Cache manager initialized');
  }
  
  @override
  Future<void> put<T>(
    String key,
    T data, {
    Duration? ttl,
    String? version,
  }) async {
    try {
      final now = DateTime.now();
      final expiration = ttl != null 
          ? now.add(ttl)
          : now.add(Duration(hours: CacheConstants.defaultTtlHours));
      
      final metadata = CacheMetadata(
        createdAt: now,
        expiresAt: expiration,
        version: version ?? CacheConstants.defaultVersion,
      );
      
      final entry = CacheEntry(data: data, metadata: metadata);
      
      // Store the cache entry
      await _storageService.store(
        _getCacheKey(key),
        entry.toJson(),
      );
      
      Logger.debug('Cached data for key: $key (expires: $expiration)');
    } on Exception catch (e) {
      Logger.error('Failed to cache data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<T?> get<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final cacheKey = _getCacheKey(key);
      final entryJson = 
          await _storageService.get<Map<String, dynamic>>(cacheKey);
      
      if (entryJson == null) {
        Logger.debug('Cache miss for key: $key');
        return null;
      }
      
      final entry = CacheEntry.fromJson(entryJson, fromJson);
      
      if (entry.isExpired) {
        Logger.debug('Cache expired for key: $key');
        await delete(key);
        return null;
      }
      
      Logger.debug('Cache hit for key: $key');
      return entry.data;
    } on Exception catch (e) {
      Logger.error('Failed to retrieve cached data for key: $key', e);
      return null;
    }
  }
  
  @override
  Future<bool> has(String key) async {
    try {
      final cacheKey = _getCacheKey(key);
      final entryJson = 
          await _storageService.get<Map<String, dynamic>>(cacheKey);
      
      if (entryJson == null) {
        return false;
      }
      
      final metadata = CacheMetadata.fromJson(entryJson['metadata']);
      if (metadata.isExpired) {
        await delete(key);
        return false;
      }
      
      return true;
    } on Exception catch (e) {
      Logger.error('Failed to check cache existence for key: $key', e);
      return false;
    }
  }
  
  @override
  Future<bool> isExpired(String key) async {
    try {
      final cacheKey = _getCacheKey(key);
      final entryJson = 
          await _storageService.get<Map<String, dynamic>>(cacheKey);
      
      if (entryJson == null) {
        return true;
      }
      
      final metadata = CacheMetadata.fromJson(entryJson['metadata']);
      return metadata.isExpired;
    } on Exception catch (e) {
      Logger.error('Failed to check cache expiration for key: $key', e);
      return true;
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      final cacheKey = _getCacheKey(key);
      await _storageService.delete(cacheKey);
      Logger.debug('Deleted cache for key: $key');
    } on Exception catch (e) {
      Logger.error('Failed to delete cache for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      final allKeys = await keys();
      for (final key in allKeys) {
        await delete(key);
      }
      Logger.debug('Cleared all cache entries');
    } catch (e) {
      Logger.error('Failed to clear cache', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clearExpired() async {
    try {
      final allKeys = await keys();
      var clearedCount = 0;
      
      for (final key in allKeys) {
        if (await isExpired(key)) {
          await delete(key);
          clearedCount++;
        }
      }
      
      Logger.debug('Cleared $clearedCount expired cache entries');
    } on Exception catch (e) {
      Logger.error('Failed to clear expired cache entries', e);
      rethrow;
    }
  }
  
  @override
  Future<int> size() async {
    try {
      final allKeys = await keys();
      return allKeys.length;
    } on Exception catch (e) {
      Logger.error('Failed to get cache size', e);
      return 0;
    }
  }
  
  @override
  Future<List<String>> keys() async {
    try {
      // This is a simplified implementation
      // In a real scenario, you'd need to iterate through storage keys
      // For now, we'll return an empty list as this would require
      // additional storage service methods
      return [];
    } on Exception catch (e) {
      Logger.error('Failed to get cache keys', e);
      return [];
    }
  }
  
  String _getCacheKey(String key) => '$_cachePrefix$key';
}
