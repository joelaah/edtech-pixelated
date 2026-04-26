import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_card.dart';
import 'package:bitwise_academy/features/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:bitwise_academy/shared/models/user_entity.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<LeaderboardBloc>().add(FetchLeaderboardRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
        builder: (context, state) {
          if (state is LeaderboardLoadInProgress) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is LeaderboardLoadFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        border: Border.all(color: AppColors.error, width: 3),
                      ),
                      child: const Icon(
                        Icons.wifi_off,
                        color: AppColors.error,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'FAILED TO LOAD',
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Could not fetch the leaderboard.\nCheck your connection and try again.',
                      style: AppTypography.bodyLg.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    GestureDetector(
                      onTap: () => context.read<LeaderboardBloc>().add(
                        FetchLeaderboardRequested(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border: Border.all(
                            color: AppColors.primaryContainer,
                            width: 3,
                          ),
                        ),
                        child: Text(
                          'RETRY',
                          style: AppTypography.headlineXs.copyWith(
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is LeaderboardLoadSuccess) {
            return CustomScrollView(
              slivers: [
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final user = state.topUsers[index];
                      return _buildLeaderboardTile(user, index + 1);
                    }, childCount: state.topUsers.length),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          64,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        color: AppColors.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'HALL OF FAME',
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.secondaryFixed,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Top players ranked by total XP earned.',
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(UserEntity user, int rank) {
    Color rankColor = AppColors.primary;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey;
    if (rank == 3) rankColor = Colors.brown;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: PixelCard(
        borderColor: rank <= 3 ? rankColor : AppColors.outlineVariant,
        backgroundColor: rank == 1
            ? Colors.amber.withValues(alpha: 0.05)
            : AppColors.surfaceContainerLowest,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rankColor,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: AppTypography.headlineXs.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (user.avatarUrl != null)
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(user.avatarUrl!),
              )
            else
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(Icons.person, color: AppColors.primary),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.toUpperCase(),
                    style: AppTypography.headlineXs.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    'LEVEL ${user.level}',
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.xp} XP',
                  style: AppTypography.headlineXs.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'TOTAL SCORE',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
