import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth/auth_provider.dart';
import '../farmer/bookings/farmer_bookings_screen.dart';
import '../shepherd/bookings/shepherd_bookings_screen.dart';

/// Bookings tab of the Universal Shell. Reuses the existing Booking
/// Requests (owner-side) and My Bookings (booker-side) screens unchanged,
/// picked by default from the user's backend `role` — every profile can
/// both list land and book land, so each screen carries a "switch view"
/// action (added this sprint) reaching the other one directly.
class BookingsTabScreen extends ConsumerWidget {
  const BookingsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doc = ref.watch(currentUserDocProvider).valueOrNull;
    return (doc?.isFarmer ?? true)
        ? const FarmerBookingsScreen()
        : const ShepherdBookingsScreen();
  }
}
