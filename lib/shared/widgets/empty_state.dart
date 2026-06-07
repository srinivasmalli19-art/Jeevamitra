// DEPRECATED — Replaced by lib/presentation/widgets/common/jm_empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
