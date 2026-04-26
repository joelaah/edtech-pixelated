import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/features/exam_library/presentation/bloc/exam_bloc.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';

/// Exam Library page showing available exams as arcade-styled cards.
class ExamListPage extends StatelessWidget {
  const ExamListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExamBloc, ExamState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          body: CustomScrollView(
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EXAM LIBRARY',
                        style: AppTypography.headlineSm.copyWith(
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select your challenge, warrior.',
                        style: AppTypography.bodyLg.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filter chips ──
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(context, 'ALL', null, state),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(context, 'MATH', 'MATH', state),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(context, 'PHYSICS', 'PHYSICS', state),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(
                          context,
                          'CHEMISTRY',
                          'CHEMISTRY',
                          state,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _buildFilterChip(context, 'CS', 'CS', state),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Exam cards ──
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: _buildExamsList(state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamsList(ExamState state) {
    if (state is ExamLoadInProgress) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    } else if (state is ExamLoadFailure) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            'ERROR: ${state.message}',
            style: AppTypography.bodyLg.copyWith(color: AppColors.error),
          ),
        ),
      );
    } else if (state is ExamLoadSuccess) {
      if (state.exams.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'NO EXAMS FOUND FOR THIS SUBJECT.',
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final exam = state.exams[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildExamCard(
              context,
              examId: exam.id,
              title: exam.title,
              subject: exam.subject,
              difficulty: exam.difficultyTier.displayName,
              difficultyColor: _getDifficultyColor(exam.difficultyTier),
              questions: exam.questionCount,
              duration: exam.durationMinutes,
              xp: exam.xpReward,
            ),
          );
        }, childCount: state.exams.length),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Color _getDifficultyColor(DifficultyTier tier) {
    return switch (tier) {
      DifficultyTier.easy => AppColors.secondary,
      DifficultyTier.medium => AppColors.primary,
      DifficultyTier.hard => AppColors.tertiary,
      DifficultyTier.ultraHard => AppColors.tertiaryContainer,
    };
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String? filterValue,
    ExamState state,
  ) {
    bool isActive = false;
    if (state is ExamLoadSuccess) {
      isActive = state.activeSubjectFilter == filterValue;
    } else if (state is ExamInitial && filterValue == null) {
      isActive = true;
    }

    return GestureDetector(
      onTap: () {
        context.read<ExamBloc>().add(
          LoadExamsRequested(subjectFilter: filterValue),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : AppColors.surfaceContainerHighest,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Text(
          label,
          style: AppTypography.headlineXs.copyWith(
            color: isActive
                ? AppColors.secondaryFixed
                : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(
    BuildContext context, {
    required String examId,
    required String title,
    required String subject,
    required String difficulty,
    required Color difficultyColor,
    required int questions,
    required int duration,
    required int xp,
  }) {
    return PixelCard(
      onTap: () => context.go('/exams/$examId'),
      showShadow: true,
      badge: difficulty,
      badgeColor: difficultyColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Subject tag
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 2,
            ),
            color: AppColors.surfaceContainerHigh,
            child: Text(
              subject,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Text(
            title,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.primary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Stats row
          Row(
            children: [
              _buildStatPill(Icons.quiz, '$questions Q'),
              const SizedBox(width: AppSpacing.md),
              _buildStatPill(Icons.timer, '${duration}m'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                color: AppColors.secondaryContainer,
                child: Text(
                  '+$xp XP',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodyLg.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
