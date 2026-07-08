import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth/auth_provider.dart';
import '../../widgets/common/jm_button.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  String? _selectedRole;

  Future<void> _proceed() async {
    if (_selectedRole == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Dev login may have already written a complete profile — don't overwrite it.
    final existing = ref.read(currentUserDocProvider).valueOrNull;
    if (existing != null && existing.isProfileComplete) {
      if (!context.mounted) return;
      context.go(existing.isFarmer
          ? RouteConstants.farmerDashboard
          : RouteConstants.shepherdDashboard);
      return;
    }

    final created = await ref.read(authNotifierProvider.notifier).createUserDoc(
      uid: user.uid,
      phone: user.phoneNumber ?? '',
      role: _selectedRole!,
      name: '',
    );
    if (!context.mounted) return;
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.go(RouteConstants.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Text('మీరు ఎవరు?', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text('I am a...', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xxl),
              _RoleTile(
                role: 'farmer',
                icon: Icons.agriculture_rounded,
                title: 'రైతు',
                titleEn: 'Farmer',
                description: 'మీ దగ్గర భూమి ఉంది, మేతకు అందించాలనుకుంటున్నారు',
                color: AppColors.primary,
                isSelected: _selectedRole == 'farmer',
                onTap: () => setState(() => _selectedRole = 'farmer'),
              ),
              const SizedBox(height: AppSpacing.base),
              _RoleTile(
                role: 'shepherd',
                icon: Icons.groups_rounded,
                title: 'గొర్రెల కాపరి',
                titleEn: 'Shepherd',
                description: 'మీ దగ్గర జంతువులు ఉన్నాయి, మేత భూమి కావాలి',
                color: AppColors.secondary,
                isSelected: _selectedRole == 'shepherd',
                onTap: () => setState(() => _selectedRole = 'shepherd'),
              ),
              const Spacer(),
              JmButton(
                label: 'Continue',
                onPressed: _selectedRole == null || isLoading ? null : _proceed,
                isLoading: isLoading,
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  final String role;
  final IconData icon;
  final String title;
  final String titleEn;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTile({
    required this.role,
    required this.icon,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withAlpha(26) : AppColors.surface,
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : AppColors.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    Text(titleEn, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
