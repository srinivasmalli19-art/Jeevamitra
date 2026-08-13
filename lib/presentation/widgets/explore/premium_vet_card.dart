import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/utils/url_launch_helper.dart';
import '../../../data/models/vet_model.dart';
import '../../../generated/l10n/app_localizations.dart';
import 'vet_avatar.dart';

/// Premium discovery card for a nearby veterinarian: profile picture,
/// name, rating, experience, village/district, distance, "Available
/// Today" badge, specialization, languages, and four actions — Call,
/// View Profile, Book, Navigate. Coordinates are used only to build the
/// maps deep link and compute [distanceKm] upstream — never rendered as
/// text here.
class PremiumVetCard extends StatelessWidget {
  final VetModel vet;
  final double distanceKm;
  final VoidCallback onViewProfile;

  const PremiumVetCard({
    super.key,
    required this.vet,
    required this.distanceKm,
    required this.onViewProfile,
  });

  Future<void> _call(BuildContext context, AppLocalizations loc) =>
      launchExternalUrl(context, telUri(vet.phone),
          failureMessage: loc.couldNotOpenDialerMsg);

  Future<void> _book(BuildContext context, AppLocalizations loc) async {
    if (vet.whatsapp != null) {
      final launched = await launchExternalUrl(
        context,
        whatsappUri(vet.whatsapp!,
            text:
                "Hello ${vet.name}, I'd like to book a consultation via JeevaMitra."),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.whatsappNotInstalledMsg,
      );
      if (launched) return;
    }
    if (context.mounted) await _call(context, loc);
  }

  Future<void> _navigate(BuildContext context, AppLocalizations loc) => launchExternalUrl(
        context,
        mapsSearchUri(vet.lat, vet.lng),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.couldNotOpenMapsMsg,
      );

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppShadows.md,
        border: Border.all(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onViewProfile,
        borderRadius: AppSpacing.cardRadius,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'vet-avatar-${vet.id}',
                    child: VetAvatar(
                        profileImageUrl: vet.profileImageUrl,
                        name: vet.name,
                        radius: 32),
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
                                vet.name,
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (vet.isVerified)
                              const Icon(Icons.verified_rounded,
                                  size: 16, color: AppColors.info),
                          ],
                        ),
                        Text(
                          vet.qualification,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (vet.rating > 0) ...[
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 2),
                              Text(
                                  loc.ratingCountMsg(
                                      vet.rating.toStringAsFixed(1), vet.reviewCount),
                                  style: Theme.of(context).textTheme.bodySmall),
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            if (vet.yearsOfExperience > 0) ...[
                              const Icon(Icons.work_history_rounded,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 2),
                              Text(loc.yearsExpMsg(vet.yearsOfExperience),
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me_rounded,
                                size: 11, color: AppColors.primary),
                            const SizedBox(width: 3),
                            Text(formatDistanceAway(distanceKm, loc),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (vet.isAvailable24x7) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(loc.availableTodayLabel,
                              style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      '${vet.village}, ${vet.district}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (vet.specialization.isNotEmpty ||
                  vet.languages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (vet.specialization.isNotEmpty)
                      _Tag(vet.specialization, AppColors.primary),
                    ...vet.languages.map((l) => _Tag(l, AppColors.secondary)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(context, loc),
                      icon: const Icon(Icons.call_rounded, size: 15),
                      label: Text(loc.callBtn),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigate(context, loc),
                      icon: const Icon(Icons.directions_rounded, size: 15),
                      label: Text(loc.navigateBtn),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _book(context, loc),
                      icon: const Icon(Icons.event_available_rounded, size: 15),
                      label: Text(loc.bookBtn),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextButton(
                onPressed: onViewProfile,
                style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 32)),
                child: Text(loc.viewProfileBtn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
