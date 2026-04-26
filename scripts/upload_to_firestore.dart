// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart' as admin;

void main() async {
  // Paths are relative to the 'app' directory
  const String serviceAccountPath = 'service-account.json';
  const String seedPath = 'database_seed.json';

  final serviceAccountFile = File(serviceAccountPath);
  final seedFile = File(seedPath);

  if (!serviceAccountFile.existsSync()) {
    print('❌ ERROR: service-account.json not found in /app directory.');
    exit(1);
  }

  if (!seedFile.existsSync()) {
    print('❌ ERROR: $seedPath not found! Run the obsidian_parser.dart first.');
    exit(1);
  }

  print('🔗 Initializing Firebase Admin SDK...');

  final Map<String, dynamic> serviceAccountJson =
      jsonDecode(serviceAccountFile.readAsStringSync()) as Map<String, dynamic>;
  final String projectId = serviceAccountJson['project_id'] as String;

  final app = admin.FirebaseApp.initializeApp(
    options: admin.AppOptions(
      credential: admin.Credential.fromServiceAccount(serviceAccountFile),
      projectId: projectId,
    ),
  );

  final firestore = app.firestore();

  try {
    final Map<String, dynamic> seedData =
        jsonDecode(seedFile.readAsStringSync()) as Map<String, dynamic>;
    final List<dynamic> exams =
        (seedData['exams'] as List<dynamic>?) ?? <dynamic>[];

    if (exams.isEmpty) {
      print('⚠️ No exams found in $seedPath.');
      return;
    }

    print(
      '🚀 Starting optimized upload of ${exams.length} exams to project: $projectId...',
    );

    for (int i = 0; i < exams.length; i++) {
      final Map<String, dynamic> examData = Map<String, dynamic>.from(
        exams[i] as Map<dynamic, dynamic>,
      );
      final String title = (examData['title'] as String?) ?? 'Untitled Exam';

      print('\n[${i + 1}/${exams.length}] Processing: $title');

      // 1. Validation
      final List<String> requiredFields = [
        'title',
        'subject',
        'difficultyTier',
        'durationMinutes',
        'questions',
      ];
      final List<String> missingFields = requiredFields
          .where((String f) => !examData.containsKey(f))
          .toList();

      if (missingFields.isNotEmpty) {
        print('   ⚠️ Skipping exam due to missing fields: $missingFields');
        continue;
      }

      final List<dynamic> questions = List<dynamic>.from(
        examData['questions'] as Iterable<dynamic>,
      );

      // 2. Prepare Exam Document
      final Map<String, dynamic> examDoc = Map<String, dynamic>.from(examData)
        ..remove('questions');

      // Ensure numeric types
      examDoc['durationMinutes'] = (examDoc['durationMinutes'] as num).toInt();
      examDoc['xpReward'] = (examDoc['xpReward'] as num?)?.toInt() ?? 100;
      examDoc['questionCount'] = questions.length;
      examDoc['status'] = (examDoc['status'] as String?) ?? 'published';

      // Convert timestamps to DateTime (Firestore SDK converts to Timestamps)
      examDoc['createdAt'] = _parseDate(examDoc['createdAt']);
      examDoc['updatedAt'] = DateTime.now().toUtc();

      // 3. Batched Upload (Atomic)
      final batch = firestore.batch();

      // Create exam doc reference
      final examRef = firestore.collection('exams').doc();
      batch.set(examRef, examDoc);

      // Add questions to batch
      for (final dynamic q in questions) {
        final Map<String, dynamic> qData = Map<String, dynamic>.from(
          q as Map<dynamic, dynamic>,
        );
        qData['points'] = (qData['points'] as num?)?.toInt() ?? 1;
        qData['order'] = (qData['order'] as num?)?.toInt() ?? 0;

        final qRef = examRef.collection('questions').doc();
        batch.set(qRef, qData);
      }

      print(
        '   📤 Committing batch (1 exam + ${questions.length} questions)...',
      );
      await batch.commit();
      print('   ✅ Success! Document ID: ${examRef.id}');
    }

    print('\n==================================================');
    print('🎉 ALL TASKS COMPLETED SUCCESSFULLY');
    print('==================================================');
  } catch (e, stack) {
    print('\n❌ FATAL ERROR: $e');
    print(stack);
    exit(1);
  } finally {
    exit(0);
  }
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now().toUtc();
  try {
    if (value is String) return DateTime.parse(value).toUtc();
  } catch (_) {
    // Fall through to default
  }
  return DateTime.now().toUtc();
}
