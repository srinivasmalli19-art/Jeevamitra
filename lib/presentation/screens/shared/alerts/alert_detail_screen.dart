import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/url_launch_helper.dart';
import '../../../../data/models/disease_alert_model.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/alerts/disease_alert_providers.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/premium_vet_card.dart';
import '../../../widgets/explore/retry_card.dart';
import 'alert_severity.dart';

/// Whether the Withdraw action should be shown on Alert Detail: only to the
/// alert's own reporter, and only while it's still active — deactivating
/// an already-inactive alert is a no-op, and the actual authorization is
/// enforced server-side by firestore.rules regardless of this UI gate.
bool canWithdrawAlert(DiseaseAlertModel alert, String? currentUid) =>
    alert.isActive &&
    alert.reportedBy.isNotEmpty &&
    alert.reportedBy == currentUid;

/// Alert Detail: hero, severity badge, description, symptoms, treatment,
/// prevention, government advisory (source authority), nearest
/// veterinarian, and Navigate/Call Vet/Share/Report Similar Case actions.
///
/// There is no image field anywhere in the Disease Alert schema and no
/// photo-upload flow for alerts (unlike farms/vets, which have Storage
/// integration) — building one is out of scope for this batch, so the
/// "hero image" requirement is met with a decorative severity-themed
/// gradient banner (the same visual language as `ExploreHeader`/
/// `HeroBanner`) instead of a fabricated photo.
class AlertDetailScreen extends ConsumerWidget {
  final String alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final alertAsync = ref.watch(alertDetailProvider(alertId));

    return alertAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(loc.alertDetailsTitle)),
        body: RetryCard(
            error: e,
            onRetry: () => ref.invalidate(alertDetailProvider(alertId))),
      ),
      data: (alert) {
        if (alert == null) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.alertDetailsTitle)),
            body: EmptyStateCard(
              icon: Icons.error_outline_rounded,
              title: loc.alertNotFoundTitle,
              subtitle: loc.alertRemovedMsg,
            ),
          );
        }
        return _AlertDetailBody(alert: alert);
      },
    );
  }
}

class _AlertDetailBody extends ConsumerWidget {
  final DiseaseAlertModel alert;
  const _AlertDetailBody({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final severity = AlertSeverity.of(alert.severity);
    final locAsync = ref.watch(locationProvider);
    final userLoc = locAsync.valueOrNull;
    final distLabel = userLoc != null
        ? formatDistanceAway(
            GeoHashHelper.distanceKm(userLoc.lat, userLoc.lng, alert.lat, alert.lng), loc)
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                tooltip: loc.shareTooltip,
                onPressed: () => _share(alert, loc),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroBanner(alert: alert, severity: severity),
            ),
          ),
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverList.list(children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _SeverityBadge(severityKey: alert.severity, loc: loc),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(alert.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                        maxLines: 3),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: 4,
                children: [
                  _MetaLine(
                    icon: Icons.location_on_rounded,
                    text: alert.village.isNotEmpty
                        ? '${alert.village}, ${alert.district}, ${alert.state}'
                        : '${alert.district}, ${alert.state}',
                  ),
                  if (distLabel != null)
                    _MetaLine(icon: Icons.near_me_rounded, text: distLabel),
                  _MetaLine(
                      icon: Icons.event_rounded,
                      text: loc.issuedDateMsg(_dateLabel(alert.issuedAt))),
                  if (alert.expiresAt != null)
                    _MetaLine(
                        icon: Icons.event_busy_rounded,
                        text: loc.validUntilDateMsg(_dateLabel(alert.expiresAt!))),
                  _MetaLine(
                      icon: speciesIcon,
                      text: speciesLabel(alert.affectedSpecies, loc)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(loc.descriptionLabel,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(alert.description,
                  style: Theme.of(context).textTheme.bodyMedium),
              if (alert.symptoms != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _InfoSection(
                  icon: Icons.sick_rounded,
                  label: loc.symptomsLabel,
                  text: alert.symptoms!,
                  color: AppColors.warning,
                ),
              ],
              if (alert.treatment != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _InfoSection(
                  icon: Icons.healing_rounded,
                  label: loc.treatmentLabel,
                  text: alert.treatment!,
                  color: AppColors.info,
                ),
              ],
              if (alert.prevention != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _InfoSection(
                  icon: Icons.shield_rounded,
                  label: loc.preventionLabel,
                  text: alert.prevention!,
                  color: AppColors.success,
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _InfoSection(
                icon: Icons.verified_rounded,
                label: loc.govtAdvisoryLabel,
                text: alert.sourceAuthority,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(loc.nearbyVeterinarianTitle,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _NearestVet(alert: alert),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigate(context, alert.lat, alert.lng, loc),
                      icon: const Icon(Icons.directions_rounded),
                      label: Text(loc.navigateBtn),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppSpacing.buttonHeight),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  if (alert.vetContactPhone != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _call(context, alert.vetContactPhone!, loc),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(loc.callVet),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context.push(RouteConstants.reportAlert),
                icon: const Icon(Icons.add_alert_rounded),
                label: Text(loc.reportSimilarCaseBtn),
                style: OutlinedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, AppSpacing.buttonHeight),
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                ),
              ),
              if (canWithdrawAlert(
                  alert, FirebaseAuth.instance.currentUser?.uid)) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _withdraw(context, ref, alert, loc),
                  icon: const Icon(Icons.block_rounded),
                  label: Text(loc.withdrawAlertBtn),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ]),
          ),
        ],
      ),
    );
  }

  String _dateLabel(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _navigate(
          BuildContext context, double lat, double lng, AppLocalizations loc) =>
      launchExternalUrl(
        context,
        mapsSearchUri(lat, lng),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.couldNotOpenMapsMsg,
      );

  Future<void> _call(BuildContext context, String phone, AppLocalizations loc) =>
      launchExternalUrl(context, telUri(phone),
          failureMessage: loc.couldNotOpenDialerMsg);

  Future<void> _withdraw(BuildContext context, WidgetRef ref,
      DiseaseAlertModel alert, AppLocalizations loc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.withdrawAlertConfirmTitle),
        content: Text(loc.withdrawAlertConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancelBtn)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(loc.withdrawAlertBtn),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await ref
        .read(diseaseAlertNotifierProvider.notifier)
        .deactivateAlert(alert.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? loc.withdrawAlertSuccessMsg : loc.withdrawAlertFailedMsg),
    ));
  }

  Future<void> _share(DiseaseAlertModel alert, AppLocalizations loc) {
    final where = alert.village.isNotEmpty
        ? '${alert.village}, ${alert.district}'
        : alert.district;
    return Share.share(
      '${alert.title}\n${alert.disease} — ${loc.severitySuffixMsg(severityLabel(alert.severity, loc))}\n'
      '${loc.locationLineMsg('$where, ${alert.state}')}\n\n${alert.description}\n\n'
      '${loc.sharedViaAppMsg}',
      subject: alert.title,
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final DiseaseAlertModel alert;
  final AlertSeverity severity;
  const _HeroBanner({required this.alert, required this.severity});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [severity.color, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        const Positioned(
          right: -16,
          bottom: -12,
          child: Opacity(
            opacity: 0.14,
            child:
                Icon(Icons.coronavirus_rounded, size: 160, color: Colors.white),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Color(0x66000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.3, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severityKey;
  final AppLocalizations loc;
  const _SeverityBadge({required this.severityKey, required this.loc});

  @override
  Widget build(BuildContext context) {
    final severity = AlertSeverity.of(severityKey);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
          color: severity.background,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severity.icon, size: 14, color: severity.color),
          const SizedBox(width: 4),
          Text(severityLabel(severityKey, loc),
              style: TextStyle(
                  fontSize: 12,
                  color: severity.color,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String label, text;
  final Color color;
  const _InfoSection(
      {required this.icon,
      required this.label,
      required this.text,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestVet extends ConsumerWidget {
  final DiseaseAlertModel alert;
  const _NearestVet({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    // Vets near the alert's location, not the viewer's — a shepherd reading
    // an alert cares who can treat animals *there*, not who is near them
    // right now. Reuses the same nearbyVetsProvider every other vet screen
    // uses; no new stream.
    final vetsAsync = ref.watch(
        nearbyVetsProvider((lat: alert.lat, lng: alert.lng, radiusKm: 50)));
    final locAsync = ref.watch(locationProvider);

    return vetsAsync.when(
      loading: () =>
          const SizedBox(height: 100, child: Center(child: JmLoading())),
      error: (e, _) => RetryCard(
        error: e,
        onRetry: () => ref.invalidate(nearbyVetsProvider),
      ),
      data: (vets) {
        if (vets.isEmpty) {
          return EmptyStateCard(
            icon: Icons.person_search_rounded,
            title: loc.noVetsNearAlertTitle,
            subtitle: loc.noVetsNearAlertMsg,
          );
        }
        final nearest = vets.first;
        final userLoc = locAsync.valueOrNull;
        final distanceKm = userLoc != null
            ? GeoHashHelper.distanceKm(
                userLoc.lat, userLoc.lng, nearest.lat, nearest.lng)
            : 0.0;
        return PremiumVetCard(
          vet: nearest,
          distanceKm: distanceKm,
          onViewProfile: () =>
              context.push(RouteConstants.vetDetail(nearest.id)),
        );
      },
    );
  }
}
