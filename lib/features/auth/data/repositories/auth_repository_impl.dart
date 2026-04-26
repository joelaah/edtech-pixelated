import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bitwise_academy/features/auth/domain/repositories/auth_repository.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

/// Concrete implementation of [AuthRepository].
///
/// Combines [AuthRemoteDataSource] (Firebase Auth) with
/// [FirebaseFirestore] (user profile documents).
class AuthRepositoryImpl with FirebaseGuardedExecution implements AuthRepository {
  final AuthRemoteDataSource _authDataSource;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authDataSource,
    required FirebaseFirestore firestore,
  }) : _authDataSource = authDataSource,
       _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  Future<bool> _isAdminWhitelisted(String email) async {
    try {
      final doc = await _firestore
          .collection('admin_whitelist')
          .doc(email)
          .get();
      return doc.exists;
    } catch (e, stackTrace) {
      AppLogger.instance.e(
        'Error checking admin whitelist for $email',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    late StreamController<UserEntity?> controller;
    StreamSubscription<fb.User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreSub;

    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        authSub = _authDataSource.authStateChanges.listen((firebaseUser) {
          firestoreSub?.cancel();
          if (firebaseUser == null) {
            controller.add(null);
          } else {
            firestoreSub = _usersCollection
                .doc(firebaseUser.uid)
                .snapshots()
                .listen(
                  (doc) {
                    if (!doc.exists || doc.data() == null) {
                      controller.add(null);
                    } else {
                      try {
                        controller.add(_mapDocToUser(doc));
                      } catch (e) {
                        AppLogger.instance.e(
                          'Error mapping auth state',
                          error: e,
                        );
                        controller.add(null);
                      }
                    }
                  },
                  onError: (Object e) {
                    AppLogger.instance.e(
                      'Error listening to user doc',
                      error: e,
                    );
                  },
                );
          }
        });
      },
      onCancel: () {
        authSub?.cancel();
        firestoreSub?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    return guardedTask(
      () async {
        final firebaseUser = _authDataSource.currentUser;
        if (firebaseUser == null) return null;

        final doc = await _usersCollection.doc(firebaseUser.uid).get();
        if (!doc.exists || doc.data() == null) return null;

        return _mapDocToUser(doc);
      },
      taskName: 'getCurrentUser',
    );
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return guardedTask(
      () async {
        final credential = await _authDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        final String uid = credential.user!.uid;

        // Update last login
        await _usersCollection.doc(uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
        });

        final doc = await _usersCollection.doc(uid).get();
        return _mapDocToUser(doc);
      },
      taskName: 'signInWithEmail',
    );
  }

  @override
  Future<Result<UserEntity>> createAccountWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return guardedTask(
      () async {
        AppLogger.instance.d('🔵 [AUTH] Step 1: Creating Firebase Auth user...');
        final credential = await _authDataSource.createAccountWithEmail(
          email: email,
          password: password,
        );
        final String uid = credential.user!.uid;
        AppLogger.instance.d('🟢 [AUTH] Step 1 DONE: Auth user created with uid=$uid');

        // Create user profile in Firestore (role defaults to student)
        AppLogger.instance.d('🔵 [AUTH] Step 2: Checking admin whitelist...');
        final bool isAdmin = await _isAdminWhitelisted(email);
        AppLogger.instance.d('🟢 [AUTH] Step 2 DONE: isAdmin=$isAdmin');

        final Map<String, dynamic> userData = {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'role': isAdmin ? UserRole.admin.name : UserRole.student.name,
          'xp': 0,
          'level': 1,
          'streakDays': 0,
          'avatarUrl': null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        };

        AppLogger.instance.d('🔵 [AUTH] Step 3: Ensuring auth state is established...');

        // Ensure the client is authenticated before writing
        final fb.User? current = _authDataSource.currentUser ?? credential.user;
        final String? currentUidBefore = current?.uid;
        if (currentUidBefore != uid) {
          AppLogger.instance.d('🔶 Auth UID mismatch. Waiting for auth to settle...');
          const timeout = Duration(seconds: 5);
          const interval = Duration(milliseconds: 250);
          var waited = Duration.zero;
          while ((_authDataSource.currentUser == null ||
                  _authDataSource.currentUser!.uid != uid) &&
              waited < timeout) {
            await Future<void>.delayed(interval);
            waited += interval;
          }
        }

        AppLogger.instance.d('🔵 [AUTH] Writing user to Firestore at users/$uid ...');
        await _usersCollection.doc(uid).set(userData);
        AppLogger.instance.d('🟢 [AUTH] Step 3 DONE: Firestore write succeeded!');

        final doc = await _usersCollection.doc(uid).get();
        return _mapDocToUser(doc);
      },
      taskName: 'createAccountWithEmail',
    );
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    return guardedTask(
      () async {
        final credential = await _authDataSource.signInWithGoogle();
        final String uid = credential.user!.uid;

        // Check if user profile exists; create if first-time
        final DocumentSnapshot<Map<String, dynamic>> existingDoc =
            await _usersCollection.doc(uid).get();

        if (!existingDoc.exists) {
          final Map<String, dynamic> userData = {
            'uid': uid,
            'email': credential.user!.email ?? '',
            'displayName': credential.user!.displayName ?? 'HERO',
            'role': await _isAdminWhitelisted(credential.user!.email ?? '')
                ? UserRole.admin.name
                : UserRole.student.name,
            'xp': 0,
            'level': 1,
            'streakDays': 0,
            'avatarUrl': credential.user!.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          };
          await _usersCollection.doc(uid).set(userData);
          AppLogger.instance.i('New Google user profile created: $uid');
        } else {
          await _usersCollection.doc(uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
            .doc(uid)
            .get();
        return _mapDocToUser(doc);
      },
      taskName: 'signInWithGoogle',
    );
  }

  @override
  Future<Result<UserEntity>> signInWithApple() async {
    return guardedTask(
      () async {
        final credential = await _authDataSource.signInWithApple();
        final String uid = credential.user!.uid;

        // Check if user profile exists; create if first-time
        final DocumentSnapshot<Map<String, dynamic>> existingDoc =
            await _usersCollection.doc(uid).get();

        if (!existingDoc.exists) {
          final Map<String, dynamic> userData = {
            'uid': uid,
            'email': credential.user!.email ?? '',
            'displayName': credential.user!.displayName ?? 'HERO',
            'role': await _isAdminWhitelisted(credential.user!.email ?? '')
                ? UserRole.admin.name
                : UserRole.student.name,
            'xp': 0,
            'level': 1,
            'streakDays': 0,
            'avatarUrl': null,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLoginAt': FieldValue.serverTimestamp(),
          };
          await _usersCollection.doc(uid).set(userData);
          AppLogger.instance.i('New Apple user profile created: $uid');
        } else {
          await _usersCollection.doc(uid).update({
            'lastLoginAt': FieldValue.serverTimestamp(),
          });
        }

        final DocumentSnapshot<Map<String, dynamic>> doc = await _usersCollection
            .doc(uid)
            .get();
        return _mapDocToUser(doc);
      },
      taskName: 'signInWithApple',
    );
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return guardedTask(
      () => _authDataSource.sendPasswordResetEmail(email: email),
      taskName: 'sendPasswordResetEmail',
    );
  }

  @override
  Future<Result<void>> signOut() async {
    return guardedTask(
      () => _authDataSource.signOut(),
      taskName: 'signOut',
    );
  }

  /// Maps a Firestore document to [UserEntity].
  UserEntity _mapDocToUser(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    return UserEntity(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      role: UserRole.fromString(data['role'] as String),
      xp: (data['xp'] as num).toInt(),
      level: (data['level'] as num).toInt(),
      streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
      avatarUrl: data['avatarUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt:
          (data['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
