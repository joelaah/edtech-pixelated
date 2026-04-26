import 'package:flutter/material.dart';

import 'package:bitwise_academy/core/constants/app_colors.dart';
import 'package:bitwise_academy/core/constants/app_spacing.dart';
import 'package:bitwise_academy/core/constants/app_typography.dart';

/// Neo-Arcade "Chunky" button with 8-bit shadow effect.
///
/// Mimics the physical arcade button press with a bottom-heavy
/// shadow that compresses on tap.
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const PixelButton({
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isLoading = false,
    this.icon,
    this.width,
    super.key,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isPrimary
        ? AppColors.secondary
        : AppColors.primary;
    final Color textColor = widget.isPrimary
        ? AppColors.onSecondary
        : AppColors.secondaryFixed;
    final Color shadowColor = widget.isPrimary
        ? AppColors.onSecondaryContainer
        : const Color(0xFF101B34);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTap: () {
        setState(() => _isPressed = false);
        widget.onPressed?.call();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.width,
        transform: Matrix4.translationValues(
          _isPressed ? 4 : 0,
          _isPressed ? 4 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(
              color: _isPressed ? Colors.transparent : shadowColor,
              width: _isPressed ? 0 : 8,
            ),
            right: BorderSide(
              color: _isPressed ? Colors.transparent : shadowColor,
              width: _isPressed ? 0 : 8,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: widget.isLoading
            ? Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: textColor,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.width != null
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: AppTypography.headlineXs.copyWith(
                      color: textColor,
                      letterSpacing: 2,
                    ),
                  ),
                  if (widget.icon != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Icon(widget.icon, color: textColor, size: 24),
                  ],
                ],
              ),
      ),
    );
  }
}
