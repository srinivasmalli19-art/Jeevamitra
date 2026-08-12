import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Professional gradient hero banner for top-level dashboard screens.
///
/// Layers a livestock/agriculture-themed icon motif under a dark gradient
/// overlay so [greeting]/[name]/[subtitle] stay legible regardless of the
/// motif's placement or the device's text-scale setting.
class HeroBanner extends StatelessWidget {
  /// Small muted line above [name] (e.g. a time-of-day greeting). Omit if
  /// the caller's greeting text already includes the name (as JeevaMitra's
  /// localized `greetingName` string does) to avoid rendering it twice.
  final String? greeting;
  final String name;
  final String? subtitle;
  final List<Widget> actions;

  const HeroBanner({
    super.key,
    this.greeting,
    required this.name,
    this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base brand gradient.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryLight, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Faint livestock/grazing motif — decorative only, never depended on
        // for information, so it can sit behind the readability overlay.
        const Positioned(
          right: -18,
          bottom: -14,
          child: Opacity(
            opacity: 0.10,
            child:
                Icon(Icons.agriculture_rounded, size: 130, color: Colors.white),
          ),
        ),
        const Positioned(
          right: 64,
          top: 4,
          child: Opacity(
            opacity: 0.08,
            child: Icon(Icons.grass_rounded, size: 56, color: Colors.white),
          ),
        ),
        // Dark gradient overlay, bottom-heavy, guarantees text contrast no
        // matter what sits behind it.
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
        // Content.
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
                      if (greeting != null)
                        Text(
                          greeting!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
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
