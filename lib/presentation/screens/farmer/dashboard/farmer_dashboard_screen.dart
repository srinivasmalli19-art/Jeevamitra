import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/booking_model.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../providers/notifications/notification_providers.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_loading.dart';

JmBadgeVariant _bookingVariant(String status) => switch (status) {
      'pending' => JmBadgeVariant.warning,
      'confirmed' => JmBadgeVariant.info,
      'active' => JmBadgeVariant.success,
      'completed' => JmBadgeVariant.neutral,
      _ => JmBadgeVariant.error,
    };

class FarmerDashboardScreen extends ConsumerWidget {
  const FarmerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _Header(name: userDoc?.name ?? 'రైతు', village: userDoc?.village),
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSpacing.sm),
                const _QuickActions(),
                const SizedBox(height: AppSpacing.xl),
                const _OverviewStats(),
                const SizedBox(height: AppSpacing.xl),
                const _PendingBanner(),
                const _RecentBookings(),
                const SizedBox(height: AppSpacing.xxl),
              ]),
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

    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          tooltip: 'Voice Assistant',
          onPressed: () => context.push(RouteConstants.assistant),
          icon: const Icon(Icons.mic_rounded, color: Colors.white),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => context.push(RouteConstants.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 9 ? '9+' : '$unread'),
            child: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'నమస్తే, $name!',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            if (village != null)
              Text(
                village!,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.primaryGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: AppSpacing.xl),
              child: Opacity(
                opacity: 0.12,
                child: Icon(Icons.agriculture_rounded,
                    size: 120, color: Colors.white),
              ),
            ),
          ),
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
    return Row(
      children: [
        _ActionChip(
          icon: Icons.add_location_alt_rounded,
          label: 'Add Land',
          color: AppColors.primary,
          onTap: () => context.push(RouteConstants.farmerAddLand),
        ),
        const SizedBox(width: AppSpacing.md),
        _ActionChip(
          icon: Icons.coronavirus_rounded,
          label: 'Alerts',
          color: AppColors.warning,
          onTap: () => context.go(RouteConstants.farmerExplore),
        ),
        const SizedBox(width: AppSpacing.md),
        _ActionChip(
          icon: Icons.landscape_rounded,
          label: 'My Lands',
          color: AppColors.secondary,
          onTap: () => context.go(RouteConstants.farmerLands),
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
        color: color.withAlpha(26),
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          borderRadius: AppSpacing.cardRadius,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
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
    final farmsAsync = ref.watch(myFarmsProvider);
    final bookingsAsync = ref.watch(farmerBookingsProvider);

    final totalLands = farmsAsync.valueOrNull?.length ?? 0;
    final bookings = bookingsAsync.valueOrNull ?? [];
    final pendingCount = bookings.where((b) => b.status == 'pending').length;
    final activeCount = bookings.where((b) => b.status == 'active').length;
    final earnings = bookings
        .where((b) => b.status == 'completed')
        .fold(0.0, (sum, b) => sum + b.totalAmount);

    if (farmsAsync.isLoading || bookingsAsync.isLoading) {
      return const JmShimmerList(count: 1, cardHeight: 80);
    }

    final fmt = NumberFormat.compact(locale: 'en_IN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _StatCard(
              label: 'My Lands',
              value: '$totalLands',
              icon: Icons.landscape_rounded,
              color: AppColors.primary,
              onTap: () => context.go(RouteConstants.farmerLands),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatCard(
              label: 'Pending',
              value: '$pendingCount',
              icon: Icons.hourglass_top_rounded,
              color: AppColors.warning,
              badge: pendingCount > 0,
              onTap: () => context.go(RouteConstants.farmerBookings),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatCard(
              label: 'Active',
              value: '$activeCount',
              icon: Icons.play_circle_rounded,
              color: AppColors.success,
              onTap: () => context.go(RouteConstants.farmerBookings),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatCard(
              label: 'Earnings',
              value: '₹${fmt.format(earnings)}',
              icon: Icons.currency_rupee_rounded,
              color: AppColors.secondary,
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool badge;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.badge = false,
    this.onTap,
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
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(
                color: badge ? color.withAlpha(140) : AppColors.outline,
                width: badge ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 18),
                    if (badge)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Pending booking alert banner ─────────────────────────────────────────────

class _PendingBanner extends ConsumerWidget {
  const _PendingBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(farmerBookingsProvider).valueOrNull ?? [];
    final pending = bookings.where((b) => b.status == 'pending').toList();

    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Material(
        color: AppColors.warningContainer,
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          borderRadius: AppSpacing.cardRadius,
          onTap: () => context.go(RouteConstants.farmerBookings),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_active_rounded,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pending.length} booking${pending.length > 1 ? 's' : ''} awaiting your approval',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.warning,
                            ),
                      ),
                      Text(
                        'Tap to review and accept',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.warning.withAlpha(180),
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.warning),
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
    final bookingsAsync = ref.watch(farmerBookingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recent Bookings',
                style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            TextButton(
              onPressed: () => context.go(RouteConstants.farmerBookings),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        bookingsAsync.when(
          loading: () => const JmShimmerList(count: 2, cardHeight: 80),
          error: (_, __) => const SizedBox.shrink(),
          data: (bookings) {
            if (bookings.isEmpty) {
              return _EmptyBookings();
            }
            final recent = bookings.take(3).toList();
            return Column(
              children: recent.map((b) => _BookingRow(booking: b)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _EmptyBookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          const Icon(Icons.event_note_rounded,
              size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No bookings yet',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Bookings from shepherds will appear here',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final BookingModel booking;
  const _BookingRow({required this.booking});

  static Color _avatarColor(String status) => switch (status) {
        'pending' => AppColors.warning,
        'confirmed' => AppColors.info,
        'active' => AppColors.success,
        'completed' => AppColors.textSecondary,
        _ => AppColors.error,
      };

  static String _statusLabel(String status) => switch (status) {
        'pending' => 'Pending',
        'confirmed' => 'Confirmed',
        'active' => 'Active',
        'completed' => 'Done',
        _ => 'Cancelled',
      };

  @override
  Widget build(BuildContext context) {
    final color = _avatarColor(booking.status);
    final dateStr = DateFormat('MMM d').format(booking.checkIn);
    final fmt = NumberFormat.compact(locale: 'en_IN');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: () => context.push(
          RouteConstants.bookingDetail('farmer', booking.id),
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
                child: Icon(Icons.person_rounded, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.shepherdName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${booking.animalCount} animals · $dateStr · ₹${fmt.format(booking.totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              JmBadge(
                label: _statusLabel(booking.status),
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
