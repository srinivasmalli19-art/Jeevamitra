import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/distance_formatter.dart';
import '../../../../core/utils/geo_hash_helper.dart';
import '../../../../core/utils/url_launch_helper.dart';
import '../../../../generated/l10n/app_localizations.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/cached_farm_image.dart';
import '../../../widgets/common/full_screen_photo_viewer.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/responsive_center.dart';
import '../../../widgets/explore/empty_state_card.dart';
import '../../../widgets/explore/retry_card.dart';
import '../../../widgets/explore/vet_avatar.dart';

class VetDetailScreen extends ConsumerWidget {
  final String vetId;
  const VetDetailScreen({super.key, required this.vetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final vetAsync = ref.watch(vetDetailProvider(vetId));
    final locAsync = ref.watch(locationProvider);

    return vetAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(loc.vetDetailsTitle)),
        body: RetryCard(
          error: e,
          onRetry: () => ref.invalidate(vetDetailProvider(vetId)),
        ),
      ),
      data: (vet) {
        if (vet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(loc.vetDetailsTitle)),
            body: EmptyStateCard(
              icon: Icons.person_off_rounded,
              title: loc.veterinarianNotFoundTitle,
              subtitle: loc.profileRemovedMsg,
            ),
          );
        }

        // Distance from shepherd's current location — GeoHashHelper.distanceKm,
        // the same Haversine formula the repository uses to filter/sort
        // nearby results, so a card's displayed distance can never
        // disagree with the one shown here for the same vet.
        String? distLabel;
        final userLoc = locAsync.valueOrNull;
        if (userLoc != null) {
          final km =
              GeoHashHelper.distanceKm(userLoc.lat, userLoc.lng, vet.lat, vet.lng);
          distLabel = formatDistanceAway(km, loc);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(loc.vetProfileTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: loc.shareTooltip,
                onPressed: () => _share(context, vet.name, vet.phone, loc),
              ),
            ],
          ),
          body: ResponsiveCenter(
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                const SizedBox(height: AppSpacing.base),
                // Profile header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'vet-avatar-${vet.id}',
                      child: VetAvatar(
                          profileImageUrl: vet.profileImageUrl,
                          name: vet.name,
                          radius: 40),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(vet.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                    maxLines: 2),
                              ),
                              if (vet.isVerified)
                                Tooltip(
                                  message: loc.verifiedVeterinarianMsg,
                                  child: const Icon(Icons.verified_rounded,
                                      color: AppColors.info, size: 20),
                                ),
                            ],
                          ),
                          Text(vet.qualification,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary)),
                          if (vet.specialization.isNotEmpty)
                            Text(vet.specialization,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.primary)),
                          if (distLabel != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.near_me_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(distLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Quick badges
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (vet.isGovtVet)
                      _Badge(
                          label: loc.govtVet,
                          icon: Icons.account_balance_rounded,
                          color: AppColors.info,
                          bg: AppColors.infoContainer),
                    if (vet.isAvailable24x7)
                      _Badge(
                          label: loc.availableTodayLabel,
                          icon: Icons.event_available_rounded,
                          color: AppColors.success,
                          bg: AppColors.successContainer),
                    if (vet.isFree)
                      _Badge(
                          label: loc.freeConsultationLabel,
                          icon: Icons.money_off_rounded,
                          color: AppColors.success,
                          bg: AppColors.successContainer)
                    else if (vet.consultationFee != null)
                      _Badge(
                          label:
                              '₹${vet.consultationFee!.toStringAsFixed(0)}${loc.feeSuffix}',
                          icon: Icons.currency_rupee_rounded,
                          color: AppColors.secondary,
                          bg: AppColors.secondaryContainer),
                    if (vet.rating > 0)
                      _Badge(
                          label: loc.ratingStarCountMsg(
                              vet.rating.toStringAsFixed(1), vet.reviewCount),
                          icon: Icons.star_rounded,
                          color: AppColors.warning,
                          bg: AppColors.warningContainer),
                    if (vet.yearsOfExperience > 0)
                      _Badge(
                          label: loc.yearsExpMsg(vet.yearsOfExperience),
                          icon: Icons.work_history_rounded,
                          color: AppColors.primary,
                          bg: AppColors.primaryContainer),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                // Location
                _InfoTile(
                  icon: Icons.location_on_rounded,
                  title: loc.locationLabel,
                  subtitle: '${vet.village}, ${vet.district}, ${vet.state}',
                ),
                if (vet.languages.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(loc.languagesTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: vet.languages
                        .map((l) => Chip(
                              avatar:
                                  const Icon(Icons.translate_rounded, size: 16),
                              label: Text(l),
                              backgroundColor: AppColors.surfaceVariant,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
                if (vet.services.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(loc.servicesTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: vet.services
                        .map((s) => Chip(
                              label: Text(s),
                              backgroundColor: AppColors.surfaceVariant,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
                if (vet.galleryUrls.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(loc.galleryTitle,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vet.galleryUrls.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => showFullScreenPhotoViewer(
                          context,
                          urls: vet.galleryUrls,
                          initialIndex: i,
                        ),
                        child: ClipRRect(
                          borderRadius: AppSpacing.cardRadius,
                          child: CachedFarmImage(
                            url: vet.galleryUrls[i],
                            width: 100,
                            height: 100,
                            errorIcon: Icons.medical_services_rounded,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                // Contact actions
                Text(loc.contactTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _call(context, vet.phone, loc),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(loc.callBtn),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigate(context, vet.lat, vet.lng, loc),
                        icon: const Icon(Icons.directions_rounded),
                        label: Text(loc.navigateBtn),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (vet.whatsapp != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _whatsapp(context, vet.whatsapp!, vet.name, loc),
                          icon: const Icon(Icons.chat_rounded),
                          label: Text(loc.whatsappVet),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, AppSpacing.buttonHeight),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _book(
                            context, vet.whatsapp, vet.phone, vet.name, loc),
                        icon: const Icon(Icons.event_available_rounded),
                        label: Text(loc.bookBtn),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          minimumSize: const Size(0, AppSpacing.buttonHeight),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _copyPhone(context, vet.phone, loc),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: Text(vet.phone),
                  style: OutlinedButton.styleFrom(
                    minimumSize:
                        const Size(double.infinity, AppSpacing.buttonHeight),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _call(BuildContext context, String phone, AppLocalizations loc) =>
      launchExternalUrl(context, telUri(phone),
          failureMessage: loc.couldNotOpenDialerMsg);

  Future<void> _whatsapp(
          BuildContext context, String phone, String name, AppLocalizations loc) =>
      launchExternalUrl(
        context,
        whatsappUri(phone),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.whatsappNotInstalledMsg,
      );

  /// "Book" doesn't create a booking record — vet appointments aren't part
  /// of this app's booking model (Bookings ties farmerId/shepherdId/farmId
  /// together and is explicitly out of scope for this batch). Instead it
  /// opens WhatsApp with a pre-filled booking request, falling back to a
  /// phone call if the vet has no WhatsApp number — the same low-friction
  /// contact mechanism Call/WhatsApp already use.
  Future<void> _book(BuildContext context, String? whatsapp, String phone,
      String name, AppLocalizations loc) async {
    if (whatsapp != null) {
      final launched = await launchExternalUrl(
        context,
        whatsappUri(whatsapp,
            text:
                "Hello $name, I'd like to book a consultation via JeevaMitra."),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.whatsappNotInstalledMsg,
      );
      if (launched) return;
    }
    if (!context.mounted) return;
    await _call(context, phone, loc);
  }

  Future<void> _navigate(
          BuildContext context, double lat, double lng, AppLocalizations loc) =>
      launchExternalUrl(
        context,
        mapsSearchUri(lat, lng),
        mode: LaunchMode.externalApplication,
        failureMessage: loc.couldNotOpenMapsMsg,
      );

  void _copyPhone(BuildContext context, String phone, AppLocalizations loc) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.phoneCopiedMsg)),
    );
  }

  void _share(BuildContext context, String name, String phone, AppLocalizations loc) {
    Clipboard.setData(ClipboardData(text: '$name — $phone'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loc.vetContactCopiedMsg)),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;

  const _Badge(
      {required this.label,
      required this.icon,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _InfoTile(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
