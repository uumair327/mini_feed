import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/post_model.dart';
import 'package:mini_feed/domain/entities/post.dart';

void main() {
  group('PostModel', () {
    late PostModel postModel;
    late Map<String, dynamic> jsonMap;
    late Map<String, dynamic> jsonPlaceholderMap;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      postModel = PostModel(
        id: 1,
        title: 'Test Post',
        body: 'This is a test post body.',
        userId: 1,
        isFavorite: true,
        isOptimistic: false,
        createdAt: testDate,
        updatedAt: testDate,
      );

      jsonMap = {
        'id': 1,
        'title': 'Test Post',
        'body': 'This is a test post body.',
        'userId': 1,
        'isFavorite': true,
        'isOptimistic': false,
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      jsonPlaceholderMap = {
        'id': 1,
        'title': 'Test Post',
        'body': 'This is a test post body.',
        'userId': 1,
      };
    });

    group('fromJson', () {
      test('should create PostModel from valid JSON', () {
        // Act
        final result = PostModel.fromJson(jsonMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.title, equals('Test Post'));
        expect(result.body, equals('This is a test post body.'));
        expect(result.userId, equals(1));
        expect(result.isFavorite, isTrue);
        expect(result.isOptimistic, isFalse);
        expect(result.createdAt, equals(testDate));
        expect(result.updatedAt, equals(testDate));
      });

      test('should create PostModel with default values for optional fields', () {
        // Arrange
        final minimalJson = {
          'id': 1,
          'title': 'Test Post',
          'body': 'This is a test post body.',
          'userId': 1,
        };

        // Act
        final result = PostModel.fromJson(minimalJson);

        // Assert
        expect(result.id, equals(1));
        expect(result.title, equals('Test Post'));
        expect(result.body, equals('This is a test post body.'));
        expect(result.userId, equals(1));
        expect(result.isFavorite, isFalse);
        expect(result.isOptimistic, isFalse);
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert PostModel to JSON', () {
        // Act
        final result = postModel.toJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['title'], equals('Test Post'));
        expect(result['body'], equals('This is a test post body.'));
        expect(result['userId'], equals(1));
        expect(result['isFavorite'], isTrue);
        expect(result['isOptimistic'], isFalse);
        expect(result['createdAt'], equals(testDate.toIso8601String()));
        expect(result['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should exclude null date fields from JSON', () {
        // Arrange
        final postWithoutDates = const PostModel(
          id: 1,
          title: 'Test Post',
          body: 'This is a test post body.',
          userId: 1,
        );

        // Act
        final result = postWithoutDates.toJson();

        // Assert
        expect(result.containsKey('createdAt'), isFalse);
        expect(result.containsKey('updatedAt'), isFalse);
      });
    });

    group('JSON string conversion', () {
      test('should convert to and from JSON string', () {
        // Act
        final jsonString = postModel.toJsonString();
        final result = PostModel.fromJsonString(jsonString);

        // Assert
        expect(result.id, equals(postModel.id));
        expect(result.title, equals(postModel.title));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
        expect(result.isFavorite, equals(postModel.isFavorite));
        expect(result.isOptimistic, equals(postModel.isOptimistic));
        expect(result.createdAt, equals(postModel.createdAt));
        expect(result.updatedAt, equals(postModel.updatedAt));
      });
    });

    group('fromDomain and toDomain', () {
      test('should convert from domain entity', () {
        // Arrange
        final domainPost = Post(
          id: 2,
          title: 'Domain Post',
          body: 'Domain post body.',
          userId: 2,
          isFavorite: true,
          createdAt: testDate,
        );

        // Act
        final result = PostModel.fromDomain(domainPost);

        // Assert
        expect(result.id, equals(domainPost.id));
        expect(result.title, equals(domainPost.title));
        expect(result.body, equals(domainPost.body));
        expect(result.userId, equals(domainPost.userId));
        expect(result.isFavorite, equals(domainPost.isFavorite));
        expect(result.createdAt, equals(domainPost.createdAt));
      });

      test('should convert to domain entity', () {
        // Act
        final result = postModel.toDomain();

        // Assert
        expect(result, isA<Post>());
        expect(result.id, equals(postModel.id));
        expect(result.title, equals(postModel.title));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
        expect(result.isFavorite, equals(postModel.isFavorite));
        expect(result.isOptimistic, equals(postModel.isOptimistic));
        expect(result.createdAt, equals(postModel.createdAt));
        expect(result.updatedAt, equals(postModel.updatedAt));
      });
    });

    group('JSONPlaceholder API format', () {
      test('should create PostModel from JSONPlaceholder JSON', () {
        // Act
        final result = PostModel.fromJsonPlaceholder(jsonPlaceholderMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.title, equals('Test Post'));
        expect(result.body, equals('This is a test post body.'));
        expect(result.userId, equals(1));
        expect(result.isFavorite, isFalse);
        expect(result.isOptimistic, isFalse);
      });

      test('should convert to JSONPlaceholder JSON format', () {
        // Act
        final result = postModel.toJsonPlaceholder();

        // Assert
        expect(result['id'], equals(1));
        expect(result['title'], equals('Test Post'));
        expect(result['body'], equals('This is a test post body.'));
        expect(result['userId'], equals(1));
        expect(result.containsKey('isFavorite'), isFalse);
        expect(result.containsKey('isOptimistic'), isFalse);
        expect(result.containsKey('createdAt'), isFalse);
        expect(result.containsKey('updatedAt'), isFalse);
      });
    });

    group('local storage format', () {
      test('should convert to local storage JSON format', () {
        // Act
        final result = postModel.toLocalStorageJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['title'], equals('Test Post'));
        expect(result['body'], equals('This is a test post body.'));
        expect(result['userId'], equals(1));
        expect(result['isFavorite'], isTrue);
        expect(result['isOptimistic'], isFalse);
        expect(result['createdAt'], equals(testDate.millisecondsSinceEpoch));
        expect(result['updatedAt'], equals(testDate.millisecondsSinceEpoch));
      });

      test('should create PostModel from local storage JSON', () {
        // Arrange
        final localStorageJson = {
          'id': 1,
          'title': 'Test Post',
          'body': 'This is a test post body.',
          'userId': 1,
          'isFavorite': true,
          'isOptimistic': false,
          'createdAt': testDate.millisecondsSinceEpoch,
          'updatedAt': testDate.millisecondsSinceEpoch,
        };

        // Act
        final result = PostModel.fromLocalStorageJson(localStorageJson);

        // Assert
        expect(result.id, equals(1));
        expect(result.title, equals('Test Post'));
        expect(result.body, equals('This is a test post body.'));
        expect(result.userId, equals(1));
        expect(result.isFavorite, isTrue);
        expect(result.isOptimistic, isFalse);
        expect(result.createdAt, equals(testDate));
        expect(result.updatedAt, equals(testDate));
      });

      test('should handle null dates in local storage format', () {
        // Arrange
        final localStorageJson = {
          'id': 1,
          'title': 'Test Post',
          'body': 'This is a test post body.',
          'userId': 1,
          'isFavorite': false,
          'isOptimistic': false,
          'createdAt': null,
          'updatedAt': null,
        };

        // Act
        final result = PostModel.fromLocalStorageJson(localStorageJson);

        // Assert
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = postModel.copyWith(
          title: 'Updated Title',
          isFavorite: false,
        );

        // Assert
        expect(result.id, equals(postModel.id));
        expect(result.title, equals('Updated Title'));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
        expect(result.isFavorite, isFalse);
        expect(result.isOptimistic, equals(postModel.isOptimistic));
        expect(result.createdAt, equals(postModel.createdAt));
        expect(result.updatedAt, equals(postModel.updatedAt));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = postModel.copyWith();

        // Assert
        expect(result.id, equals(postModel.id));
        expect(result.title, equals(postModel.title));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
        expect(result.isFavorite, equals(postModel.isFavorite));
        expect(result.isOptimistic, equals(postModel.isOptimistic));
        expect(result.createdAt, equals(postModel.createdAt));
        expect(result.updatedAt, equals(postModel.updatedAt));
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite status', () {
        // Act
        final result = postModel.toggleFavorite();

        // Assert
        expect(result.isFavorite, isFalse);
        expect(result.id, equals(postModel.id));
        expect(result.title, equals(postModel.title));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
      });
    });

    group('markAsSynced', () {
      test('should mark post as synced', () {
        // Arrange
        final optimisticPost = postModel.copyWith(isOptimistic: true);

        // Act
        final result = optimisticPost.markAsSynced(syncedId: 999);

        // Assert
        expect(result.id, equals(999));
        expect(result.isOptimistic, isFalse);
        expect(result.updatedAt, isNotNull);
        expect(result.title, equals(optimisticPost.title));
        expect(result.body, equals(optimisticPost.body));
        expect(result.userId, equals(optimisticPost.userId));
      });

      test('should keep original ID when syncedId not provided', () {
        // Arrange
        final optimisticPost = postModel.copyWith(isOptimistic: true);

        // Act
        final result = optimisticPost.markAsSynced();

        // Assert
        expect(result.id, equals(optimisticPost.id));
        expect(result.isOptimistic, isFalse);
      });
    });

    group('optimistic factory', () {
      test('should create optimistic post', () {
        // Act
        final result = PostModel.optimistic(
          title: 'Optimistic Post',
          body: 'Optimistic body',
          userId: 1,
          tempId: 12345,
        );

        // Assert
        expect(result.id, equals(12345));
        expect(result.title, equals('Optimistic Post'));
        expect(result.body, equals('Optimistic body'));
        expect(result.userId, equals(1));
        expect(result.isOptimistic, isTrue);
        expect(result.createdAt, isNotNull);
      });

      test('should generate temp ID when not provided', () {
        // Act
        final result = PostModel.optimistic(
          title: 'Optimistic Post',
          body: 'Optimistic body',
          userId: 1,
        );

        // Assert
        expect(result.id, isNotNull);
        expect(result.isOptimistic, isTrue);
      });
    });

    group('mock factory', () {
      test('should create mock post with default values', () {
        // Act
        final result = PostModel.mock();

        // Assert
        expect(result.id, equals(1));
        expect(result.title, equals('Test Post'));
        expect(result.body, equals('This is a test post body.'));
        expect(result.userId, equals(1));
        expect(result.isFavorite, isFalse);
        expect(result.isOptimistic, isFalse);
      });

      test('should create mock post with custom values', () {
        // Act
        final result = PostModel.mock(
          id: 99,
          title: 'Custom Post',
          isFavorite: true,
        );

        // Assert
        expect(result.id, equals(99));
        expect(result.title, equals('Custom Post'));
        expect(result.isFavorite, isTrue);
      });
    });

    group('inherited properties', () {
      test('should inherit bodyPreview property from Post entity', () {
        // Act
        final bodyPreview = postModel.bodyPreview;

        // Assert
        expect(bodyPreview, equals('This is a test post body.'));
      });

      test('should inherit hasContent property from Post entity', () {
        // Act
        final hasContent = postModel.hasContent;

        // Assert
        expect(hasContent, isTrue);
      });

      test('should inherit isValidForCreation property from Post entity', () {
        // Act
        final isValid = postModel.isValidForCreation;

        // Assert
        expect(isValid, isTrue);
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = postModel.toString();

        // Assert
        expect(result, contains('PostModel'));
        expect(result, contains('Test Post'));
        expect(result, contains('true')); // isFavorite
        expect(result, contains('false')); // isOptimistic
      });
    });
  });
}