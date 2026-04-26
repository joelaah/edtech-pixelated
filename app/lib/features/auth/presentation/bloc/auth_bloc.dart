import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

// ── Events ──

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Check current auth state on app launch.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Sign in with email/password.
final class AuthSignInWithEmailRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });
  @override
  List<Object?> get props => [email, password];
}

/// Create account with email/password.
final class AuthCreateAccountRequested extends AuthEvent {
  final String email;
  final String password;
  final String displayName;
  const AuthCreateAccountRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign in with Google.
final class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Sign in with Apple.
final class AuthSignInWithAppleRequested extends AuthEvent {
  const AuthSignInWithAppleRequested();
}

/// Send password reset email.
final class AuthPasswordResetRequested extends AuthEvent {
  final String email;
  const AuthPasswordResetRequested({required this.email});
  @override
  List<Object?> get props => [email];
}

/// Sign out.
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Instantaneously update the user's state (e.g. after purchasing an avatar).
final class AuthUserUpdated extends AuthEvent {
  final UserEntity user;
  const AuthUserUpdated({required this.user});
  @override
  List<Object?> get props => [user];
}

// ── States ──

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError({required this.message});
  @override
  List<Object?> get props => [message];
}

final class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

/// Internal event to handle real-time auth state changes
final class _AuthUserChanged extends AuthEvent {
  final UserEntity? user;
  const _AuthUserChanged({required this.user});
  @override
  List<Object?> get props => [user];
}

// ── BLoC ──

/// Manages the full authentication lifecycle.
///
/// Listens to [AuthRepository.authStateChanges] and handles
/// sign-in, sign-up, Google auth, password reset, and sign-out.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmail);
    on<AuthCreateAccountRequested>(_onCreateAccount);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AuthSignInWithAppleRequested>(_onSignInWithApple);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthUserUpdated>(_onUserUpdated);
    on<_AuthUserChanged>(_onUserChanged);

    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(_AuthUserChanged(user: user));
    });
  }

  void _onUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  void _onUserUpdated(
    AuthUserUpdated event,
    Emitter<AuthState> emit,
  ) {
    emit(AuthAuthenticated(user: event.user));
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity?> result = await _authRepository.getCurrentUser();
    switch (result) {
      case Success(:final data):
        if (data != null) {
          emit(AuthAuthenticated(user: data));
        } else {
          emit(const AuthUnauthenticated());
        }
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity> result = await _authRepository.signInWithEmail(
      email: event.email,
      password: event.password,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(user: data));
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  Future<void> _onCreateAccount(
    AuthCreateAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity> result =
        await _authRepository.createAccountWithEmail(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(user: data));
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity> result = await _authRepository.signInWithGoogle();
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(user: data));
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<UserEntity> result = await _authRepository.signInWithApple();
    switch (result) {
      case Success(:final data):
        emit(AuthAuthenticated(user: data));
      case Failure(:final exception):
        // Don't show error if user cancelled
        if (exception.message.toLowerCase().contains('cancelled')) {
          emit(const AuthUnauthenticated());
        } else {
          emit(AuthError(message: exception.message));
        }
    }
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<void> result = await _authRepository.sendPasswordResetEmail(
      email: event.email,
    );
    switch (result) {
      case Success():
        emit(const AuthPasswordResetSent());
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final Result<void> result = await _authRepository.signOut();
    switch (result) {
      case Success():
        emit(const AuthUnauthenticated());
      case Failure(:final exception):
        emit(AuthError(message: exception.message));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
