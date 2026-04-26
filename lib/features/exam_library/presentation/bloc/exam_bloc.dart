import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/features/exam_library/data/repositories/exam_repository.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

// ── Events ──

sealed class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch exams. Optionally filter by a subject.
final class LoadExamsRequested extends ExamEvent {
  final String? subjectFilter;

  const LoadExamsRequested({this.subjectFilter});

  @override
  List<Object?> get props => [subjectFilter];
}

/// Internal event for when the exams stream emits new data.
final class _ExamsUpdated extends ExamEvent {
  final List<ExamModel> exams;
  final String? activeSubjectFilter;

  const _ExamsUpdated(this.exams, {this.activeSubjectFilter});

  @override
  List<Object?> get props => [exams, activeSubjectFilter];
}

/// Internal event for when the exams stream emits an error.
final class _ExamsError extends ExamEvent {
  final String message;

  const _ExamsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── States ──

sealed class ExamState extends Equatable {
  const ExamState();

  @override
  List<Object?> get props => [];
}

final class ExamInitial extends ExamState {
  const ExamInitial();
}

final class ExamLoadInProgress extends ExamState {
  const ExamLoadInProgress();
}

final class ExamLoadSuccess extends ExamState {
  final List<ExamModel> exams;
  final String? activeSubjectFilter;

  const ExamLoadSuccess({
    required this.exams,
    this.activeSubjectFilter,
  });

  @override
  List<Object?> get props => [exams, activeSubjectFilter];
}

final class ExamLoadFailure extends ExamState {
  final String message;

  const ExamLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// ── BLoC ──

/// Manages fetching and filtering of published exams via a real-time stream.
class ExamBloc extends Bloc<ExamEvent, ExamState> {
  final ExamRepository _examRepository;
  StreamSubscription<Result<List<ExamModel>>>? _examsSubscription;

  ExamBloc({required ExamRepository examRepository})
      : _examRepository = examRepository,
        super(const ExamInitial()) {
    on<LoadExamsRequested>(_onLoadExamsRequested);
    on<_ExamsUpdated>(_onExamsUpdated);
    on<_ExamsError>(_onExamsError);
  }

  Future<void> _onLoadExamsRequested(
    LoadExamsRequested event,
    Emitter<ExamState> emit,
  ) async {
    emit(const ExamLoadInProgress());

    await _examsSubscription?.cancel();
    
    _examsSubscription = _examRepository.watchPublishedExams().listen(
      (result) {
        switch (result) {
          case Success(:final data):
            add(_ExamsUpdated(data, activeSubjectFilter: event.subjectFilter));
          case Failure(:final exception):
            add(_ExamsError(exception.message));
        }
      },
      onError: (Object? error) {
        add(_ExamsError(error.toString()));
      },
    );
  }

  void _onExamsUpdated(_ExamsUpdated event, Emitter<ExamState> emit) {
    List<ExamModel> filteredExams = event.exams;
    if (event.activeSubjectFilter != null && event.activeSubjectFilter!.isNotEmpty) {
      filteredExams = event.exams
          .where((exam) => exam.subject.toUpperCase() == event.activeSubjectFilter!.toUpperCase())
          .toList();
    }

    emit(ExamLoadSuccess(
      exams: filteredExams,
      activeSubjectFilter: event.activeSubjectFilter,
    ));
  }

  void _onExamsError(_ExamsError event, Emitter<ExamState> emit) {
    emit(ExamLoadFailure(message: event.message));
  }

  @override
  Future<void> close() {
    _examsSubscription?.cancel();
    return super.close();
  }
}
