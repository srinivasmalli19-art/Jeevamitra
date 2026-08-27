import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/firebase_error_translator.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/common/standard_app_bar.dart';
import '../../shepherd/bookings/shepherd_bookings_screen.dart';

class FarmerBookingsScreen extends ConsumerStatefulWidget {
  const FarmerBookingsScreen({super.key});

  @override
  ConsumerState<FarmerBookingsScreen> createState() =>
      _FarmerBookingsScreenState();
}

class _FarmerBookingsScreenState extends ConsumerState<FarmerBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(farmerBookingsProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: loc.bookings,
        actions: [
          // Universal Access: booking land yourself is available to every
          // profile, not just this tab's default (owner/requests) view.
          IconButton(
            icon: const Icon(Icons.travel_explore_rounded),
            tooltip: loc.exploreAllFeaturesTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShepherdBookingsScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: loc.bookingPending),
            Tab(text: loc.bookingActive),
            Tab(text: loc.historyLabel),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const JmShimmerList(count: 3, cardHeight: 130),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(farmerBookingsProvider),
        ),
        data: (all) => TabBarView(
          controller: _tabs,
          children: [
            _BookingList(
              bookings: all.where((b) => b.isPending).toList(),
              emptyTitle: loc.noPendingRequestsTitle,
              emptySubtitle: loc.noPendingRequestsSubtitle,
              role: 'farmer',
            ),
            _BookingList(
              bookings: all.where((b) => b.isConfirmed || b.isActive).toList(),
              emptyTitle: loc.noActiveBookingsTitle,
              emptySubtitle: loc.noActiveBookingsSubtitle,
              role: 'farmer',
            ),
            _BookingList(
              bookings:
                  all.where((b) => b.isCompleted || b.isCancelled).toList(),
              emptyTitle: loc.noHistoryYetTitle,
              emptySubtitle: loc.noHistoryYetSubtitle,
              role: 'farmer',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared list ──────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyTitle, emptySubtitle, role;

  const _BookingList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateCard(
        icon: Icons.inbox_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
        accentColor: AppColors.textDisabled,
      );
    }
    return ResponsiveCenter(
      child: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i], role: role),
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final String role;

  const _BookingCard({required this.booking, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.sm,
        border: Border.all(
          color: booking.isPending ? AppColors.warning : AppColors.outline,
          width: booking.isPending ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(RouteConstants.bookingDetail(role, booking.id)),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.farmTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _statusBadge(booking.status, loc),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(booking.shepherdName,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(booking.farmVillage,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${DateFormat('d MMM').format(booking.checkIn)} → '
                    '${DateFormat('d MMM').format(booking.checkOut)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              if (booking.isPending && role == 'farmer') ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(bookingNotifierProvider.notifier)
                            .cancelBooking(booking.id, 'Rejected by farmer'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: Text(loc.rejectBtn),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ref
                            .read(bookingNotifierProvider.notifier)
                            .confirmBooking(booking.id),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: Text(loc.acceptBtn),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, AppLocalizations loc) {
    final (label, variant) = switch (status) {
      'pending' => (loc.bookingPending, JmBadgeVariant.warning),
      'confirmed' => (loc.bookingConfirmed, JmBadgeVariant.info),
      'active' => (loc.bookingActive, JmBadgeVariant.success),
      'completed' => (loc.bookingCompleted, JmBadgeVariant.neutral),
      _ => (loc.bookingCancelled, JmBadgeVariant.error),
    };
    return JmBadge(label: label, variant: variant, small: true);
  }
}
