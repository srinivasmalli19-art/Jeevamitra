import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/geo_constants.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/dashboard_stat_card.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/alert_card.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/nearby_land_card.dart';
import '../../../widgets/explore/premium_vet_card.dart';
import 'quick_action_button.dart';

// All five sections below are always built for every profile — Universal
// Access — HomeDashboardScreen only ever changes the *order* it places
// them in (see home_priority.dart). None of them read `role`/`profileType`
// to decide whether to render; they render from whatever data actually
// exists for the signed-in user.

// ─── Section header (shared) ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Spacer(),
        if (onViewAll != null)
          TextButton(onPressed: onViewAll, child: Text(loc.viewAllBtn)),
      ],
    );
  }
}

// ─── Nearby Lands ──────────────────────────────────────────────────────────────

class NearbyLandsSection extends ConsumerWidget {
  const NearbyLandsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);
    final loc_ = locAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: loc.nearbyLandsLabel,
          onViewAll: () => context.go(RouteConstants.lands),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (loc_ == null)
          EmptyStateCard(
            icon: Icons.my_location_rounded,
            title: loc.locationRequiredTitle,
            subtitle: loc.locationNeededLandsMsg,
            buttonLabel: loc.discoverLandsBtn,
            onButtonTap: () => context.go(RouteConstants.lands),
          )
        else
          Consumer(builder: (context, ref, _) {
            final farmsAsync = ref.watch(nearbyFarmsProvider((
              lat: loc_.lat,
              lng: loc_.lng,
              radiusKm: GeoConstants.radiusNearby,
            )));
            return farmsAsync.when(
              loading: () => const JmShimmerList(count: 2, cardHeight: 200),
              error: (_, __) => const SizedBox.shrink(),
              data: (farms) {
                if (farms.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.landscape_rounded,
                    title: loc.nearbyLandsLabel,
                    subtitle: loc.noLandsYetSubtitle,
                  );
                }
                final ranked = farms
                    .map((f) => (
                          f,
                          GeoHashHelper.distanceKm(
                              loc_.lat, loc_.lng, f.lat, f.lng)
                        ))
                    .toList()
                  ..sort((a, b) => a.$2.compareTo(b.$2));
                return Column(
                  children: [
                    for (final (farm, distanceKm) in ranked.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: NearbyLandCard(
                          farm: farm,
                          distanceKm: distanceKm,
                          onViewDetails: () => context
                              .push(RouteConstants.shepherdLand(farm.id)),
                        ),
                      ),
                  ],
                );
              },
            );
          }),
      ],
    );
  }
}

// ─── My Lands ──────────────────────────────────────────────────────────────────

class MyLandsSection extends ConsumerWidget {
  const MyLandsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final farmsAsync = ref.watch(myFarmsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: loc.myLands,
          onViewAll: () => context.go(RouteConstants.lands),
        ),
        const SizedBox(height: AppSpacing.sm),
        farmsAsync.when(
          loading: () => const JmShimmerList(count: 1, cardHeight: 80),
          error: (_, __) => const SizedBox.shrink(),
          data: (farms) {
            if (farms.isEmpty) {
              return EmptyStateCard(
                icon: Icons.add_location_alt_rounded,
                title: loc.noLandsYetTitle,
                subtitle: loc.noLandsYetSubtitle,
                buttonLabel: loc.postLandLabel,
                onButtonTap: () => context.push(RouteConstants.farmerAddLand),
              );
            }
            final available = farms.where((f) => f.isAvailable).length;
            return Row(
              children: [
                Expanded(
                  child: DashboardStatCard(
                    label: loc.myLands,
                    value: '${farms.length}',
                    icon: Icons.landscape_rounded,
                    color: AppColors.primary,
                    onTap: () => context.go(RouteConstants.lands),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: DashboardStatCard(
                    label: loc.availableNow,
                    value: '$available',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    onTap: () => context.go(RouteConstants.lands),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Active Bookings (Booking Requests + My Bookings) ─────────────────────────

JmBadgeVariant _bookingVariant(String status) => switch (status) {
      'pending' => JmBadgeVariant.warning,
      'confirmed' => JmBadgeVariant.info,
      'active' => JmBadgeVariant.success,
      'completed' => JmBadgeVariant.neutral,
      _ => JmBadgeVariant.error,
    };

String _statusLabel(String status, AppLocalizations loc) => switch (status) {
      'pending' => loc.bookingPending,
      'confirmed' => loc.bookingConfirmed,
      'active' => loc.bookingActive,
      'completed' => loc.bookingCompleted,
      _ => loc.bookingCancelled,
    };

class ActiveBookingsSection extends ConsumerWidget {
  const ActiveBookingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final requestsAsync = ref.watch(farmerBookingsProvider);
    final myBookingsAsync = ref.watch(shepherdBookingsProvider);

    final isLoading = requestsAsync.isLoading || myBookingsAsync.isLoading;
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.activeBookingsLabel),
          const SizedBox(height: AppSpacing.sm),
          const JmShimmerList(count: 2, cardHeight: 80),
        ],
      );
    }

    final requests = requestsAsync.valueOrNull ?? [];
    final myBookings = myBookingsAsync.valueOrNull ?? [];

    // Not gated by role/profileType — shown whenever the data exists, so a
    // "Livestock Owner"-labeled user who also happens to own land still
    // sees their booking requests, and vice versa (Universal Access).
    if (requests.isEmpty && myBookings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.activeBookingsLabel),
          const SizedBox(height: AppSpacing.sm),
          EmptyStateCard(
            icon: Icons.event_note_rounded,
            title: loc.noBookingsYetTitle,
            subtitle: loc.noBookingsYetSubtitle,
            buttonLabel: loc.discoverLandsBtn,
            onButtonTap: () => context.go(RouteConstants.lands),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (requests.isNotEmpty) ...[
          _SectionHeader(
            title: loc.bookingRequestsLabel,
            onViewAll: () => context.go(RouteConstants.bookings),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final b in requests.take(2))
            _BookingPreviewRow(
              booking: b,
              role: 'farmer',
              title: b.shepherdName,
            ),
          if (myBookings.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (myBookings.isNotEmpty) ...[
          _SectionHeader(
            title: loc.myBookingsLabel,
            onViewAll: () => context.go(RouteConstants.bookings),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final b in myBookings.take(2))
            _BookingPreviewRow(
              booking: b,
              role: 'shepherd',
              title: b.farmTitle,
            ),
        ],
      ],
    );
  }
}

class _BookingPreviewRow extends StatelessWidget {
  final BookingModel booking;
  final String role;
  final String title;
  const _BookingPreviewRow({
    required this.booking,
    required this.role,
    required this.title,
  });

  static Color _avatarColor(String status) => switch (status) {
        'pending' => AppColors.warning,
        'confirmed' => AppColors.info,
        'active' => AppColors.success,
        'completed' => AppColors.textSecondary,
        _ => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(booking.status);
    final dateStr = DateFormat('MMM d').format(booking.checkIn);
    final fmt = NumberFormat.compact(locale: 'en_IN');
    final loc = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: () =>
            context.push(RouteConstants.bookingDetail(role, booking.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(color: AppColors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                    BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
                child: Icon(
                  role == 'farmer'
                      ? Icons.person_rounded
                      : Icons.landscape_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      loc.bookingSummaryMsg(booking.animalCount, dateStr,
                          fmt.format(booking.totalAmount)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              JmBadge(
                label: _statusLabel(booking.status, loc),
                variant: _bookingVariant(booking.status),
                small: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nearby Vets ───────────────────────────────────────────────────────────────

class NearbyVetsSection extends ConsumerWidget {
  const NearbyVetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);
    final loc_ = locAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: loc.nearbyVets,
          onViewAll: () => context.go(RouteConstants.vets),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (loc_ == null)
          EmptyStateCard(
            icon: Icons.my_location_rounded,
            title: loc.locationRequiredTitle,
            subtitle: loc.locationNeededVetsMsg,
            buttonLabel: loc.findVetLabel,
            onButtonTap: () => context.go(RouteConstants.vets),
          )
        else
          Consumer(builder: (context, ref, _) {
            final vetsAsync = ref.watch(nearbyVetsProvider((
              lat: loc_.lat,
              lng: loc_.lng,
              radiusKm: GeoConstants.radiusNearby,
            )));
            return vetsAsync.when(
              loading: () => const JmShimmerList(count: 2, cardHeight: 160),
              error: (_, __) => const SizedBox.shrink(),
              data: (vets) {
                if (vets.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.medical_services_rounded,
                    title: loc.noVetsFoundTitle,
                    subtitle: loc.noVetsFoundRadiusMsg(
                        GeoConstants.radiusNearby.toInt()),
                  );
                }
                final ranked = vets
                    .map((v) => (
                          v,
                          GeoHashHelper.distanceKm(
                              loc_.lat, loc_.lng, v.lat, v.lng)
                        ))
                    .toList()
                  ..sort((a, b) => a.$2.compareTo(b.$2));
                return Column(
                  children: [
                    for (final (vet, distanceKm) in ranked.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PremiumVetCard(
                          vet: vet,
                          distanceKm: distanceKm,
                          onViewProfile: () => context
                              .push(RouteConstants.vetDetail(vet.id)),
                        ),
                      ),
                  ],
                );
              },
            );
          }),
      ],
    );
  }
}

// ─── Disease Alerts ────────────────────────────────────────────────────────────

class DiseaseAlertsSection extends ConsumerWidget {
  const DiseaseAlertsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locAsync = ref.watch(locationProvider);
    final loc_ = locAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: loc.alertsLabel,
          onViewAll: () => context.push(RouteConstants.farmerExplore),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (loc_ == null)
          EmptyStateCard(
            icon: Icons.my_location_rounded,
            title: loc.locationRequiredTitle,
            subtitle: loc.locationNeededAlertsMsg,
            buttonLabel: loc.reportAlertTitle,
            onButtonTap: () => context.push(RouteConstants.reportAlert),
          )
        else
          Consumer(builder: (context, ref, _) {
            final alertsAsync = ref.watch(nearbyAlertsProvider((
              lat: loc_.lat,
              lng: loc_.lng,
              radiusKm: GeoConstants.radiusNearby,
            )));
            return alertsAsync.when(
              loading: () => const JmShimmerList(count: 2, cardHeight: 100),
              error: (_, __) => const SizedBox.shrink(),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return EmptyStateCard(
                    icon: Icons.health_and_safety_rounded,
                    title: loc.noActiveAlertsTitle,
                    subtitle: loc.noActiveAlertsMsg,
                    buttonLabel: loc.reportAlertTitle,
                    onButtonTap: () => context.push(RouteConstants.reportAlert),
                  );
                }
                final ranked = alerts
                    .map((a) => (
                          a,
                          GeoHashHelper.distanceKm(
                              loc_.lat, loc_.lng, a.lat, a.lng)
                        ))
                    .toList()
                  ..sort((a, b) => a.$2.compareTo(b.$2));
                return Column(
                  children: [
                    for (final (alert, distanceKm) in ranked.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AlertCard(
                          alert: alert,
                          distanceKm: distanceKm,
                          onReadMore: () => context
                              .push(RouteConstants.alertDetail(alert.id)),
                        ),
                      ),
                  ],
                );
              },
            );
          }),
      ],
    );
  }
}

// ─── Quick Actions ─────────────────────────────────────────────────────────────

// Compact single row of 4 (prototype treatment) — replaces the pre-Sprint
// 6A 2x2 grid of large `_ActionChip` cards. Every action's callback target
// is unchanged from before.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.quickActionsLabel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Icons.add_location_alt_rounded,
                label: loc.postLandLabel,
                color: AppColors.primary,
                onTap: () => context.push(RouteConstants.farmerAddLand),
              ),
            ),
            Expanded(
              child: QuickActionButton(
                icon: Icons.search_rounded,
                label: loc.findLandLabel,
                color: AppColors.secondary,
                onTap: () => context.go(RouteConstants.lands),
              ),
            ),
            Expanded(
              child: QuickActionButton(
                icon: Icons.medical_services_rounded,
                label: loc.findVetLabel,
                color: AppColors.info,
                onTap: () => context.go(RouteConstants.vets),
              ),
            ),
            Expanded(
              child: QuickActionButton(
                icon: Icons.coronavirus_rounded,
                label: loc.reportAlertTitle,
                color: AppColors.warning,
                onTap: () => context.push(RouteConstants.reportAlert),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
