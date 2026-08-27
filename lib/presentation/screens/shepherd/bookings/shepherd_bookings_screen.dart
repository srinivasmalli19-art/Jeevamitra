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
import '../../farmer/bookings/farmer_bookings_screen.dart';

class ShepherdBookingsScreen extends ConsumerWidget {
  const ShepherdBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(shepherdBookingsProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: loc.bookings,
        actions: [
          // Universal Access: managing booking requests for your own land
          // is available to every profile, not just this tab's default
          // (booker) view.
          IconButton(
            icon: const Icon(Icons.inbox_rounded),
            tooltip: loc.exploreAllFeaturesTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FarmerBookingsScreen()),
            ),
          ),
        ],
      ),
      body: bookingsAsync.when(
        loading: () => const JmShimmerList(count: 3, cardHeight: 110),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(shepherdBookingsProvider),
        ),
        data: (bookings) => bookings.isEmpty
            ? EmptyStateCard(
                icon: Icons.calendar_month_rounded,
                title: loc.noBookingsYetTitle,
                subtitle: loc.bookLandToSeeBookingsMsg,
                accentColor: AppColors.textDisabled,
              )
            : ResponsiveCenter(
                child: ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, i) =>
                      _ShepherdBookingCard(booking: bookings[i]),
                ),
              ),
      ),
    );
  }
}

class _ShepherdBookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _ShepherdBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(RouteConstants.bookingDetail('shepherd', booking.id)),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(booking.farmTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _statusBadge(booking.status, loc),
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
                      '${loc.animalsCountLabel(booking.animalCount)} · '
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
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
