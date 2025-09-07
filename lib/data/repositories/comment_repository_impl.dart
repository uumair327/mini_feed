import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/data/datasources/remote/post_remote_datasource.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final PostRemoteDataSource remoteDataSource;

  CommentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<List<Comment>>> getComments({required int postId}) async {
    try {
      final comments = await remoteDataSource.getComments(postId);
      return Result.success(comments.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to get comments', e.toString()));
    }
  }

  @override
  Future<Result<Comment>> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  }) async {
    try {
      final comment = await remoteDataSource.createComment(
        postId: postId,
        name: name,
        email: email,
        body: body,
      );
      return Result.success(comment.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to create comment', e.toString()));
    }
  }
}