import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/common/standard_app_bar.dart';
import '../../../widgets/explore/alert_card.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/loading_skeleton.dart';
import '../../../widgets/explore/retry_card.dart';

/// Lets a farmer see and manage the disease alerts they personally
/// reported (active and withdrawn) — the only place reportedBy-owned
/// alerts are listed; DiseaseAlertRepository.deactivateAlert() already
/// existed but had no UI entry point before this screen and the
/// Withdraw action on AlertDetailScreen.
class MyReportedAlertsScreen extends ConsumerWidget {
  const MyReportedAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final alertsAsync = ref.watch(myReportedAlertsProvider);

    return Scaffold(
      appBar: StandardAppBar(title: loc.myReportedAlertsTitle),
      body: alertsAsync.when(
        loading: () => const LoadingSkeleton(count: 3),
        error: (e, _) => RetryCard(
          error: e,
          onRetry: () => ref.invalidate(myReportedAlertsProvider),
        ),
        data: (alerts) {
          if (alerts.isEmpty) {
            return EmptyStateCard(
              icon: Icons.campaign_outlined,
              title: loc.noReportedAlertsTitle,
              subtitle: loc.noReportedAlertsSubtitle,
            );
          }
          return ResponsiveCenter(
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) {
                final alert = alerts[i];
                return AlertCard(
                  alert: alert,
                  onReadMore: () =>
                      context.push(RouteConstants.alertDetail(alert.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
