import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/domain/usecases/auth/login_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/logout_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/check_auth_status_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/get_post_details_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/refresh_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/get_favorite_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/comments/get_comments_usecase.dart';
import 'package:mini_feed/domain/usecases/comments/create_comment_usecase.dart';

void main() {
  group('UseCase Compilation Test', () {
    test('should compile all use cases without errors', () {
      // This test ensures all use cases compile correctly
      // We're not testing functionality here, just compilation
      
      // Auth use cases
      expect(LoginUseCase, isA<Type>());
      expect(LogoutUseCase, isA<Type>());
      expect(CheckAuthStatusUseCase, isA<Type>());
      expect(GetCurrentUserUseCase, isA<Type>());
      
      // Post use cases
      expect(GetPostsUseCase, isA<Type>());
      expect(GetPostDetailsUseCase, isA<Type>());
      expect(CreatePostUseCase, isA<Type>());
      expect(SearchPostsUseCase, isA<Type>());
      expect(RefreshPostsUseCase, isA<Type>());
      
      // Favorite use cases
      expect(ToggleFavoriteUseCase, isA<Type>());
      expect(GetFavoritePostsUseCase, isA<Type>());
      
      // Comment use cases
      expect(GetCommentsUseCase, isA<Type>());
      expect(CreateCommentUseCase, isA<Type>());
    });

    test('should have correct parameter classes', () {
      // Test parameter classes compile
      expect(LoginParams, isA<Type>());
      expect(GetPostsParams, isA<Type>());
      expect(GetPostDetailsParams, isA<Type>());
      expect(CreatePostParams, isA<Type>());
      expect(SearchPostsParams, isA<Type>());
      expect(ToggleFavoriteParams, isA<Type>());
      expect(GetFavoritePostsParams, isA<Type>());
      expect(GetCommentsParams, isA<Type>());
      expect(CreateCommentParams, isA<Type>());
    });
  });
}