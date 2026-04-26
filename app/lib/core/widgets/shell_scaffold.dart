import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// The main shell scaffold wrapping all authenticated routes.
///
/// Provides the retro top bar and chunky bottom navigation bar
/// consistent with the Neo-Arcade Editorial design system.
class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({required this.child, super.key});

  int _currentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/exams')) return 1;
    if (location.startsWith('/quests')) return 2;
    if (location.startsWith('/admin')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/exams');
      case 2:
        context.go('/quests');
      case 3:
        context.go('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: AppSpacing.bottomNavHeight,
        decoration: const BoxDecoration(
          color: AppColors.primaryContainer,
          border: Border(
            top: BorderSide(
              color: AppColors.onSurface,
              width: AppSpacing.borderThick,
            ),
          ),
        ),
        child: Row(
          children: List<Widget>.generate(4, (int index) {
            final bool isActive = currentIndex == index;
            const List<_NavItem> items = [
              _NavItem(icon: Icons.home, label: 'HERO'),
              _NavItem(icon: Icons.quiz, label: 'QUESTS'),
              _NavItem(icon: Icons.shopping_bag, label: 'SHOP'),
              _NavItem(icon: Icons.settings, label: 'CONFIG'),
            ];
            final _NavItem item = items[index];

            return Expanded(
              child: GestureDetector(
                onTap: () => _onTap(context, index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.secondary : Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: isActive
                            ? AppColors.secondaryFixed
                            : AppColors.surfaceContainerHighest,
                        size: 28,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: AppTypography.labelLg.copyWith(
                          color: isActive
                              ? AppColors.secondaryFixed
                              : AppColors.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
