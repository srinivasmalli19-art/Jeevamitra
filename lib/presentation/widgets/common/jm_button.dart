import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum JmButtonVariant { primary, secondary, outline, ghost, danger }
enum JmButtonSize { sm, md, lg }

class JmButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final JmButtonVariant variant;
  final JmButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  const JmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = JmButtonVariant.primary,
    this.size = JmButtonSize.md,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final height = switch (size) {
      JmButtonSize.sm => AppSpacing.buttonHeightSm,
      JmButtonSize.md => AppSpacing.buttonHeight,
      JmButtonSize.lg => 60.0,
    };
    final fontSize = switch (size) {
      JmButtonSize.sm => 13.0,
      JmButtonSize.md => 16.0,
      JmButtonSize.lg => 18.0,
    };

    Widget child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: fontSize + 2),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(trailingIcon, size: fontSize + 2),
              ],
            ],
          );

    final style = _buildStyle(height);

    if (fullWidth) {
      child = SizedBox(width: double.infinity, child: child);
    }

    return switch (variant) {
      JmButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      JmButtonVariant.ghost || JmButtonVariant.secondary => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      _ => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
    };
  }

  Color get _foregroundColor => switch (variant) {
    JmButtonVariant.primary => Colors.white,
    JmButtonVariant.danger => Colors.white,
    JmButtonVariant.secondary => AppColors.secondaryDark,
    JmButtonVariant.outline => AppColors.primary,
    JmButtonVariant.ghost => AppColors.primary,
  };

  ButtonStyle _buildStyle(double height) {
    final bg = switch (variant) {
      JmButtonVariant.primary => AppColors.primary,
      JmButtonVariant.danger => AppColors.error,
      JmButtonVariant.secondary => AppColors.secondaryContainer,
      JmButtonVariant.outline => Colors.transparent,
      JmButtonVariant.ghost => Colors.transparent,
    };
    final fg = _foregroundColor;
    final minSize = Size(fullWidth ? double.infinity : 0, height);

    return switch (variant) {
      JmButtonVariant.outline => OutlinedButton.styleFrom(
          foregroundColor: fg,
          minimumSize: minSize,
          side: BorderSide(
            color: variant == JmButtonVariant.danger ? AppColors.error : AppColors.primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        ),
      JmButtonVariant.ghost => TextButton.styleFrom(
          foregroundColor: fg,
          minimumSize: minSize,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        ),
      _ => ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: minSize,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        ),
    };
  }
}
