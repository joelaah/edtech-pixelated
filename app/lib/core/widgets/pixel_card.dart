import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Neo-Arcade card with recessed inner shadow.
///
/// The card uses `surfaceContainerLowest` with a border-bottom/right
/// to create a "slotted into a machine" effect per DESIGN.md.
class PixelCard extends StatefulWidget {
  final Widget child;
  final String? badge;
  final Color? badgeColor;
  final EdgeInsets? padding;
  final bool showShadow;
  final VoidCallback? onTap;

  const PixelCard({
    required this.child,
    this.badge,
    this.badgeColor,
    this.padding,
    this.showShadow = false,
    this.onTap,
    super.key,
  });

  @override
  State<PixelCard> createState() => _PixelCardState();
}

class _PixelCardState extends State<PixelCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double scale = _isPressed ? 0.98 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTap: () {
          setState(() => _isPressed = false);
          debugPrint('PIXEL_CARD: Tap registered');
          widget.onTap?.call();
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: widget.onTap != null ? scale : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: const Border(
                    bottom: BorderSide(
                      color: AppColors.primary,
                      width: AppSpacing.borderThick,
                    ),
                  ),
                  boxShadow: widget.showShadow
                      ? [
                          BoxShadow(
                            color: _isHovered && widget.onTap != null 
                                ? AppColors.shadowTinted.withValues(alpha: 0.8)
                                : AppColors.shadowTinted,
                            offset: _isHovered && widget.onTap != null 
                                ? const Offset(6, 6) 
                                : const Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: widget.child,
              ),
              if (widget.badge != null)
                Positioned(
                  top: -12,
                  left: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm + 4,
                      vertical: AppSpacing.xs,
                    ),
                    color: widget.badgeColor ?? AppColors.tertiary,
                    child: Text(
                      widget.badge!,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

