import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notifications/notification_providers.dart';
import '../../widgets/common/jm_empty_state.dart';
import '../../widgets/common/jm_error_state.dart';
import '../../widgets/common/jm_loading.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationNotifierProvider.notifier).markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const JmShimmerList(count: 5, cardHeight: 72),
        error: (e, _) => JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const JmEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'Booking updates and alerts will appear here',
            );
          }
          final groups = _group(notifications);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i];
              if (group is String) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.xs),
                  child: Text(
                    group,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                  ),
                );
              }
              final n = group as NotificationModel;
              return _NotificationTile(
                notification: n,
                onTap: () => _handleTap(context, ref, n),
                onDismiss: () => ref
                    .read(notificationNotifierProvider.notifier)
                    .delete(n.id),
              );
            },
          );
        },
      ),
    );
  }

  // Returns interleaved [String label, NotificationModel, ...] list
  List<Object> _group(List<NotificationModel> items) {
    final result = <Object>[];
    String? currentLabel;
    for (final n in items) {
      final label = _dateLabel(n.createdAt);
      if (label != currentLabel) {
        result.add(label);
        currentLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'TODAY';
    if (diff.inDays == 1) return 'YESTERDAY';
    if (diff.inDays < 7) return 'THIS WEEK';
    return 'EARLIER';
  }

  void _handleTap(BuildContext context, WidgetRef ref, NotificationModel n) {
    // Mark as read
    if (!n.isRead) {
      ref.read(notificationNotifierProvider.notifier).markAsRead(n.id);
    }
    // Navigate based on type and payload
    final bookingId = n.payload['bookingId'] as String?;
    final role = n.payload['role'] as String?;
    if (bookingId != null && role != null) {
      context.push(RouteConstants.bookingDetail(role, bookingId));
      return;
    }
    // Disease alert → explore tab
    if (n.type == 'disease_alert') {
      final isFarmer = n.payload['role'] == 'farmer';
      context.push(
          isFarmer ? RouteConstants.farmerExplore : RouteConstants.farmerExplore);
    }
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (iconData, iconColor) = _iconFor(n.type);

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        color: AppColors.errorContainer,
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: n.isRead ? Colors.transparent : AppColors.primaryContainer.withAlpha(60),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(n.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.textDisabled,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(String type) => switch (type) {
        'booking_request' => (Icons.event_available_rounded, AppColors.info),
        'booking_confirmed' => (Icons.check_circle_rounded, AppColors.success),
        'booking_active' => (Icons.play_circle_rounded, AppColors.success),
        'booking_completed' => (Icons.verified_rounded, AppColors.primary),
        'booking_cancelled' => (Icons.cancel_rounded, AppColors.error),
        'disease_alert' => (Icons.warning_rounded, AppColors.warning),
        _ => (Icons.notifications_rounded, AppColors.textSecondary),
      };
}
