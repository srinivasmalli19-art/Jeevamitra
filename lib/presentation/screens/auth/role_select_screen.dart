import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/user_profile_type.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../onboarding/choose_profile_screen.dart';

/// Post-auth fallback for the rare case an authenticated user has no
/// Firestore doc and no pending pre-auth profile selection (see
/// `OtpVerificationScreen._verify()`, which normally creates the doc
/// automatically from the profile chosen before Phone Login) — e.g. a
/// dev/test login that jumped straight to OTP. Renders the same
/// ChooseProfileScreen UI as the new pre-auth step, but creates the user
/// doc immediately on selection since an authenticated uid already exists.
class RoleSelectScreen extends ConsumerWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChooseProfileScreen(onContinue: _onContinue);
  }

  Future<void> _onContinue(
      BuildContext context, WidgetRef ref, UserProfileType selected) async {
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
      role: selected.backendRole,
      name: '',
      profileType: selected.storageValue,
    );
    if (!context.mounted) return;
    if (!created) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).genericErrorRetryMsg),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.go(RouteConstants.profileSetup);
  }
}
