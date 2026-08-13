import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../providers/notifications/notification_providers.dart';
import '../../../widgets/common/dashboard_stat_card.dart';
import '../../../widgets/common/hero_banner.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/explore/empty_state_card.dart';

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

class ShepherdDashboardScreen extends ConsumerWidget {
  const ShepherdDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _Header(name: userDoc?.name ?? loc.roleShepherd, village: userDoc?.village),
          const SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverToBoxAdapter(
              child: ResponsiveCenter(
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.sm),
                    _QuickActions(),
                    SizedBox(height: AppSpacing.xl),
                    _OverviewStats(),
                    SizedBox(height: AppSpacing.xl),
                    _ActiveTripBanner(),
                    _RecentBookings(),
                    SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sliver header ─────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final String name;
  final String? village;
  const _Header({required this.name, this.village});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final loc = AppLocalizations.of(context);

    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.secondaryDark,
      elevation: 0,
      actions: [
        IconButton(
          tooltip: loc.voiceAssistantTooltip,
          onPressed: () => context.push(RouteConstants.assistant),
          icon: const Icon(Icons.mic_rounded, color: Colors.white),
        ),
        IconButton(
          tooltip: loc.notifications,
          onPressed: () => context.push(RouteConstants.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: HeroBanner(
          name: loc.greetingName(name),
          subtitle: village,
          subtitleIcon: village != null ? Icons.location_on_rounded : null,
          gradientColors: const [AppColors.secondaryDark, AppColors.secondary],
        ),
      ),
    );
  }
}

// ─── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Row(
      children: [
        _ActionChip(
          icon: Icons.search_rounded,
          label: loc.findLandLabel,
          color: AppColors.secondary,
          onTap: () => context.go(RouteConstants.shepherdDiscover),
        ),
        const SizedBox(width: AppSpacing.md),
        _ActionChip(
          icon: Icons.medical_services_rounded,
          label: loc.findVetLabel,
          color: AppColors.error,
          onTap: () => context.go(RouteConstants.shepherdVets),
        ),
        const SizedBox(width: AppSpacing.md),
        _ActionChip(
          icon: Icons.calendar_month_rounded,
          label: loc.myTripsLabel,
          color: AppColors.info,
          onTap: () => context.go(RouteConstants.shepherdBookings),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          borderRadius: AppSpacing.cardRadius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md, horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.cardRadius,
              boxShadow: AppShadows.sm,
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Overview stats ────────────────────────────────────────────────────────────

class _OverviewStats extends ConsumerWidget {
  const _OverviewStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(shepherdBookingsProvider);

    if (bookingsAsync.isLoading) {
      return const JmShimmerList(count: 1, cardHeight: 80);
    }

    final bookings = bookingsAsync.valueOrNull ?? [];
    final now = DateTime.now();

    final upcoming = bookings
        .where((b) => b.status == 'confirmed' && b.checkIn.isAfter(now))
        .length;
    final active = bookings.where((b) => b.status == 'active').length;
    final completed = bookings.where((b) => b.status == 'completed').length;
    final totalSpent = bookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    final fmt = NumberFormat.compact(locale: 'en_IN');
    final loc = AppLocalizations.of(context);

    final cards = [
      DashboardStatCard(
        label: loc.upcomingLabel,
        value: '$upcoming',
        icon: Icons.event_rounded,
        color: AppColors.info,
        onTap: () => context.go(RouteConstants.shepherdBookings),
      ),
      DashboardStatCard(
        label: loc.bookingActive,
        value: '$active',
        icon: Icons.play_circle_rounded,
        color: AppColors.success,
        badge: active > 0,
        onTap: () => context.go(RouteConstants.shepherdBookings),
      ),
      DashboardStatCard(
        label: loc.tripsDoneLabel,
        value: '$completed',
        icon: Icons.check_circle_rounded,
        color: AppColors.secondary,
      ),
      DashboardStatCard(
        label: loc.spentLabel,
        value: '₹${fmt.format(totalSpent)}',
        icon: Icons.currency_rupee_rounded,
        color: AppColors.primary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.overviewLabel, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // Below ~392px of content width a 4-across row leaves each card
            // too narrow for its bold value text to render without
            // ellipsizing, so fall back to a 2x2 wrap.
            const minCardWidth = 92.0;
            const gap = AppSpacing.sm;
            final fourAcross = (constraints.maxWidth - gap * 3) / 4;
            final perRow = fourAcross >= minCardWidth ? 4 : 2;
            final cardWidth =
                (constraints.maxWidth - gap * (perRow - 1)) / perRow;

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Active trip banner ────────────────────────────────────────────────────────

class _ActiveTripBanner extends ConsumerWidget {
  const _ActiveTripBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(shepherdBookingsProvider).valueOrNull ?? [];
    final active = bookings.where((b) => b.status == 'active').toList();
    final loc = AppLocalizations.of(context);

    if (active.isEmpty) return const SizedBox.shrink();

    final trip = active.first;
    final dateStr = DateFormat('MMM d').format(trip.checkOut);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Material(
        color: AppColors.successContainer,
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          borderRadius: AppSpacing.cardRadius,
          onTap: () => context.push(
            RouteConstants.bookingDetail('shepherd', trip.id),
          ),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: AppColors.success, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.activeTripMsg(trip.farmTitle),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.success,
                            ),
                      ),
                      Text(
                        loc.tripEndsMsg(trip.animalCount, dateStr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.success.withAlpha(180),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.success),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent bookings ───────────────────────────────────────────────────────────

class _RecentBookings extends ConsumerWidget {
  const _RecentBookings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(shepherdBookingsProvider);
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(loc.myTripsLabel, style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(RouteConstants.shepherdBookings),
              child: Text(loc.viewAllBtn),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        bookingsAsync.when(
          loading: () => const JmShimmerList(count: 2, cardHeight: 80),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            if (bookings.isEmpty) {
              return _EmptyTrips();
            }
            final recent = bookings.take(3).toList();
            return Column(
              children: recent.map((b) => _TripRow(booking: b)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return EmptyStateCard(
      icon: Icons.route_rounded,
      title: loc.noTripsYetTitle,
      subtitle: loc.noTripsYetSubtitle,
      accentColor: AppColors.secondary,
      buttonLabel: loc.discoverLandsBtn,
      onButtonTap: () => context.go(RouteConstants.shepherdDiscover),
    );
  }
}

class _TripRow extends StatelessWidget {
  final BookingModel booking;
  const _TripRow({required this.booking});

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
        onTap: () => context.push(
          RouteConstants.bookingDetail('shepherd', booking.id),
        ),
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
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.landscape_rounded, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.farmTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      loc.bookingSummaryMsg(booking.animalCount, dateStr,
                          fmt.format(booking.totalAmount)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
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
