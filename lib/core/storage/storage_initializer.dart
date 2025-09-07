import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import 'cache_manager.dart';
import 'storage_service.dart';
import 'token_storage.dart';

/// Utility class for initializing all storage services
class StorageInitializer {
  static StorageService? _storageService;
  static CacheManager? _cacheManager;
  static TokenStorage? _tokenStorage;
  static bool _isInitialized = false;
  
  /// Initialize all storage services
  static Future<void> initialize() async {
    if (_isInitialized) {
      Logger.debug('Storage services already initialized, skipping...');
      return;
    }
    
    try {
      Logger.debug('Initializing storage services...');
      
      // Initialize Hive only once
      await Hive.initFlutter();
      Logger.debug('Hive initialized');
      
      // Initialize storage service
      _storageService = StorageServiceImpl();
      await _storageService!.initialize();
      Logger.debug('Storage service initialized');
      
      // Initialize cache manager
      _cacheManager = CacheManagerImpl(_storageService!);
      await _cacheManager!.initialize();
      Logger.debug('Cache manager initialized');
      
      // Initialize token storage
      _tokenStorage = TokenStorageImpl(_storageService!);
      Logger.debug('Token storage initialized');
      
      // Clean up expired cache entries on startup
      await _cacheManager!.clearExpired();
      
      _isInitialized = true;
      Logger.debug('All storage services initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize storage services', e);
      rethrow;
    }
  }
  
  /// Get the storage service instance
  static StorageService get storageService {
    if (_storageService == null) {
      throw Exception(
        'StorageService not initialized. Call initialize() first.',
      );
    }
    return _storageService!;
  }
  
  /// Get the cache manager instance
  static CacheManager get cacheManager {
    if (_cacheManager == null) {
      throw Exception('CacheManager not initialized. Call initialize() first.');
    }
    return _cacheManager!;
  }
  
  /// Get the token storage instance
  static TokenStorage get tokenStorage {
    if (_tokenStorage == null) {
      throw Exception('TokenStorage not initialized. Call initialize() first.');
    }
    return _tokenStorage!;
  }
  
  /// Dispose all storage services
  static Future<void> dispose() async {
    try {
      await _storageService?.dispose();
      _storageService = null;
      _cacheManager = null;
      _tokenStorage = null;
      _isInitialized = false;
      
      Logger.debug('All storage services disposed');
    } on Exception catch (e) {
      Logger.error('Failed to dispose storage services', e);
    }
  }
  
  /// Check if storage services are initialized
  static bool get isInitialized => _isInitialized;
  
  /// Clear all storage data (useful for testing or logout)
  static Future<void> clearAllData() async {
    try {
      await _storageService?.clear();
      await _tokenStorage?.clearAllTokens();
      await _cacheManager?.clear();
      
      Logger.debug('All storage data cleared');
    } catch (e) {
      Logger.error('Failed to clear all storage data', e);
      rethrow;
    }
  }
  
  /// Get storage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final cacheSize = await _cacheManager?.size() ?? 0;
      final hasToken = await _tokenStorage?.hasToken() ?? false;
      
      return {
        'cacheSize': cacheSize,
        'hasToken': hasToken,
        'isInitialized': isInitialized,
      };
    } on Exception catch (e) {
      Logger.error('Failed to get storage statistics', e);
      return {
        'cacheSize': 0,
        'hasToken': false,
        'isInitialized': false,
        'error': e.toString(),
      };
    }
  }
}
