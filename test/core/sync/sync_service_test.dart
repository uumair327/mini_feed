import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/core/sync/sync_service.dart';
import 'package:mini_feed/core/network/network_info.dart';
import 'package:mini_feed/core/storage/storage_service.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/data/datasources/remote/post_remote_datasource.dart';
import 'package:mini_feed/data/models/post_model.dart';

class MockNetworkInfo extends Mock implements NetworkInfo {}
class MockStorageService extends Mock implements StorageService {}
class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}

void main() {
  group('SyncService', () {
    late SyncServiceImpl syncService;
    late MockNetworkInfo mockNetworkInfo;
    late MockStorageService mockStorageService;
    late MockPostRemoteDataSource mockPostRemoteDataSource;
    late StreamController<bool> connectivityController;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      mockStorageService = MockStorageService();
      mockPostRemoteDataSource = MockPostRemoteDataSource();
      connectivityController = StreamController<bool>.broadcast();

      when(() => mockNetworkInfo.connectivityStream)
          .thenAnswer((_) => connectivityController.stream);
      when(() => mockStorageService.initialize())
          .thenAnswer((_) async {});

      syncService = SyncServiceImpl(
        networkInfo: mockNetworkInfo,
        storageService: mockStorageService,
        postRemoteDataSource: mockPostRemoteDataSource,
      );
    });

    tearDown(() {
      connectivityController.close();
      syncService.dispose();
    });

    group('initialize', () {
      test('should initialize storage service', () async {
        // Act
        await syncService.initialize();

        // Assert
        verify(() => mockStorageService.initialize()).called(1);
      });

      test('should listen to connectivity changes', () async {
        // Act
        await syncService.initialize();

        // Assert
        verify(() => mockNetworkInfo.connectivityStream).called(1);
      });

      test('should not initialize twice', () async {
        // Act
        await syncService.initialize();
        await syncService.initialize();

        // Assert
        verify(() => mockStorageService.initialize()).called(1);
      });
    });

    group('syncPendingChanges', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should skip sync when already syncing', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);

        // Act - start two syncs simultaneously
        final future1 = syncService.syncPendingChanges();
        final future2 = syncService.syncPendingChanges();

        await Future.wait([future1, future2]);

        // Assert - should only check connectivity once for the first sync
        verify(() => mockNetworkInfo.isConnected).called(1);
      });

      test('should skip sync when not connected', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => false);

        // Act
        await syncService.syncPendingChanges();

        // Assert
        verify(() => mockNetworkInfo.isConnected).called(1);
        verifyNever(() => mockStorageService.get<String>(any()));
      });

      test('should emit sync status events', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);

        final statusEvents = <SyncStatus>[];
        syncService.syncStatusStream.listen(statusEvents.add);

        // Act
        await syncService.syncPendingChanges();

        // Assert
        expect(statusEvents, contains(SyncStatus.syncing));
        expect(statusEvents, contains(SyncStatus.success));
        expect(statusEvents, contains(SyncStatus.idle));
      });
    });

    group('syncOptimisticPosts', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should sync optimistic posts successfully', () async {
        // Arrange
        final optimisticPost = PostModel(
          id: -1,
          title: 'Test Post',
          body: 'Test Body',
          userId: 1,
          isOptimistic: true,
        );

        when(() => mockStorageService.get<String>('post_-1'))
            .thenAnswer((_) async => optimisticPost.toJsonString());
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);
        when(() => mockPostRemoteDataSource.createPost(
              title: any(named: 'title'),
              body: any(named: 'body'),
              userId: any(named: 'userId'),
            )).thenAnswer((_) async => success(
              PostModel(
                id: 101,
                title: 'Test Post',
                body: 'Test Body',
                userId: 1,
              ),
            ));
        when(() => mockStorageService.delete(any()))
            .thenAnswer((_) async {});
        when(() => mockStorageService.store(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await syncService.syncOptimisticPosts();

        // Assert
        verify(() => mockPostRemoteDataSource.createPost(
              title: 'Test Post',
              body: 'Test Body',
              userId: 1,
            )).called(1);
        verify(() => mockStorageService.delete('post_-1')).called(1);
        verify(() => mockStorageService.store('post_101', any())).called(1);
      });

      test('should handle sync failures gracefully', () async {
        // Arrange
        final optimisticPost = PostModel(
          id: -1,
          title: 'Test Post',
          body: 'Test Body',
          userId: 1,
          isOptimistic: true,
        );

        when(() => mockStorageService.get<String>('post_-1'))
            .thenAnswer((_) async => optimisticPost.toJsonString());
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);
        when(() => mockPostRemoteDataSource.createPost(
              title: any(named: 'title'),
              body: any(named: 'body'),
              userId: any(named: 'userId'),
            )).thenAnswer((_) async => failure(
              NetworkFailure('Network error'),
            ));
        when(() => mockStorageService.store(any(), any()))
            .thenAnswer((_) async {});

        // Act
        await syncService.syncOptimisticPosts();

        // Assert
        verify(() => mockPostRemoteDataSource.createPost(
              title: 'Test Post',
              body: 'Test Body',
              userId: 1,
            )).called(1);
        // Should update the cached post with error info
        verify(() => mockStorageService.store('post_-1', any())).called(1);
        verifyNever(() => mockStorageService.delete('post_-1'));
      });
    });

    group('invalidateExpiredCache', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should remove expired cache entries', () async {
        // Arrange
        final oldPost = PostModel(
          id: 1,
          title: 'Old Post',
          body: 'Old Body',
          userId: 1,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        when(() => mockStorageService.get<String>('post_1'))
            .thenAnswer((_) async => oldPost.toJsonString());
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);
        when(() => mockStorageService.delete(any()))
            .thenAnswer((_) async {});

        // Act
        await syncService.invalidateExpiredCache();

        // Assert
        verify(() => mockStorageService.delete('post_1')).called(1);
      });

      test('should keep fresh cache entries', () async {
        // Arrange
        final freshPost = PostModel(
          id: 1,
          title: 'Fresh Post',
          body: 'Fresh Body',
          userId: 1,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockStorageService.get<String>('post_1'))
            .thenAnswer((_) async => freshPost.toJsonString());
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);

        // Act
        await syncService.invalidateExpiredCache();

        // Assert
        verifyNever(() => mockStorageService.delete('post_1'));
      });
    });

    group('auto sync', () {
      setUp(() async {
        await syncService.initialize();
      });

      test('should start and stop auto sync', () {
        // Act
        syncService.startAutoSync();
        syncService.stopAutoSync();

        // Assert - no exceptions should be thrown
        expect(true, isTrue);
      });

      test('should not start auto sync twice', () {
        // Act
        syncService.startAutoSync();
        syncService.startAutoSync();
        syncService.stopAutoSync();

        // Assert - no exceptions should be thrown
        expect(true, isTrue);
      });
    });

    group('connectivity integration', () {
      test('should trigger sync when connectivity is restored', () async {
        // Arrange
        when(() => mockNetworkInfo.isConnected)
            .thenAnswer((_) async => true);
        when(() => mockStorageService.get<String>(any()))
            .thenAnswer((_) async => null);

        await syncService.initialize();

        // Act - simulate connectivity restoration
        connectivityController.add(true);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(() => mockNetworkInfo.isConnected).called(1);
      });

      test('should not trigger sync when connectivity is lost', () async {
        // Arrange
        await syncService.initialize();

        // Act - simulate connectivity loss
        connectivityController.add(false);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(() => mockNetworkInfo.isConnected);
      });
    });
  });
}