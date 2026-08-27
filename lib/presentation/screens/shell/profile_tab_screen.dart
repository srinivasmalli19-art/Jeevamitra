import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../shared/profile_screen.dart';

/// Profile tab of the Universal Shell. Thin role-forwarding wrapper over
/// the existing shared ProfileScreen — replaces the former
/// FarmerProfileScreen/ShepherdProfileScreen, which did exactly this same
/// forwarding but from two separate shell branches.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(currentUserDocProvider).valueOrNull;
    return ProfileScreen(role: doc?.role ?? 'farmer');
  }
}
