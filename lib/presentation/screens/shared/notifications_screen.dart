import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/firebase_error_translator.dart';
import '../../../data/models/notification_model.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/notifications/notification_providers.dart';
import '../../widgets/common/jm_empty_state.dart';
import '../../widgets/common/jm_error_state.dart';
import '../../widgets/common/jm_loading.dart';
import '../../widgets/common/responsive_center.dart';
import '../../widgets/common/standard_app_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: loc.notifications,
        actions: [
          if (unread > 0)
            TextButton.icon(
              onPressed: () => ref
                  .read(notificationNotifierProvider.notifier)
                  .markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded,
                  size: 18, color: Colors.white),
              label: Text(loc.markAllReadBtn,
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const JmShimmerList(count: 5, cardHeight: 96),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return JmEmptyState(
              icon: Icons.notifications_none_rounded,
              title: loc.noNotifications,
              subtitle: loc.noNotificationsSubtitle,
            );
          }
          final groups = _group(notifications, loc);
          return ResponsiveCenter(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final group = groups[i];
                if (group is String) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base,
                        AppSpacing.md, AppSpacing.base, AppSpacing.xs),
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
            ),
          );
        },
      ),
    );
  }

  // Returns interleaved [String label, NotificationModel, ...] list
  List<Object> _group(List<NotificationModel> items, AppLocalizations loc) {
    final result = <Object>[];
    String? currentLabel;
    for (final n in items) {
      final label = _dateLabel(n.createdAt, loc);
      if (label != currentLabel) {
        result.add(label);
        currentLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  String _dateLabel(DateTime dt, AppLocalizations loc) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return loc.todayLabel.toUpperCase();
    if (diff.inDays == 1) return loc.yesterdayLabel.toUpperCase();
    if (diff.inDays < 7) return loc.thisWeekLabel.toUpperCase();
    return loc.earlierLabel.toUpperCase();
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

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: 4),
      decoration: BoxDecoration(
        color: n.isRead
            ? AppColors.surface
            : AppColors.primaryContainer.withAlpha(50),
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.sm,
        border: Border.all(
          color: n.isRead ? AppColors.outline : AppColors.primary,
          width: n.isRead ? 1 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Dismissible(
        key: ValueKey(n.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          color: AppColors.errorContainer,
          child:
              const Icon(Icons.delete_outline_rounded, color: AppColors.error),
        ),
        onDismissed: (_) => onDismiss(),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.cardPadding,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                          if (!n.isRead) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
