import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/booking_model.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../widgets/common/jm_badge.dart';
import '../../../widgets/common/jm_empty_state.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

class ShepherdBookingsScreen extends ConsumerWidget {
  const ShepherdBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(shepherdBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: JmLoading()),
        error: (e, _) => JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(shepherdBookingsProvider),
        ),
        data: (bookings) => bookings.isEmpty
            ? const JmEmptyState(
                icon: Icons.calendar_month_rounded,
                title: 'No Bookings Yet',
                subtitle:
                    'Book a grazing land from Discover to see your bookings here.',
              )
            : ListView.separated(
                padding: AppSpacing.screenPadding,
                itemCount: bookings.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, i) =>
                    _ShepherdBookingCard(booking: bookings[i]),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: () =>
            context.push(RouteConstants.bookingDetail('shepherd', booking.id)),
        borderRadius: AppSpacing.cardRadius,
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
                  _statusBadge(booking.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(booking.farmVillage,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Text(
                    '${_fmt(booking.checkIn)} → ${_fmt(booking.checkOut)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${booking.animalCount} animals · ₹${booking.totalAmount.toStringAsFixed(0)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, variant) = switch (status) {
      'pending' => ('Pending', JmBadgeVariant.warning),
      'confirmed' => ('Confirmed', JmBadgeVariant.info),
      'active' => ('Active', JmBadgeVariant.success),
      'completed' => ('Completed', JmBadgeVariant.neutral),
      _ => ('Cancelled', JmBadgeVariant.error),
    };
    return JmBadge(label: label, variant: variant, small: true);
  }

  String _fmt(DateTime d) {
    const m = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month]}';
  }
}
