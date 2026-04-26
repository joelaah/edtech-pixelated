import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Repository for user profile operations.
///
/// Handles XP updates, level progression, and streak tracking.
class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Fetch a user profile by UID.
  Future<Result<UserEntity>> fetchUser(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _usersCollection.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return Failure<UserEntity>(NotFoundException(
          message: 'User not found: $uid',
          code: 'user-not-found',
        ));
      }
      return Success<UserEntity>(_mapDocToUser(doc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchUser failed', error: e);
      return Failure<UserEntity>(FirestoreException(
        message: e.message ?? 'Failed to fetch user',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Real-time stream of a single user profile document.
  ///
  /// Emits [Success<UserEntity>] on each Firestore update,
  /// or [Failure] on error.
  Stream<Result<UserEntity>> watchUser(String uid) {
    return _usersCollection
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) {
            return Failure<UserEntity>(NotFoundException(
              message: 'User not found: $uid',
              code: 'user-not-found',
            ));
          }
          return Success<UserEntity>(_mapDocToUser(doc));
        })
        .handleError((Object e, StackTrace stackTrace) {
          AppLogger.instance.e('watchUser failed', error: e);
          if (e is FirebaseException) {
            return Failure<UserEntity>(FirestoreException(
              message: e.message ?? 'Failed to stream user',
              code: e.code,
              stackTrace: stackTrace,
            ));
          }
          return Failure<UserEntity>(FirestoreException(
            message: 'An unexpected error occurred: $e',
            code: 'unknown',
            stackTrace: stackTrace,
          ));
        });
  }

  /// Award XP to a user and check for level-up.
  Future<Result<UserEntity>> awardXp({
    required String uid,
    required int xpAmount,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'xp': FieldValue.increment(xpAmount),
      });

      // Check for level-up (every 500 XP = 1 level)
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _usersCollection.doc(uid).get();
      final Map<String, dynamic> data = doc.data()!;
      final int currentXp = (data['xp'] as num).toInt();
      final int newLevel = (currentXp ~/ 500) + 1;
      final int currentLevel = (data['level'] as num).toInt();

      if (newLevel > currentLevel) {
        await _usersCollection.doc(uid).update({'level': newLevel});
        AppLogger.instance.i(
          'User $uid leveled up: $currentLevel → $newLevel',
        );
      }

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc =
          await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('awardXp failed', error: e);
      return Failure<UserEntity>(FirestoreException(
        message: e.message ?? 'Failed to award XP',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Update the daily streak counter.
  Future<Result<void>> updateStreak({
    required String uid,
    required int streakDays,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'streakDays': streakDays,
      });
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('updateStreak failed', error: e);
      return Failure<void>(FirestoreException(
        message: e.message ?? 'Failed to update streak',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Update user profile fields.
  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      if (updates.isEmpty) return const Success<void>(null);

      await _usersCollection.doc(uid).update(updates);
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('updateProfile failed', error: e);
      return Failure<void>(FirestoreException(
        message: e.message ?? 'Failed to update profile',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Admin: change a user's role.
  Future<Result<void>> setUserRole({
    required String uid,
    required UserRole role,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'role': role.name,
      });
      AppLogger.instance.i('User role changed: $uid → ${role.name}');
      return const Success<void>(null);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('setUserRole failed', error: e);
      return Failure<void>(FirestoreException(
        message: e.message ?? 'Failed to set user role',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Fetch all users (admin).
  Future<Result<List<UserEntity>>> fetchAllUsers() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _usersCollection.orderBy('createdAt', descending: true).get();
      final List<UserEntity> users =
          snapshot.docs.map(_mapDocToUser).toList();
      return Success<List<UserEntity>>(users);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchAllUsers failed', error: e);
      return Failure<List<UserEntity>>(FirestoreException(
        message: e.message ?? 'Failed to fetch users',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Fetch total user count (admin).
  Future<Result<int>> fetchUserCount() async {
    try {
      final AggregateQuerySnapshot snapshot =
          await _usersCollection.count().get();
      return Success<int>(snapshot.count ?? 0);
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('fetchUserCount failed', error: e);
      return Failure<int>(FirestoreException(
        message: e.message ?? 'Failed to count users',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Award Coins to a user.
  Future<Result<UserEntity>> awardCoins({
    required String uid,
    required int coinsAmount,
  }) async {
    try {
      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(coinsAmount),
      });

      final DocumentSnapshot<Map<String, dynamic>> updatedDoc =
          await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('awardCoins failed', error: e);
      return Failure<UserEntity>(FirestoreException(
        message: e.message ?? 'Failed to award coins',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  /// Purchase/Unlock an avatar and deduct coins.
  Future<Result<UserEntity>> purchaseAvatar({
    required String uid,
    required String avatarId,
    required int price,
  }) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      final data = doc.data()!;
      final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;

      if (currentCoins < price) {
        return const Failure<UserEntity>(ValidationException(
          message: 'Not enough coins to purchase this avatar.',
          code: 'insufficient-funds',
          fieldErrors: {},
        ));
      }

      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(-price),
        'unlockedAvatars': FieldValue.arrayUnion([avatarId]),
      });

      final updatedDoc = await _usersCollection.doc(uid).get();
      return Success<UserEntity>(_mapDocToUser(updatedDoc));
    } on FirebaseException catch (e, stackTrace) {
      AppLogger.instance.e('purchaseAvatar failed', error: e);
      return Failure<UserEntity>(FirestoreException(
        message: e.message ?? 'Failed to purchase avatar',
        code: e.code,
        stackTrace: stackTrace,
      ));
    }
  }

  UserEntity _mapDocToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    return UserEntity(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      role: UserRole.fromString(data['role'] as String),
      xp: (data['xp'] as num).toInt(),
      level: (data['level'] as num).toInt(),
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
      unlockedAvatars: List<String>.from(data['unlockedAvatars'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
