import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Abstract contract for authentication operations.
///
/// All methods return [Result<T>] — never throw.
abstract class AuthRepository {
  /// Stream of authentication state changes and live Firestore user profile updates.
  Stream<UserEntity?> get authStateChanges;

  /// Get the currently authenticated user, or `null`.
  Future<Result<UserEntity?>> getCurrentUser();

  /// Sign in with email and password.
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Create a new account with email and password.
  Future<Result<UserEntity>> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign in with Google.
  Future<Result<UserEntity>> signInWithGoogle();

  /// Sign in with Apple.
  Future<Result<UserEntity>> signInWithApple();

  /// Send password reset email.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// Sign out.
  Future<Result<void>> signOut();
}
