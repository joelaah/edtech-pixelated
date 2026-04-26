import 'package:equatable/equatable.dart';

/// Represents an exam/evaluation module.
///
/// Maps to the `exams/{examId}` Firestore document.
class ExamModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String subject;
  final DifficultyTier difficultyTier;
  final int durationMinutes;
  final String createdBy;
  final ExamStatus status;
  final int xpReward;
  final int questionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExamModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.difficultyTier,
    required this.durationMinutes,
    required this.createdBy,
    required this.status,
    required this.xpReward,
    required this.questionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  ExamModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    DifficultyTier? difficultyTier,
    int? durationMinutes,
    String? createdBy,
    ExamStatus? status,
    int? xpReward,
    int? questionCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      difficultyTier: difficultyTier ?? this.difficultyTier,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      questionCount: questionCount ?? this.questionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        subject,
        difficultyTier,
        durationMinutes,
        createdBy,
        status,
        xpReward,
        questionCount,
        createdAt,
        updatedAt,
      ];
}

/// Difficulty tiers matching the design mockups.
enum DifficultyTier {
  easy,
  medium,
  hard,
  ultraHard;

  String get displayName {
    return switch (this) {
      DifficultyTier.easy => 'EASY',
      DifficultyTier.medium => 'MEDIUM',
      DifficultyTier.hard => 'HARD',
      DifficultyTier.ultraHard => 'ULTRA-HARD',
    };
  }

  String get firestoreValue {
    return switch (this) {
      DifficultyTier.easy => 'easy',
      DifficultyTier.medium => 'medium',
      DifficultyTier.hard => 'hard',
      DifficultyTier.ultraHard => 'ultra_hard',
    };
  }

  static DifficultyTier fromString(String value) {
    return DifficultyTier.values.firstWhere(
      (DifficultyTier tier) => tier.firestoreValue == value,
      orElse: () => DifficultyTier.easy,
    );
  }

  int get xpMultiplier {
    return switch (this) {
      DifficultyTier.easy => 1,
      DifficultyTier.medium => 2,
      DifficultyTier.hard => 4,
      DifficultyTier.ultraHard => 8,
    };
  }
}

/// Exam publication status.
enum ExamStatus {
  draft,
  published,
  archived;

  static ExamStatus fromString(String value) {
    return ExamStatus.values.firstWhere(
      (ExamStatus s) => s.name == value,
      orElse: () => ExamStatus.draft,
    );
  }
}
