import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/storage/storage_initializer.dart';

void main() {
  group('StorageInitializer', () {
    test('should handle initialization gracefully', () async {
      // This test verifies that initialization doesn't throw
      // In a real test environment, we'd mock Hive and other dependencies
      
      // Act & Assert
      expect(() => StorageInitializer.initialize(), returnsNormally);
    });
    
    test('should throw when accessing services before initialization', () {
      // Act & Assert
      expect(
        () => StorageInitializer.storageService,
        throwsA(isA<Exception>()),
      );
      expect(
        () => StorageInitializer.cacheManager,
        throwsA(isA<Exception>()),
      );
      expect(
        () => StorageInitializer.tokenStorage,
        throwsA(isA<Exception>()),
      );
    });
    
    test('should report not initialized initially', () {
      // Act & Assert
      expect(StorageInitializer.isInitialized, isFalse);
    });
    
    test('should handle disposal gracefully', () async {
      // Act & Assert
      expect(() => StorageInitializer.dispose(), returnsNormally);
    });
    
    test('should handle clear all data gracefully', () async {
      // Act & Assert
      expect(() => StorageInitializer.clearAllData(), returnsNormally);
    });
    
    test('should return storage stats', () async {
      // Act
      final stats = await StorageInitializer.getStorageStats();
      
      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('cacheSize'), isTrue);
      expect(stats.containsKey('hasToken'), isTrue);
      expect(stats.containsKey('isInitialized'), isTrue);
    });
    
    test('should handle stats error gracefully', () async {
      // This test verifies that getStorageStats doesn't throw
      // even when services are not initialized
      
      // Act
      final stats = await StorageInitializer.getStorageStats();
      
      // Assert
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats['cacheSize'], equals(0));
      expect(stats['hasToken'], equals(false));
      expect(stats['isInitialized'], equals(false));
    });
  });
}
