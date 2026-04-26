import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bitwise_academy/core/errors/result.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';
import 'package:bitwise_academy/shared/services/user_repository.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchLeaderboardRequested extends LeaderboardEvent {}

// ─── State ───────────────────────────────────────────────────────────────────

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoadInProgress extends LeaderboardState {}

class LeaderboardLoadSuccess extends LeaderboardState {
  final List<UserEntity> topUsers;

  const LeaderboardLoadSuccess({required this.topUsers});

  @override
  List<Object?> get props => [topUsers];
}

class LeaderboardLoadFailure extends LeaderboardState {
  final String error;

  const LeaderboardLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

// ─── Bloc ────────────────────────────────────────────────────────────────────

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final UserRepository _userRepository;

  LeaderboardBloc({required UserRepository userRepository})
    : _userRepository = userRepository,
      super(LeaderboardInitial()) {
    on<FetchLeaderboardRequested>(_onFetchLeaderboardRequested);
  }

  Future<void> _onFetchLeaderboardRequested(
    FetchLeaderboardRequested event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoadInProgress());
    final result = await _userRepository.fetchLeaderboard();

    switch (result) {
      case Success(:final data):
        emit(LeaderboardLoadSuccess(topUsers: data));
      case Failure(:final exception):
        emit(LeaderboardLoadFailure(error: exception.message));
    }
  }
}
