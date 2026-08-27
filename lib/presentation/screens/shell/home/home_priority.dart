import '../../../../domain/entities/user_profile_type.dart';

/// The reorderable content sections of the unified Home Dashboard.
///
/// Deliberately excludes Quick Actions — that block is navigation
/// shortcuts, not profile-personalized content, so it always renders first
/// regardless of profile (matching both legacy dashboards, which also put
/// their quick-action row before anything else).
///
/// CRITICAL: this enum/ordering is a *display-order* concept only. Nothing
/// in HomeDashboardScreen uses it to decide whether a section is shown —
/// every section is always built for every profile; only the order
/// changes. See homeSectionPriority's doc comment for what "priority"
/// means in relation to the product spec's per-profile lists.
enum HomeSection { nearbyLands, myLands, activeBookings, nearbyVets, diseaseAlerts }

/// Returns all five [HomeSection]s in the order [profileType] should see
/// them, per the product spec's per-profile priority lists. Every profile
/// gets every section — Universal Access — this only reorders them.
///
/// The spec's per-profile lists don't map 1:1 onto these five sections in
/// every case; two documented interpretations reconcile the difference:
///  - "Availability" (listed under Fodder Land Provider) isn't a separate
///    Home section — availability management already lives inside each
///    land's own screen (Land Detail → Availability Calendar, unchanged
///    this sprint) and isn't part of the six sections the brief names as
///    mandatory for Home. It's treated as emphasis on [myLands], not a
///    7th section.
///  - "Booking Requests" and "My Bookings" (split out separately under
///    "Both") are the two possible flavors of the single [activeBookings]
///    section, which renders both flavors together whenever the signed-in
///    user actually has data for both — not gated by profileType at all,
///    since a Livestock-Owner-labeled user is just as able to own land and
///    receive requests as anyone else (Universal Access).
///
/// Any section the spec's list doesn't explicitly rank for a given profile
/// is appended after the ranked ones, in a fixed, stable order — it must
/// still be fully present, just deprioritized, never hidden.
List<HomeSection> homeSectionPriority(UserProfileType profileType) {
  const all = HomeSection.values;
  final ranked = switch (profileType) {
    UserProfileType.livestockOwner => [
        HomeSection.nearbyLands,
        HomeSection.activeBookings,
        HomeSection.nearbyVets,
        HomeSection.diseaseAlerts,
      ],
    UserProfileType.fodderLandProvider => [
        HomeSection.myLands,
        HomeSection.activeBookings,
        HomeSection.diseaseAlerts,
      ],
    UserProfileType.both => [
        HomeSection.myLands,
        HomeSection.nearbyLands,
        HomeSection.activeBookings,
        HomeSection.nearbyVets,
        HomeSection.diseaseAlerts,
      ],
  };
  final remaining = all.where((s) => !ranked.contains(s));
  return [...ranked, ...remaining];
}
