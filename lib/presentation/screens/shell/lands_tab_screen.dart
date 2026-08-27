import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../farmer/lands/farmer_lands_screen.dart';
import '../shepherd/discover/shepherd_discover_screen.dart';

/// Lands tab of the Universal Shell. Reuses the existing My Lands (owner)
/// and Discover (browse/book) screens unchanged, picked by default from the
/// user's backend `role` — but since Universal Access means every profile
/// can both post AND discover land, each of the two screens carries a
/// "switch view" action (added this sprint) that opens the other one
/// directly, so the non-default view is always one tap away regardless of
/// role or profileType.
class LandsTabScreen extends ConsumerWidget {
  const LandsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(currentUserDocProvider).valueOrNull;
    return (doc?.isFarmer ?? true)
        ? const FarmerLandsScreen()
        : const ShepherdDiscoverScreen();
  }
}
