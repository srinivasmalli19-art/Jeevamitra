import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';

class JmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool hasBorder;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const JmCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.hasBorder = false,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppSpacing.cardRadius;
    return Material(
      color: color ?? AppColors.surface,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: padding ?? AppSpacing.cardPadding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: hasBorder
                ? Border.all(color: AppColors.outline, width: 1)
                : null,
            boxShadow: shadows ?? AppShadows.card,
          ),
          child: child,
        ),
      ),
    );
  }
}
