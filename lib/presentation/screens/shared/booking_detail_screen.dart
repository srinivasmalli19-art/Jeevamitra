import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firebase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/booking/booking_providers.dart';
import '../../widgets/common/jm_badge.dart';
import '../../widgets/common/jm_error_state.dart';
import '../../widgets/common/jm_loading.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  final String role; // 'farmer' | 'shepherd'

  const BookingDetailScreen(
      {super.key, required this.bookingId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isFarmer = role == 'farmer';

    return bookingAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(bookingDetailProvider(bookingId)),
        ),
      ),
      data: (booking) {
        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Booking Details')),
            body: const Center(child: Text('Booking not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Booking Details'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.base),
                child: _statusBadge(booking.status),
              ),
            ],
          ),
          body: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Farm info
              _Section(
                title: 'Land',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.farmTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(booking.farmVillage,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              // Dates & herd
              _Section(
                title: 'Stay Details',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.login_rounded,
                      label: 'Check-in',
                      value: _fmt(booking.checkIn),
                    ),
                    _InfoRow(
                      icon: Icons.logout_rounded,
                      label: 'Check-out',
                      value: _fmt(booking.checkOut),
                    ),
                    _InfoRow(
                      icon: Icons.timelapse_rounded,
                      label: 'Duration',
                      value: '${booking.durationDays} days',
                    ),
                    _InfoRow(
                      icon: Icons.groups_rounded,
                      label: 'Animals',
                      value: '${booking.animalCount}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              // Amount
              _Section(
                title: 'Payment',
                child: _InfoRow(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Total Estimate',
                  value: '₹${booking.totalAmount.toStringAsFixed(0)}',
                  highlight: true,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              // Parties
              _Section(
                title: isFarmer ? 'Shepherd' : 'Farmer',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Name',
                      value: isFarmer ? booking.shepherdName : 'Farmer',
                    ),
                    if (isFarmer && booking.shepherdPhone != null)
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: booking.shepherdPhone!,
                      ),
                  ],
                ),
              ),
              // Status timeline
              const SizedBox(height: AppSpacing.base),
              _Section(
                title: 'Status',
                child: _StatusTimeline(status: booking.status),
              ),
              if (booking.cancellationReason != null) ...[
                const SizedBox(height: AppSpacing.base),
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: AppSpacing.cardRadius,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Cancelled: ${booking.cancellationReason}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              // Actions
              ..._buildActions(context, ref, booking, uid, isFarmer),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildActions(BuildContext context, WidgetRef ref,
      booking, String uid, bool isFarmer) {
    final notifier = ref.read(bookingNotifierProvider.notifier);
    final actions = <Widget>[];

    if (isFarmer) {
      if (booking.isPending) {
        actions.add(
          FilledButton.icon(
            onPressed: () async {
              final ok = await notifier.confirmBooking(booking.id, booking: booking);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking confirmed!')),
                );
              }
            },
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Confirm Booking'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              backgroundColor: AppColors.success,
            ),
          ),
        );
        actions.add(const SizedBox(height: AppSpacing.sm));
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _cancelDialog(context, notifier, booking.id, booking: booking),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject Booking'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        );
      }
      if (booking.isConfirmed) {
        actions.add(
          FilledButton.icon(
            onPressed: () async {
              final ok = await notifier.activateBooking(booking.id, booking: booking);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking marked as active!')),
                );
              }
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Mark as Active (Arrived)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
            ),
          ),
        );
      }
      if (booking.isActive) {
        actions.add(
          FilledButton.icon(
            onPressed: () async {
              final ok = await notifier.completeBooking(booking.id, booking: booking);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking completed!')),
                );
              }
            },
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Mark as Completed'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              backgroundColor: AppColors.success,
            ),
          ),
        );
      }
    } else {
      // Shepherd
      if (booking.isPending || booking.isConfirmed) {
        actions.add(
          OutlinedButton.icon(
            onPressed: () => _cancelDialog(context, notifier, booking.id, booking: booking),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Cancel Booking'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        );
      }
      if (booking.canReview) {
        actions.add(
          FilledButton.icon(
            onPressed: () => _reviewDialog(context, notifier, booking.id),
            icon: const Icon(Icons.star_rounded),
            label: const Text('Leave a Review'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
              backgroundColor: AppColors.secondary,
            ),
          ),
        );
      }
    }

    return actions;
  }

  Future<void> _cancelDialog(BuildContext context, BookingNotifier notifier,
      String bookingId, {required booking}) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            hintText: 'e.g. changed plans...',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep Booking')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await notifier.cancelBooking(
        bookingId, reasonCtrl.text.trim().isEmpty ? 'Cancelled' : reasonCtrl.text.trim(),
        booking: booking);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Booking cancelled')));
    context.pop();
  }

  Future<void> _reviewDialog(BuildContext context,
      BookingNotifier notifier, String bookingId) async {
    double rating = 4;
    final reviewCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Rate this Land'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.secondary,
                    ),
                    onPressed: () => setState(() => rating = (i + 1).toDouble()),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  labelText: 'Your review',
                  hintText: 'How was the grazing land?',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Skip')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true) return;
    await notifier.submitReview(
        bookingId, rating, reviewCtrl.text.trim());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Review submitted!')));
  }

  Widget _statusBadge(String status) {
    final (label, variant) = switch (status) {
      FirebaseConstants.bookingPending => ('Pending', JmBadgeVariant.warning),
      FirebaseConstants.bookingConfirmed => ('Confirmed', JmBadgeVariant.info),
      FirebaseConstants.bookingActive => ('Active', JmBadgeVariant.success),
      FirebaseConstants.bookingCompleted => ('Completed', JmBadgeVariant.neutral),
      _ => ('Cancelled', JmBadgeVariant.error),
    };
    return JmBadge(label: label, variant: variant);
  }

  String _fmt(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }
}

// ─── Status timeline ──────────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    (FirebaseConstants.bookingPending, 'Requested', Icons.pending_rounded),
    (FirebaseConstants.bookingConfirmed, 'Confirmed', Icons.check_circle_rounded),
    (FirebaseConstants.bookingActive, 'Active', Icons.play_circle_rounded),
    (FirebaseConstants.bookingCompleted, 'Completed', Icons.task_alt_rounded),
  ];

  int get _currentIndex {
    for (var i = 0; i < _steps.length; i++) {
      if (_steps[i].$1 == status) return i;
    }
    return -1; // cancelled
  }

  @override
  Widget build(BuildContext context) {
    if (status == FirebaseConstants.bookingCancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Text('Cancelled',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
        ],
      );
    }

    final cur = _currentIndex;
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepIdx < cur ? AppColors.success : AppColors.outline,
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final done = stepIdx < cur;
        final active = stepIdx == cur;
        return Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.success
                    : active
                        ? AppColors.primary
                        : AppColors.outline,
              ),
              child: Icon(
                _steps[stepIdx].$3,
                size: 16,
                color: done || active ? Colors.white : AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _steps[stepIdx].$2,
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Card(
          elevation: 0,
          color: AppColors.surfaceVariant,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool highlight;
  const _InfoRow(
      {required this.icon, required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: highlight
                ? Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
