import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:bitwise_academy/core/errors/app_exception.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/core/utils/firebase_interceptor.dart';
import 'package:bitwise_academy/core/utils/logger.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';
import 'package:bitwise_academy/shared/models/question_model.dart';

/// Repository for all exam-related Firestore operations.
///
/// Handles CRUD for exams and their questions sub-collection.
class ExamRepository with FirebaseGuardedExecution {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ExamRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  CollectionReference<Map<String, dynamic>> get _examsCollection =>
      _firestore.collection('exams');

  // ── READ ──

  /// Fetch all published exams (for students).
  Future<Result<List<ExamModel>>> fetchPublishedExams() async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection
              .where('status', isEqualTo: 'published')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs.map(_mapDocToExam).toList();
    }, taskName: 'fetchPublishedExams');
  }

  /// Watch all published exams (for students).
  Stream<Result<List<ExamModel>>> watchPublishedExams() {
    return guardedStream(
      () => _examsCollection
          .where('status', isEqualTo: 'published')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map(_mapDocToExam).toList();
          }),
      taskName: 'watchPublishedExams',
    );
  }

  /// Fetch ALL exams regardless of status (for admins).
  Future<Result<List<ExamModel>>> fetchAllExams() async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection.orderBy('updatedAt', descending: true).get();

      return snapshot.docs.map(_mapDocToExam).toList();
    }, taskName: 'fetchAllExams');
  }

  /// Fetch a single exam by ID.
  Future<Result<ExamModel>> fetchExamById(String examId) async {
    return guardedTask(() async {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _examsCollection
          .doc(examId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw NotFoundException(
          message: 'Exam not found: $examId',
          code: 'exam-not-found',
        );
      }
      return _mapDocToExam(doc);
    }, taskName: 'fetchExamById');
  }

  /// Fetch all questions for an exam.
  Future<Result<List<QuestionModel>>> fetchQuestions(String examId) async {
    return guardedTask(() async {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _examsCollection
              .doc(examId)
              .collection('questions')
              .orderBy('order')
              .get();

      return snapshot.docs.map(_mapDocToQuestion).toList();
    }, taskName: 'fetchQuestions');
  }

  // ── CREATE ──

  /// Create a new exam (admin only).
  ///
  /// If [attachmentFile] is provided, it will be uploaded to Firebase Storage
  /// and its download URL stored in the exam document as `attachmentUrl`.
  Future<Result<ExamModel>> createExam({
    required String title,
    required String description,
    required String subject,
    required DifficultyTier difficultyTier,
    required int durationMinutes,
    required String createdBy,
    required int xpReward,
    File? attachmentFile,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'subject': subject,
        'difficultyTier': difficultyTier.firestoreValue,
        'durationMinutes': durationMinutes,
        'createdBy': createdBy,
        'status': ExamStatus.draft.name,
        'xpReward': xpReward,
        'questionCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final DocumentReference<Map<String, dynamic>> docRef =
          await _examsCollection.add(data);
      AppLogger.instance.i('Exam created: ${docRef.id}');

      // Upload attachment if provided
      if (attachmentFile != null) {
        final attachmentResult = await uploadExamFile(
          examId: docRef.id,
          file: attachmentFile,
        );
        switch (attachmentResult) {
          case Success(:final data):
            await docRef.update({'attachmentUrl': data});
          case Failure(:final exception):
            AppLogger.instance.w(
              'Exam created but file upload failed: ${exception.message}',
            );
        }
      }

      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      return _mapDocToExam(doc);
    }, taskName: 'createExam');
  }

  /// Uploads a file to Firebase Storage under `exam_assets/{examId}/`.
  ///
  /// Returns the download URL of the uploaded file on success.
  Future<Result<String>> uploadExamFile({
    required String examId,
    required File file,
  }) async {
    return guardedTask(() async {
      final fileName =
          'exam_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = _storage.ref().child('exam_assets/$examId/$fileName');

      final uploadTask = await storageRef.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      AppLogger.instance.i('Exam file uploaded: $downloadUrl');
      return downloadUrl;
    }, taskName: 'uploadExamFile');
  }

  /// Add a question to an exam (admin only).
  Future<Result<QuestionModel>> addQuestion({
    required String examId,
    required String questionText,
    required QuestionType questionType,
    required List<String> options,
    required String correctAnswer,
    required String explanation,
    required int points,
    required int order,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        'questionText': questionText,
        'questionType': questionType.firestoreValue,
        'options': options,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'points': points,
        'order': order,
      };

      final DocumentReference<Map<String, dynamic>> docRef =
          await _examsCollection.doc(examId).collection('questions').add(data);

      // Update question count on the exam
      await _examsCollection.doc(examId).update({
        'questionCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.instance.i('Question added to exam $examId: ${docRef.id}');
      final DocumentSnapshot<Map<String, dynamic>> doc = await docRef.get();
      return _mapDocToQuestion(doc);
    }, taskName: 'addQuestion');
  }

  // ── UPDATE ──

  /// Update exam metadata (admin only).
  Future<Result<void>> updateExam({
    required String examId,
    Map<String, dynamic>? updates,
  }) async {
    return guardedTask(() async {
      final Map<String, dynamic> data = {
        ...?updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _examsCollection.doc(examId).update(data);
      AppLogger.instance.i('Exam updated: $examId');
    }, taskName: 'updateExam');
  }

  /// Publish an exam (change status to published).
  Future<Result<void>> publishExam(String examId) async {
    return updateExam(
      examId: examId,
      updates: {'status': ExamStatus.published.name},
    );
  }

  /// Archive an exam.
  Future<Result<void>> archiveExam(String examId) async {
    return updateExam(
      examId: examId,
      updates: {'status': ExamStatus.archived.name},
    );
  }

  // ── DELETE ──

  /// Delete an exam and all its questions (admin only).
  Future<Result<void>> deleteExam(String examId) async {
    return guardedTask(() async {
      // Delete questions sub-collection first
      final QuerySnapshot<Map<String, dynamic>> questions =
          await _examsCollection.doc(examId).collection('questions').get();
      final WriteBatch batch = _firestore.batch();
      for (final DocumentSnapshot<Map<String, dynamic>> doc in questions.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_examsCollection.doc(examId));
      await batch.commit();

      AppLogger.instance.i('Exam deleted: $examId');
    }, taskName: 'deleteExam');
  }

  // ── Mappers ──

  ExamModel _mapDocToExam(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return ExamModel(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      subject: data['subject'] as String,
      difficultyTier: DifficultyTier.fromString(
        data['difficultyTier'] as String,
      ),
      durationMinutes: (data['durationMinutes'] as num).toInt(),
      createdBy: data['createdBy'] as String,
      status: ExamStatus.fromString(data['status'] as String),
      xpReward: (data['xpReward'] as num).toInt(),
      questionCount: (data['questionCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  QuestionModel _mapDocToQuestion(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data()!;
    return QuestionModel(
      id: doc.id,
      questionText: data['questionText'] as String,
      questionType: QuestionType.fromString(data['questionType'] as String),
      options: List<String>.from(data['options'] as List<dynamic>? ?? []),
      correctAnswer: data['correctAnswer'] as String,
      explanation: data['explanation'] as String? ?? '',
      points: (data['points'] as num).toInt(),
      order: (data['order'] as num).toInt(),
    );
  }
}
