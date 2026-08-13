import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Explore's hero header — same gradient/motif/overlay language as the
/// Farmer Dashboard's HeroBanner (dark gradient overlay over the brand
/// gradient, guaranteeing text contrast regardless of the decorative
/// motif), tailored for a section header rather than a personalized
/// greeting: a title, a subtitle, and an optional trailing actions row.
class ExploreHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Widget> actions;

  const ExploreHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.travel_explore_rounded,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Faint decorative motif — purely visual, never load-bearing for
        // information, matching HeroBanner's approach.
        Positioned(
          right: -16,
          bottom: -12,
          child: Opacity(
            opacity: 0.10,
            child: Icon(icon, size: 120, color: Colors.white),
          ),
        ),
        const Positioned(
          right: 70,
          top: 0,
          child: Opacity(
            opacity: 0.08,
            child: Icon(Icons.eco_rounded, size: 48, color: Colors.white),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x59000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.4, 1.0],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, AppSpacing.sm, AppSpacing.sm, AppSpacing.base),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: actions),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
