import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/vet/vet_providers.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';

class VetDetailScreen extends ConsumerWidget {
  final String vetId;
  const VetDetailScreen({super.key, required this.vetId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vetAsync = ref.watch(vetDetailProvider(vetId));
    final locAsync = ref.watch(locationProvider);

    return vetAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Vet Details')),
        body: JmErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(vetDetailProvider(vetId)),
        ),
      ),
      data: (vet) {
        if (vet == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vet Details')),
            body: const Center(child: Text('Veterinarian not found')),
          );
        }

        String? distLabel;
        final loc = locAsync.valueOrNull;
        if (loc != null) {
          final km = LocationService()
              .distanceBetween(loc.lat, loc.lng, vet.lat, vet.lng);
          distLabel = km < 1
              ? '${(km * 1000).toInt()} m away'
              : '${km.toStringAsFixed(1)} km away';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Vet Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () => _share(context, vet.name, vet.phone),
              ),
            ],
          ),
          body: ListView(
            padding: AppSpacing.screenPadding,
            children: [
              const SizedBox(height: AppSpacing.base),
              // Profile header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryContainer,
                    backgroundImage: vet.profileImageUrl != null
                        ? NetworkImage(vet.profileImageUrl!)
                        : null,
                    onBackgroundImageError: vet.profileImageUrl != null ? (_, __) {} : null,
                    child: vet.profileImageUrl == null
                        ? Text(
                            vet.name.isNotEmpty
                                ? vet.name[0].toUpperCase()
                                : 'V',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary),
                          )
                        : null,
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
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                  maxLines: 2),
                            ),
                            if (vet.isVerified)
                              const Tooltip(
                                message: 'Verified Veterinarian',
                                child: Icon(Icons.verified_rounded,
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
                        label: 'Govt Vet',
                        icon: Icons.account_balance_rounded,
                        color: AppColors.info,
                        bg: AppColors.infoContainer),
                  if (vet.isAvailable24x7)
                    _Badge(
                        label: '24×7 Available',
                        icon: Icons.access_time_filled_rounded,
                        color: AppColors.success,
                        bg: AppColors.successContainer),
                  if (vet.isFree)
                    _Badge(
                        label: 'Free Consultation',
                        icon: Icons.money_off_rounded,
                        color: AppColors.success,
                        bg: AppColors.successContainer)
                  else if (vet.consultationFee != null)
                    _Badge(
                        label: '₹${vet.consultationFee!.toStringAsFixed(0)} Fee',
                        icon: Icons.currency_rupee_rounded,
                        color: AppColors.secondary,
                        bg: AppColors.secondaryContainer),
                  if (vet.rating > 0)
                    _Badge(
                        label: '${vet.rating.toStringAsFixed(1)} ★ (${vet.reviewCount})',
                        icon: Icons.star_rounded,
                        color: AppColors.warning,
                        bg: AppColors.warningContainer),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // Location
              _InfoTile(
                icon: Icons.location_on_rounded,
                title: 'Location',
                subtitle: '${vet.village}, ${vet.district}, ${vet.state}',
                trailing: distLabel,
              ),
              if (vet.services.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Services', style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: AppSpacing.xxl),
              // Contact actions
              Text('Contact',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _call(context, vet.phone),
                      icon: const Icon(Icons.call_rounded),
                      label: const Text('Call'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        minimumSize:
                            const Size(double.infinity, AppSpacing.buttonHeight),
                      ),
                    ),
                  ),
                  if (vet.whatsapp != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _whatsapp(context, vet.whatsapp!),
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(
                              double.infinity, AppSpacing.buttonHeight),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _copyPhone(context, vet.phone),
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
        );
      },
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  Future<void> _whatsapp(BuildContext context, String phone) async {
    final number = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/91$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not installed')),
      );
    }
  }

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied')),
    );
  }

  void _share(BuildContext context, String name, String phone) {
    Clipboard.setData(ClipboardData(text: '$name — $phone'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vet contact copied to clipboard')),
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
  final String? trailing;

  const _InfoTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing});

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
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        if (trailing != null)
          Text(trailing!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
