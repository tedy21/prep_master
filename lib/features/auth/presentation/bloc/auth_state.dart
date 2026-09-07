part of 'auth_bloc.dart';

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

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.isAnonymous, this.phoneNumber});

  final bool isAnonymous;
  final String? phoneNumber;

  @override
  List<Object?> get props => [isAnonymous, phoneNumber];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
