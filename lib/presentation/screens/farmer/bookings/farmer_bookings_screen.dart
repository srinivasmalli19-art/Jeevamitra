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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: JmLoading()),
        error: (e, _) => JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(farmerBookingsProvider),
        ),
        data: (all) => TabBarView(
          controller: _tabs,
          children: [
            _BookingList(
              bookings: all
                  .where((b) => b.isPending)
                  .toList(),
              emptyTitle: 'No Pending Requests',
              emptySubtitle: 'New booking requests from shepherds will appear here.',
              role: 'farmer',
            ),
            _BookingList(
              bookings: all
                  .where((b) => b.isConfirmed || b.isActive)
                  .toList(),
              emptyTitle: 'No Active Bookings',
              emptySubtitle: 'Confirmed and ongoing bookings will appear here.',
              role: 'farmer',
            ),
            _BookingList(
              bookings: all
                  .where((b) => b.isCompleted || b.isCancelled)
                  .toList(),
              emptyTitle: 'No History Yet',
              emptySubtitle: 'Completed and cancelled bookings will appear here.',
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
      return JmEmptyState(
        icon: Icons.inbox_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i], role: role),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final String role;

  const _BookingCard({required this.booking, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: BorderSide(
          color: booking.isPending ? AppColors.warning : AppColors.outline,
          width: booking.isPending ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push(
            RouteConstants.bookingDetail(role, booking.id)),
        borderRadius: AppSpacing.cardRadius,
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
                    '₹${booking.totalAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              if (booking.isPending && role == 'farmer') ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(bookingNotifierProvider.notifier)
                            .cancelBooking(booking.id, 'Rejected by farmer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => ref
                            .read(bookingNotifierProvider.notifier)
                            .confirmBooking(booking.id),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Accept'),
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
