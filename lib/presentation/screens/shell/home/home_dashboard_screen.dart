import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/user_profile_type.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/notifications/notification_providers.dart';
import '../../../widgets/common/responsive_center.dart';
import 'home_priority.dart';
import 'home_sections.dart';
import 'home_stats_grid.dart';

/// The single Home tab of the Universal Shell.
///
/// Sprint 6A hierarchy (prototype-driven — see jeevamitra.html): compact
/// header → greeting (cream) → HomeStatsGrid (2x2 cross-domain summary) →
/// Quick Actions (compact row of 4) → profile-priority content sections.
/// Every section is still built for every profile — Universal Access —
/// only the *order* changes, driven by the user's effectiveProfileType
/// (falls back to role-inference for legacy accounts, via the existing
/// UserDoc.effectiveProfileType getter — no migration).
class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Nearby Lands/Vets/Disease Alerts/HomeStatsGrid all need a location;
    // fetch once up front rather than duplicating this in every section
    // (matches the existing pattern in shepherd_discover_screen.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loc = ref.read(locationProvider);
      if (!loc.hasValue || loc.valueOrNull == null) {
        ref.read(locationProvider.notifier).fetch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;
    final loc = AppLocalizations.of(context);
    // userDoc is guaranteed non-null by the router's redirect guard before
    // this screen is ever reached; `both` is a neutral, defensive fallback
    // only for the brief instant before the first Firestore snapshot lands.
    final order = homeSectionPriority(
      userDoc?.effectiveProfileType ?? UserProfileType.both,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // Prototype-fidelity: the reference is presented as a narrow
      // phone-width canvas even on desktop web, not a wide reading column.
      // Wrapping the whole scroll view (header included) rather than only
      // the content below it, so the header doesn't stay full-bleed while
      // the rest of the page is constrained. No-op on phone-width
      // viewports (ResponsiveCenter's existing, unchanged behavior) — the
      // shared default (720px, used by 11 other screens) is untouched;
      // this is a per-call-site override exactly like settings_screen.dart
      // and profile_screen.dart already use for their own narrower widths.
      body: ResponsiveCenter(
        maxWidth: 430,
        child: CustomScrollView(
          slivers: [
            const _Header(),
            SliverToBoxAdapter(
              child: _Greeting(name: userDoc?.name ?? loc.profile),
            ),
            SliverPadding(
              padding: AppSpacing.screenPadding,
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    const HomeStatsGrid(),
                    const SizedBox(height: AppSpacing.xxl),
                    const QuickActionsSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    for (final section in order) ...[
                      switch (section) {
                        HomeSection.nearbyLands => const NearbyLandsSection(),
                        HomeSection.myLands => const MyLandsSection(),
                        HomeSection.activeBookings =>
                          const ActiveBookingsSection(),
                        HomeSection.nearbyVets => const NearbyVetsSection(),
                        HomeSection.diseaseAlerts =>
                          const DiseaseAlertsSection(),
                      },
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Best-of-day greeting label — pure presentation logic, no existing
/// daypart utility was found in the codebase (grepped for "Good morning" /
/// "DateTime.now().hour" — none), so this is the smallest helper needed.
String daypartGreetingLabel(AppLocalizations loc, {DateTime? now}) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return loc.goodMorningLabel;
  if (hour < 17) return loc.goodAfternoonLabel;
  return loc.goodEveningLabel;
}

// ─── Compact header ────────────────────────────────────────────────────────────
//
// Replaces the old 150px SliverAppBar + HeroBanner (which carried the
// greeting inside the green banner, plus a mic icon) — prototype shows a
// compact ~90-100px bar with just the brand + location, and the greeting
// living below it on cream. Not confirmed by the prototype: the header's
// scroll-pinning behavior (the reference is a static screenshot) — left
// as a plain scrolling sliver rather than guessing at pinning.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;
    final loc = AppLocalizations.of(context);

    // Real location data (village/district), not a hard-coded string —
    // the prototype's "VIJAYAWADA · KRISHNA DISTRICT" is illustrative
    // content, not a fixed value to bake in.
    final locationParts = [userDoc?.village, userDoc?.district]
        .where((p) => p != null && p.isNotEmpty)
        .map((p) => p!.toUpperCase())
        .toList();
    final locationLine = locationParts.isEmpty ? null : locationParts.join(' · ');

    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        color: AppColors.primaryDark,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JeevaMitra',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      if (locationLine != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          locationLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Not confirmed by the prototype which existing feature
                // this icon should open (glyph reads as a map/book) —
                // mapped to the existing Explore Map screen as the closest
                // real, already-built destination rather than inventing a
                // new one.
                _HeaderIconButton(
                  icon: Icons.map_outlined,
                  tooltip: loc.mapViewTooltip,
                  onTap: () => context.push(RouteConstants.shepherdExploreMap),
                ),
                const SizedBox(width: AppSpacing.sm),
                _HeaderIconButton(
                  icon: Icons.notifications_outlined,
                  tooltip: loc.notifications,
                  badgeCount: unread,
                  onTap: () => context.push(RouteConstants.notifications),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha(38),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Badge(
            isLabelVisible: badgeCount > 0,
            label: Text(badgeCount > 9 ? '9+' : '$badgeCount'),
            child: Tooltip(
              message: tooltip,
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Greeting (below the header, on cream) ─────────────────────────────────────

class _Greeting extends StatelessWidget {
  final String name;
  const _Greeting({required this.name});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.lg, AppSpacing.base, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            daypartGreetingLabel(loc).toUpperCase(),
            style: const TextStyle(
              color: AppColors.actionPrimaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loc.namasteNameLabel(name),
            style: AppTypography.serifDisplay(size: 28),
          ),
        ],
      ),
    );
  }
}
