// Pure-function tests for the unified Home Dashboard's profile-priority
// ordering (Sprint 5). No widget pumping needed — homeSectionPriority()
// takes a UserProfileType and returns a List<HomeSection>, so these run as
// plain Dart unit tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/domain/entities/user_profile_type.dart';
import 'package:jeevamitra/presentation/screens/shell/home/home_priority.dart';

void main() {
  group('homeSectionPriority — per-profile ordering matches the spec', () {
    test('Livestock Owner: Nearby Lands, Active Bookings, Nearby Vets, '
        'Disease Alerts, then My Lands (not in the spec\'s top 4, still '
        'present)', () {
      final order = homeSectionPriority(UserProfileType.livestockOwner);
      expect(order, [
        HomeSection.nearbyLands,
        HomeSection.activeBookings,
        HomeSection.nearbyVets,
        HomeSection.diseaseAlerts,
        HomeSection.myLands,
      ]);
    });

    test('Fodder Land Provider: My Lands, Active Bookings (Booking '
        'Requests), Disease Alerts, then Nearby Lands/Nearby Vets (not in '
        'the spec\'s top items, still present)', () {
      final order = homeSectionPriority(UserProfileType.fodderLandProvider);
      expect(order, [
        HomeSection.myLands,
        HomeSection.activeBookings,
        HomeSection.diseaseAlerts,
        HomeSection.nearbyLands,
        HomeSection.nearbyVets,
      ]);
    });

    test('Both: My Lands, Nearby Lands, Active Bookings, Nearby Vets, '
        'Disease Alerts — matches the spec\'s 6-item list once Booking '
        'Requests/My Bookings are recognized as the two flavors of the '
        'single Active Bookings section', () {
      final order = homeSectionPriority(UserProfileType.both);
      expect(order, [
        HomeSection.myLands,
        HomeSection.nearbyLands,
        HomeSection.activeBookings,
        HomeSection.nearbyVets,
        HomeSection.diseaseAlerts,
      ]);
    });
  });

  group('homeSectionPriority — Universal Access at the ordering level', () {
    for (final profile in UserProfileType.values) {
      test('${profile.name}: every one of the 5 Home sections is present '
          'exactly once — priority only ever reorders, never drops', () {
        final order = homeSectionPriority(profile);
        expect(order.length, HomeSection.values.length);
        expect(order.toSet(), HomeSection.values.toSet());
      });
    }
  });

  group('homeSectionPriority — legacy accounts (no stored profileType)', () {
    test('a legacy shepherd-role account infers livestockOwner and still '
        'gets a complete, valid ordering', () {
      final inferred = UserProfileType.inferFromRole('shepherd');
      expect(inferred, UserProfileType.livestockOwner);
      final order = homeSectionPriority(inferred);
      expect(order.toSet(), HomeSection.values.toSet());
    });

    test('a legacy farmer-role account infers fodderLandProvider and still '
        'gets a complete, valid ordering', () {
      final inferred = UserProfileType.inferFromRole('farmer');
      expect(inferred, UserProfileType.fodderLandProvider);
      final order = homeSectionPriority(inferred);
      expect(order.toSet(), HomeSection.values.toSet());
    });
  });
}
