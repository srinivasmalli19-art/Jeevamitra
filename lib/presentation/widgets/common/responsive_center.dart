import 'package:flutter/material.dart';

/// Clamps content to a comfortable reading/scanning width on tablets and
/// web, centering it, while staying full-width (a no-op) on phones. Never
/// changes phone layout since [maxWidth] only engages once the viewport
/// exceeds it.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 720});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
