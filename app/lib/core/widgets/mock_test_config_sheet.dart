import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';
import 'package:bitwise_academy/core/widgets/pixel_button.dart';

/// Configuration result returned when the user confirms their mock test setup.
class MockTestConfig {
  final String subject;
  final String difficulty;
  final String group;

  const MockTestConfig({
    required this.subject,
    required this.difficulty,
    required this.group,
  });
}

/// Shows a Neo-Arcade styled bottom sheet for configuring a random mock test.
///
/// Returns a [MockTestConfig] if the user confirms, or `null` if dismissed.
Future<MockTestConfig?> showMockTestConfigSheet(BuildContext context) {
  return showModalBottomSheet<MockTestConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _MockTestConfigSheet(),
  );
}

class _MockTestConfigSheet extends StatefulWidget {
  const _MockTestConfigSheet();

  @override
  State<_MockTestConfigSheet> createState() => _MockTestConfigSheetState();
}

class _MockTestConfigSheetState extends State<_MockTestConfigSheet> {
  String? _selectedSubject;
  String? _selectedDifficulty;
  String? _selectedGroup;

  // Placeholder lists — update these to match your Obsidian frontmatter values.
  static const List<String> _subjects = [
    'Mathematics',
    'Reasoning',
    'English',
    'General Knowledge',
    'Science',
    'History',
    'Geography',
    'Polity',
    'Economics',
  ];

  static const List<String> _groups = [
    'MPSC Group A',
    'MPSC Group B',
    'MPSC Group C',
    'SSC CGL',
    'SSC CHSL',
    'Practice',
  ];

  static const List<String> _difficulties = [
    'easy',
    'medium',
    'hard',
    'ultra_hard',
  ];

  static const Map<String, String> _difficultyLabels = {
    'easy': 'EASY',
    'medium': 'MEDIUM',
    'hard': 'HARD',
    'ultra_hard': 'ULTRA-HARD',
  };

  static const Map<String, Color> _difficultyColors = {
    'easy': AppColors.secondary,
    'medium': AppColors.primary,
    'hard': AppColors.tertiary,
    'ultra_hard': AppColors.tertiaryContainer,
  };

  bool get _isValid =>
      _selectedSubject != null &&
      _selectedDifficulty != null &&
      _selectedGroup != null;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.primary, width: 4),
          left: BorderSide(color: AppColors.primary, width: 4),
          right: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Handle bar ──
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  color: AppColors.outlineVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Title ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: AppColors.secondaryFixed,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'CONFIGURE MOCK TEST',
                      style: AppTypography.headlineXs.copyWith(
                        color: AppColors.secondaryFixed,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Subject selector ──
              _buildSectionLabel('SUBJECT'),
              const SizedBox(height: AppSpacing.sm),
              _buildPixelDropdown<String>(
                value: _selectedSubject,
                hint: 'Select subject...',
                items: _subjects,
                labelBuilder: (s) => s.toUpperCase(),
                onChanged: (v) => setState(() => _selectedSubject = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Group selector ──
              _buildSectionLabel('GROUP'),
              const SizedBox(height: AppSpacing.sm),
              _buildPixelDropdown<String>(
                value: _selectedGroup,
                hint: 'Select group...',
                items: _groups,
                labelBuilder: (s) => s.toUpperCase(),
                onChanged: (v) => setState(() => _selectedGroup = v),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Difficulty selector (chip-style) ──
              _buildSectionLabel('DIFFICULTY'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _difficulties.map((d) {
                  final isSelected = _selectedDifficulty == d;
                  final color =
                      _difficultyColors[d] ?? AppColors.onSurfaceVariant;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDifficulty = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerLowest,
                        border: Border.all(
                          color: isSelected ? color : AppColors.outlineVariant,
                          width: isSelected ? 3 : 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isSelected ? color : Colors.transparent,
                              border: Border.all(color: color, width: 2),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _difficultyLabels[d] ?? d.toUpperCase(),
                            style: AppTypography.headlineXs.copyWith(
                              color: isSelected
                                  ? color
                                  : AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Start button ──
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isValid ? 1.0 : 0.4,
                child: PixelButton(
                  label: 'START MISSION',
                  icon: Icons.play_arrow,
                  width: double.infinity,
                  onPressed: _isValid
                      ? () {
                          Navigator.of(context).pop(
                            MockTestConfig(
                              subject: _selectedSubject!,
                              difficulty: _selectedDifficulty!,
                              group: _selectedGroup!,
                            ),
                          );
                        }
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: AppTypography.headlineXs.copyWith(color: AppColors.primary),
    );
  }

  Widget _buildPixelDropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(
          color: value != null ? AppColors.primary : AppColors.outlineVariant,
          width: value != null ? 3 : 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceContainerLowest,
          hint: Text(
            hint,
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.primary,
            size: 28,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: AppTypography.headlineXs.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
