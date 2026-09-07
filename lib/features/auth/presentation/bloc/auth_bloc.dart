import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/phone_auth_mapper.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignInAnonymously>(_onSignInAnonymously);
    on<AuthSignInWithPhone>(_onSignInWithPhone);
    on<AuthRegisterWithPhone>(_onRegisterWithPhone);
    on<AuthSignOut>(_onSignOut);
  }

  final AuthRepository _authRepository;

  AuthAuthenticated _authenticatedFromUser(User user) {
    return AuthAuthenticated(
      isAnonymous: user.isAnonymous,
      phoneNumber: _authRepository.displayPhone ??
          PhoneAuthMapper.fromAuthEmail(user.email),
    );
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    if (_authRepository.currentUser != null) {
      emit(_authenticatedFromUser(_authRepository.currentUser!));
      return;
    }

    final result = await _authRepository.signInAnonymously();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(_authenticatedFromUser(user)),
    );
  }

  Future<void> _onSignInAnonymously(
    AuthSignInAnonymously event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInAnonymously();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(_authenticatedFromUser(user)),
    );
  }

  Future<void> _onSignInWithPhone(
    AuthSignInWithPhone event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.signInWithPhone(
      phone: event.phone,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(_authenticatedFromUser(user)),
    );
  }

  Future<void> _onRegisterWithPhone(
    AuthRegisterWithPhone event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _authRepository.registerWithPhone(
      phone: event.phone,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(_authenticatedFromUser(user)),
    );
  }

  Future<void> _onSignOut(AuthSignOut event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await _authRepository.signOut();
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async {
        // Return to guest mode so progress writes keep working.
        final anon = await _authRepository.signInAnonymously();
        anon.fold(
          (failure) => emit(AuthError(failure.message)),
          (user) => emit(_authenticatedFromUser(user)),
        );
      },
    );
  }
}
