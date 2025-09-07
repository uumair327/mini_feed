import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for toggling post favorite status
/// 
/// Handles marking/unmarking posts as favorites with validation
/// and delegates to the repository for persistence.
class ToggleFavoriteUseCase implements UseCase<Post, ToggleFavoriteParams> {
  final PostRepository repository;

  const ToggleFavoriteUseCase(this.repository);

  @override
  Future<Result<Post>> call(ToggleFavoriteParams params) async {
    // Validate post ID
    if (params.id <= 0) {
      return failure(const ValidationFailure('Post ID must be greater than 0'));
    }

    // Delegate to repository for favorite toggle
    return await repository.toggleFavorite(
      postId: params.id,
      isFavorite: params.isFavorite,
    );
  }
}

/// Parameters for the toggle favorite use case
class ToggleFavoriteParams {
  final int id;
  final bool isFavorite;

  const ToggleFavoriteParams({
    required this.id,
    required this.isFavorite,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToggleFavoriteParams && 
        other.id == id && 
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode => id.hashCode ^ isFavorite.hashCode;

  @override
  String toString() => 'ToggleFavoriteParams(id: $id, isFavorite: $isFavorite)';
}