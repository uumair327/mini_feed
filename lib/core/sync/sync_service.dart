import 'dart:async';

import '../network/network_info.dart';
import '../storage/storage_service.dart';
import '../utils/logger.dart';

import '../../data/datasources/remote/post_remote_datasource.dart';
import '../../data/models/cached_post.dart';
import '../../data/models/post_model.dart';


/// Abstract interface for synchronization operations
abstract class SyncService {
  Future<void> initialize();
  Future<void> syncPendingChanges();
  Future<void> syncFavorites();
  Future<void> syncOptimisticPosts();
  Future<void> invalidateExpiredCache();
  Future<void> cleanupCache();
  void startAutoSync();
  void stopAutoSync();
  Stream<SyncStatus> get syncStatusStream;
}

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync result for tracking sync operations
class SyncResult {
  final bool success;
  final String? error;
  final int itemsSynced;
  final int itemsFailed;

  const SyncResult({
    required this.success,
    this.error,
    this.itemsSynced = 0,
    this.itemsFailed = 0,
  });

  factory SyncResult.success({int itemsSynced = 0}) => SyncResult(
        success: true,
        itemsSynced: itemsSynced,
      );

  factory SyncResult.failure(String error, {int itemsFailed = 0}) => SyncResult(
        success: false,
        error: error,
        itemsFailed: itemsFailed,
      );
}

/// Implementation of SyncService
class SyncServiceImpl implements SyncService {
  final NetworkInfo _networkInfo;
  final StorageService _storageService;
  final PostRemoteDataSource _postRemoteDataSource;

  final StreamController<SyncStatus> _syncStatusController =
      StreamController<SyncStatus>.broadcast();

  Timer? _autoSyncTimer;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isInitialized = false;
  bool _isSyncing = false;

  SyncServiceImpl({
    required NetworkInfo networkInfo,
    required StorageService storageService,
    required PostRemoteDataSource postRemoteDataSource,
  })  : _networkInfo = networkInfo,
        _storageService = storageService,
        _postRemoteDataSource = postRemoteDataSource;

  @override
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  @override
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.debug('Sync service already initialized');
      return;
    }

    try {
      await _storageService.initialize();

      // Listen to connectivity changes
      _connectivitySubscription = _networkInfo.connectivityStream.listen(
        (isConnected) {
          if (isConnected && !_isSyncing) {
            Logger.info('Connectivity restored, starting sync...');
            syncPendingChanges();
          }
        },
        onError: (error) {
          Logger.error('Connectivity stream error', error);
        },
      );

      _isInitialized = true;
      Logger.info('Sync service initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize sync service', e);
      rethrow;
    }
  }

  @override
  Future<void> syncPendingChanges() async {
    if (_isSyncing) {
      Logger.debug('Sync already in progress, skipping...');
      return;
    }

    if (!await _networkInfo.isConnected) {
      Logger.debug('No network connection, skipping sync');
      return;
    }

    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);

    try {
      Logger.info('Starting sync of pending changes...');

      // Sync in order of priority
      await syncOptimisticPosts();
      await syncFavorites();
      await invalidateExpiredCache();

      _syncStatusController.add(SyncStatus.success);
      Logger.info('Sync completed successfully');
    } catch (e) {
      Logger.error('Sync failed', e);
      _syncStatusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.idle);
    }
  }

  @override
  Future<void> syncOptimisticPosts() async {
    try {
      Logger.debug('Syncing optimistic posts...');

      final optimisticPosts = await _getOptimisticPosts();
      if (optimisticPosts.isEmpty) {
        Logger.debug('No optimistic posts to sync');
        return;
      }

      int synced = 0;
      int failed = 0;

      for (final cachedPost in optimisticPosts) {
        try {
          if (cachedPost.shouldRetrySync()) {
            final result = await _syncOptimisticPost(cachedPost);
            if (result.success) {
              synced++;
            } else {
              failed++;
            }
          }
        } catch (e) {
          Logger.error('Failed to sync optimistic post ${cachedPost.id}', e);
          failed++;
        }
      }

      Logger.info('Optimistic posts sync completed: $synced synced, $failed failed');
    } catch (e) {
      Logger.error('Failed to sync optimistic posts', e);
      rethrow;
    }
  }

  @override
  Future<void> syncFavorites() async {
    try {
      Logger.debug('Syncing favorites...');

      final pendingFavorites = await _getPendingFavorites();
      if (pendingFavorites.isEmpty) {
        Logger.debug('No pending favorites to sync');
        return;
      }

      int synced = 0;
      int failed = 0;

      for (final favorite in pendingFavorites) {
        try {
          final result = await _syncFavorite(favorite);
          if (result.success) {
            synced++;
          } else {
            failed++;
          }
        } catch (e) {
          Logger.error('Failed to sync favorite ${favorite['postId']}', e);
          failed++;
        }
      }

      Logger.info('Favorites sync completed: $synced synced, $failed failed');
    } catch (e) {
      Logger.error('Failed to sync favorites', e);
      rethrow;
    }
  }

  @override
  Future<void> invalidateExpiredCache() async {
    try {
      Logger.debug('Invalidating expired cache...');

      final expiredKeys = await _getExpiredCacheKeys();
      int invalidated = 0;

      for (final key in expiredKeys) {
        try {
          await _storageService.delete(key);
          invalidated++;
        } catch (e) {
          Logger.error('Failed to invalidate cache key: $key', e);
        }
      }

      Logger.info('Cache invalidation completed: $invalidated items removed');
    } catch (e) {
      Logger.error('Failed to invalidate expired cache', e);
      rethrow;
    }
  }

  @override
  Future<void> cleanupCache() async {
    try {
      Logger.debug('Cleaning up cache...');

      // Remove old cache entries
      await invalidateExpiredCache();

      // Clean up orphaned data
      await _cleanupOrphanedData();

      // Compact cache if needed
      await _compactCache();

      Logger.info('Cache cleanup completed');
    } catch (e) {
      Logger.error('Failed to cleanup cache', e);
      rethrow;
    }
  }

  @override
  void startAutoSync() {
    if (_autoSyncTimer != null) {
      Logger.debug('Auto sync already started');
      return;
    }

    // Sync every 5 minutes
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!_isSyncing) {
        syncPendingChanges();
      }
    });

    Logger.info('Auto sync started (5 minute interval)');
  }

  @override
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    Logger.info('Auto sync stopped');
  }

  // Private helper methods

  Future<List<CachedPost>> _getOptimisticPosts() async {
    try {
      final optimisticPosts = <CachedPost>[];

      // This is a simplified implementation
      // In a real app, you'd have a more efficient way to track optimistic posts
      for (int i = -1000; i < 0; i++) {
        final postData = await _storageService.get<String>('post_$i');
        if (postData != null) {
          try {
            final postModel = PostModel.fromJsonString(postData);
            if (postModel.isOptimistic) {
              final cachedPost = CachedPost.fromModel(
                postModel,
                needsSync: true,
              );
              optimisticPosts.add(cachedPost);
            }
          } catch (e) {
            Logger.error('Failed to parse optimistic post $i', e);
          }
        }
      }

      return optimisticPosts;
    } catch (e) {
      Logger.error('Failed to get optimistic posts', e);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getPendingFavorites() async {
    try {
      final pendingFavorites = <Map<String, dynamic>>[];

      // Get pending favorites from storage
      final pendingFavoritesData = await _storageService.get<String>('pending_favorites');
      if (pendingFavoritesData != null) {
        // Parse pending favorites (simplified implementation)
        // In a real app, you'd have a more structured approach
      }

      return pendingFavorites;
    } catch (e) {
      Logger.error('Failed to get pending favorites', e);
      return [];
    }
  }

  Future<SyncResult> _syncOptimisticPost(CachedPost cachedPost) async {
    try {
      Logger.debug('Syncing optimistic post: ${cachedPost.id}');

      // Create the post on the server
      final result = await _postRemoteDataSource.createPost(
        title: cachedPost.title,
        body: cachedPost.body,
        userId: cachedPost.userId,
      );

      return result.fold(
        (failure) async {
          // Mark as failed and increment retry count
          final updatedPost = cachedPost.markForSync(error: failure.toString());
          await _updateCachedPost(updatedPost);
          return SyncResult.failure(failure.toString());
        },
        (createdPost) async {
          // Replace optimistic post with real post
          await _storageService.delete('post_${cachedPost.id}');
          await _storageService.store('post_${createdPost.id}', createdPost.toJsonString());

          Logger.info('Successfully synced optimistic post ${cachedPost.id} -> ${createdPost.id}');
          return SyncResult.success(itemsSynced: 1);
        },
      );


    } catch (e) {
      Logger.error('Failed to sync optimistic post ${cachedPost.id}', e);
      
      // Mark as failed
      final updatedPost = cachedPost.markForSync(error: e.toString());
      await _updateCachedPost(updatedPost);
      
      return SyncResult.failure(e.toString());
    }
  }

  Future<SyncResult> _syncFavorite(Map<String, dynamic> favorite) async {
    try {
      // In a real app, you'd sync favorites with the server
      // For this demo, we'll just mark them as synced locally
      Logger.debug('Syncing favorite: ${favorite['postId']}');
      
      // Remove from pending favorites
      await _removePendingFavorite(favorite);
      
      return SyncResult.success(itemsSynced: 1);
    } catch (e) {
      Logger.error('Failed to sync favorite ${favorite['postId']}', e);
      return SyncResult.failure(e.toString());
    }
  }

  Future<List<String>> _getExpiredCacheKeys() async {
    try {
      final expiredKeys = <String>[];
      final now = DateTime.now();

      // Check posts cache
      for (int i = 1; i <= 1000; i++) {
        final cacheKey = 'post_$i';
        final postData = await _storageService.get<String>(cacheKey);
        if (postData != null) {
          try {
            final postModel = PostModel.fromJsonString(postData);
            if (postModel.createdAt != null) {
              final age = now.difference(postModel.createdAt!);
              if (age > const Duration(hours: 24)) {
                expiredKeys.add(cacheKey);
              }
            }
          } catch (e) {
            // If we can't parse it, consider it expired
            expiredKeys.add(cacheKey);
          }
        }
      }

      return expiredKeys;
    } catch (e) {
      Logger.error('Failed to get expired cache keys', e);
      return [];
    }
  }

  Future<void> _cleanupOrphanedData() async {
    try {
      // Clean up orphaned comments, favorites, etc.
      // This is a simplified implementation
      Logger.debug('Cleaning up orphaned data...');
    } catch (e) {
      Logger.error('Failed to cleanup orphaned data', e);
    }
  }

  Future<void> _compactCache() async {
    try {
      // Compact cache by removing duplicates, optimizing storage, etc.
      // This is a simplified implementation
      Logger.debug('Compacting cache...');
    } catch (e) {
      Logger.error('Failed to compact cache', e);
    }
  }

  Future<void> _updateCachedPost(CachedPost cachedPost) async {
    try {
      final postModel = cachedPost.toModel();
      await _storageService.store('post_${cachedPost.id}', postModel.toJsonString());
    } catch (e) {
      Logger.error('Failed to update cached post ${cachedPost.id}', e);
    }
  }

  Future<void> _removePendingFavorite(Map<String, dynamic> favorite) async {
    try {
      // Remove from pending favorites list
      // This is a simplified implementation
      Logger.debug('Removing pending favorite: ${favorite['postId']}');
    } catch (e) {
      Logger.error('Failed to remove pending favorite', e);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    _syncStatusController.close();
    Logger.debug('Sync service disposed');
  }
}