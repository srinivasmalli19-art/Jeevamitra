import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';

class EmergencyFab extends StatelessWidget {
  const EmergencyFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => context.push(RouteConstants.emergency),
      backgroundColor: AppColors.emergency,
      tooltip: 'Emergency',
      child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 28),
    );
  }
}
