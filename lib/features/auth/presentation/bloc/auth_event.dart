part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthSignInAnonymously extends AuthEvent {
  const AuthSignInAnonymously();
}

class AuthSignInWithPhone extends AuthEvent {
  const AuthSignInWithPhone({required this.phone, required this.password});

  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}

class AuthRegisterWithPhone extends AuthEvent {
  const AuthRegisterWithPhone({required this.phone, required this.password});

  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}

class AuthSignOut extends AuthEvent {
  const AuthSignOut();
}
