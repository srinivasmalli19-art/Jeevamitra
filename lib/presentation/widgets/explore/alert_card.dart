import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../data/models/disease_alert_model.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../screens/shared/alerts/alert_severity.dart';

/// The modern Disease Alert card: a severity accent bar, disease icon,
/// title, village/district, distance, issued date, affected species, and a
/// Read More button — the single card every alert list in the module
/// renders (Nearby/District/Active/Recent tabs, and any future list),
/// replacing the old inline `_AlertCard`/`_SeverityIcon` pair that used to
/// live in `farmer_explore_screen.dart`.
class AlertCard extends StatelessWidget {
  final DiseaseAlertModel alert;
  final double? distanceKm;
  final VoidCallback onReadMore;

  const AlertCard({super.key, required this.alert, this.distanceKm, required this.onReadMore});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final severity = AlertSeverity.of(alert.severity);
    return Material(
      color: AppColors.surface,
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        borderRadius: AppSpacing.cardRadius,
        onTap: onReadMore,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppSpacing.cardRadius,
            boxShadow: AppShadows.sm,
            border: Border.all(color: severity.color.withAlpha(60)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: severity.color,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppSpacing.radiusLg)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                  color: severity.color.withAlpha(26), shape: BoxShape.circle),
                              child: Icon(Icons.coronavirus_rounded, color: severity.color, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(alert.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleSmall),
                                  Text(alert.disease,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: severity.background,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(severity.icon, size: 12, color: severity.color),
                                  const SizedBox(width: 4),
                                  Text(severityLabel(alert.severity, loc),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: severity.color,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: 4,
                          children: [
                            _MetaChip(
                              icon: Icons.location_on_rounded,
                              text: alert.village.isNotEmpty
                                  ? '${alert.village}, ${alert.district}'
                                  : alert.district,
                            ),
                            if (distanceKm != null)
                              _MetaChip(
                                  icon: Icons.near_me_rounded,
                                  text: formatDistanceAway(distanceKm!, loc)),
                            _MetaChip(icon: Icons.event_rounded, text: _age(alert.issuedAt, loc)),
                            _MetaChip(
                                icon: speciesIcon, text: speciesLabel(alert.affectedSpecies, loc)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: onReadMore,
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: Text(loc.readMoreBtn),
                            style: TextButton.styleFrom(
                              foregroundColor: severity.color,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _age(DateTime dt, AppLocalizations loc) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return loc.daysAgoMsg(diff.inDays);
    if (diff.inHours > 0) return loc.hoursAgoMsg(diff.inHours);
    if (diff.inMinutes > 0) return loc.minutesAgoMsg(diff.inMinutes);
    return loc.justNowMsg;
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textDisabled),
        const SizedBox(width: 3),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary, fontSize: 11.5)),
      ],
    );
  }
}
