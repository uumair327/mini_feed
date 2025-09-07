import 'package:equatable/equatable.dart';
import 'package:mini_feed/domain/entities/post.dart';

abstract class PostCreationState extends Equatable {
  const PostCreationState();

  @override
  List<Object?> get props => [];
}

class PostCreationInitial extends PostCreationState {
  const PostCreationInitial();
}

class PostCreationLoading extends PostCreationState {
  const PostCreationLoading();
}

class PostCreationSuccess extends PostCreationState {
  final Post post;

  const PostCreationSuccess({required this.post});

  @override
  List<Object?> get props => [post];
}

class PostCreationFailure extends PostCreationState {
  final String message;
  final String? details;

  const PostCreationFailure({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}