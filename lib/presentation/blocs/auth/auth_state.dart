import 'package:equatable/equatable.dart';
import 'package:mini_feed/domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final User user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;
  final String? details;

  const AuthFailure({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}