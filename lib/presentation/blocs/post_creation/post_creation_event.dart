import 'package:equatable/equatable.dart';

abstract class PostCreationEvent extends Equatable {
  const PostCreationEvent();

  @override
  List<Object?> get props => [];
}

class PostCreationRequested extends PostCreationEvent {
  final String title;
  final String body;
  final int userId;

  const PostCreationRequested({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}

class PostCreationReset extends PostCreationEvent {
  const PostCreationReset();
}