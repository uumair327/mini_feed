import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../utils/logger.dart';

/// Abstract interface for storage operations
abstract class StorageService {
  Future<void> initialize();
  Future<void> storeSecure(String key, String value);
  Future<String?> getSecure(String key);
  Future<void> deleteSecure(String key);
  Future<void> clearSecure();
  Future<void> store(String key, dynamic value);
  Future<T?> get<T>(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<void> dispose();
}

/// Implementation of StorageService using Hive and FlutterSecureStorage
class StorageServiceImpl implements StorageService {
  static const String _generalBoxName = 'mini_feed_general';
  
  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;
  Box? _generalBox;

  StorageServiceImpl() {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }
  
  @override
  Future<void> initialize() async {
    try {
      Logger.debug('Initializing storage services...');
      
      // Initialize Hive
      await Hive.initFlutter();
      
      // Open general storage box
      _generalBox = await Hive.openBox(_generalBoxName);
      
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      Logger.debug('Storage services initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize storage services', e);
      rethrow;
    }
  }
  
  @override
  Future<void> storeSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      Logger.debug('Stored secure data for key: $key');
    } on Exception catch (e) {
      Logger.error('Failed to store secure data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<String?> getSecure(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      Logger.debug('Retrieved secure data for key: $key');
      return value;
    } catch (e) {
      Logger.error('Failed to retrieve secure data for key: $key', e);
      return null;
    }
  }
  
  @override
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      Logger.debug('Deleted secure data for key: $key');
    } catch (e) {
      Logger.error('Failed to delete secure data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
      Logger.debug('Cleared all secure storage');
    } catch (e) {
      Logger.error('Failed to clear secure storage', e);
      rethrow;
    }
  }
  
  @override
  Future<void> store(String key, dynamic value) async {
    try {
      if (_generalBox == null) {
        throw Exception('Storage not initialized');
      }
      
      // Store in Hive for complex objects
      if (value is Map || value is List) {
        await _generalBox!.put(key, value);
      } else {
        // Store in SharedPreferences for simple types
        if (value is String) {
          await _prefs.setString(key, value);
        } else if (value is int) {
          await _prefs.setInt(key, value);
        } else if (value is double) {
          await _prefs.setDouble(key, value);
        } else if (value is bool) {
          await _prefs.setBool(key, value);
        } else if (value is List<String>) {
          await _prefs.setStringList(key, value);
        } else {
          // Fallback to JSON string for other types
          await _prefs.setString(key, jsonEncode(value));
        }
      }
      
      Logger.debug('Stored data for key: $key');
    } on Exception catch (e) {
      Logger.error('Failed to store data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<T?> get<T>(String key) async {
    try {
      if (_generalBox == null) {
        throw Exception('Storage not initialized');
      }
      
      // Try Hive first
      final hiveValue = _generalBox!.get(key);
      if (hiveValue != null) {
        Logger.debug('Retrieved data from Hive for key: $key');
        return hiveValue as T?;
      }
      
      // Fallback to SharedPreferences
      final prefsValue = _prefs.get(key);
      if (prefsValue != null) {
        Logger.debug('Retrieved data from SharedPreferences for key: $key');
        return prefsValue as T?;
      }
      
      return null;
    } catch (e) {
      Logger.error('Failed to retrieve data for key: $key', e);
      return null;
    }
  }
  
  @override
  Future<void> delete(String key) async {
    try {
      if (_generalBox == null) {
        throw Exception('Storage not initialized');
      }
      
      // Delete from both storages
      await _generalBox!.delete(key);
      await _prefs.remove(key);
      
      Logger.debug('Deleted data for key: $key');
    } catch (e) {
      Logger.error('Failed to delete data for key: $key', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      if (_generalBox == null) {
        throw Exception('Storage not initialized');
      }
      
      // Clear both storages
      await _generalBox!.clear();
      await _prefs.clear();
      
      Logger.debug('Cleared all general storage');
    } on Exception catch (e) {
      Logger.error('Failed to clear general storage', e);
      rethrow;
    }
  }
  
  @override
  Future<void> dispose() async {
    try {
      await _generalBox?.close();
      await Hive.close();
      Logger.debug('Storage services disposed');
    } catch (e) {
      Logger.error('Failed to dispose storage services', e);
    }
  }
}
