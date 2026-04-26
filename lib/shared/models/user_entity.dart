import 'package:equatable/equatable.dart';

/// Represents a user/player in the system.
///
/// Maps directly to the `users/{uid}` Firestore document.
class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final int xp;
  final int level;
  final int coins;
  final int streakDays;
  final String? avatarUrl;
  final List<String> unlockedAvatars;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.xp,
    required this.level,
    this.coins = 0,
    required this.streakDays,
    this.avatarUrl,
    this.unlockedAvatars = const [],
    required this.createdAt,
    required this.lastLoginAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    int? xp,
    int? level,
    int? coins,
    int? streakDays,
    String? avatarUrl,
    List<String>? unlockedAvatars,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      streakDays: streakDays ?? this.streakDays,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unlockedAvatars: unlockedAvatars ?? this.unlockedAvatars,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    role,
    xp,
    level,
    coins,
    streakDays,
    avatarUrl,
    unlockedAvatars,
    createdAt,
    lastLoginAt,
  ];
}

/// User role enum matching Firestore role field.
enum UserRole {
  student,
  admin;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.name == value,
      orElse: () => UserRole.student,
    );
  }
}
