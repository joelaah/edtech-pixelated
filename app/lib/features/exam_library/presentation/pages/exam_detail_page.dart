import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/attempt_bloc.dart';
import 'package:bitwise_academy/features/exam_library/presentation/bloc/exam_bloc.dart';
import 'package:bitwise_academy/shared/models/exam_model.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';

/// Exam detail / test configuration page.
///
/// Shows exam info and difficulty selection before starting.
class ExamDetailPage extends StatefulWidget {
  final String examId;

  const ExamDetailPage({required this.examId, super.key});

  @override
  State<ExamDetailPage> createState() => _ExamDetailPageState();
}

class _ExamDetailPageState extends State<ExamDetailPage> {
  String _selectedDifficulty = 'EASY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onPrimary),
          onPressed: () => context.go('/exams'),
        ),
        title: Text(
          'MISSION BRIEFING',
          style: AppTypography.headlineXs.copyWith(
            color: AppColors.secondaryFixed,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<AttemptBloc, AttemptState>(
        listener: (context, state) {
          if (state is AttemptInProgress) {
            context.go('/exams/${widget.examId}/take');
          } else if (state is AttemptFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<ExamBloc, ExamState>(
          builder: (context, examState) {
            ExamModel? exam;
            if (examState is ExamLoadSuccess) {
              try {
                exam = examState.exams.firstWhere((e) => e.id == widget.examId);
              } catch (_) {
                // Exam not found in the loaded list
              }
            }

            if (examState is ExamLoadInProgress) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (exam == null) {
              return Center(
                child: Text(
                  'MISSION DATA NOT FOUND',
                  style: AppTypography.headlineMd.copyWith(color: AppColors.error),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Exam header ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF101B34),
                          width: 8,
                        ),
                        right: BorderSide(
                          color: Color(0xFF101B34),
                          width: 8,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          color: AppColors.secondary,
                          child: Text(
                            exam.subject.toUpperCase(),
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          exam.title.toUpperCase(),
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.secondaryFixed,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          exam.description,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onPrimaryContainer,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Mission stats ──
                  Text(
                    'MISSION PARAMETERS',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildParamCard(
                            Icons.quiz, 'QUESTIONS', '${exam.questionCount}'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildParamCard(Icons.timer, 'DURATION',
                            '${exam.durationMinutes} MIN'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildParamCard(
                            Icons.star, 'XP REWARD', '+${exam.xpReward}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Difficulty selector ──
                  Text(
                    'SELECT DIFFICULTY',
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDifficultyOption(
                    'EASY',
                    'Standard questions, no time pressure.',
                    AppColors.secondary,
                    isSelected: _selectedDifficulty == 'EASY',
                    onTap: () => setState(() => _selectedDifficulty = 'EASY'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDifficultyOption(
                    'MEDIUM',
                    'Mixed difficulty, strict timer.',
                    AppColors.primary,
                    isSelected: _selectedDifficulty == 'MEDIUM',
                    onTap: () => setState(() => _selectedDifficulty = 'MEDIUM'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDifficultyOption(
                    'HARD',
                    'Advanced questions, bonus XP.',
                    AppColors.tertiary,
                    isSelected: _selectedDifficulty == 'HARD',
                    onTap: () => setState(() => _selectedDifficulty = 'HARD'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Start button ──
                  BlocBuilder<AttemptBloc, AttemptState>(
                    builder: (context, attemptState) {
                      final isLoading = attemptState is AttemptLoadInProgress;
                      return PixelButton(
                        label: isLoading ? 'INITIALIZING...' : 'BEGIN MISSION',
                        icon: isLoading ? Icons.hourglass_empty : Icons.play_arrow,
                        width: double.infinity,
                        onPressed: isLoading
                            ? () {}
                            : () {
                                final authState = context.read<AuthBloc>().state;
                                if (authState is AuthAuthenticated) {
                                  context.read<AttemptBloc>().add(
                                        StartAttemptRequested(
                                          examId: widget.examId,
                                          userId: authState.user.uid,
                                        ),
                                      );
                                }
                              },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParamCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.headlineSm.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(
    String label,
    String desc,
    Color color, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surfaceContainerLowest,
          border: Border.all(
            color: isSelected ? color : AppColors.outlineVariant,
            width: isSelected ? 4 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                border: Border.all(color: color, width: 3),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.headlineXs.copyWith(color: color),
                  ),
                  Text(
                    desc,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
