import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/user_profile_type.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../widgets/common/jm_button.dart';

/// "Choose Your Profile" — reused at two points in the app:
///  - pre-auth, between Welcome (OnboardingScreen) and Phone Login, for new
///    signups (the selection is held in `pendingProfileTypeProvider` until
///    OTP succeeds, since there's no uid to write to yet).
///  - post-auth, as the existing `/auth/role` fallback for the rare case an
///    authenticated user has no Firestore doc and no pending selection
///    (e.g. a dev/test login that jumped straight to OTP).
///
/// The widget itself only presents the three profiles and reports the
/// selection back via [onContinue]; each route decides what happens next,
/// so this file has no auth/Firestore/navigation logic of its own.
class ChooseProfileScreen extends ConsumerStatefulWidget {
  final Future<void> Function(BuildContext context, WidgetRef ref, UserProfileType selected)
      onContinue;
  final UserProfileType? initialSelection;

  const ChooseProfileScreen({
    super.key,
    required this.onContinue,
    this.initialSelection,
  });

  @override
  ConsumerState<ChooseProfileScreen> createState() => _ChooseProfileScreenState();
}

class _ChooseProfileScreenState extends ConsumerState<ChooseProfileScreen> {
  UserProfileType? _selected;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
  }

  Future<void> _proceed() async {
    final selected = _selected;
    if (selected == null || _submitting) return;
    setState(() => _submitting = true);
    await widget.onContinue(context, ref, selected);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Text(loc.chooseProfileTitle,
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(loc.chooseProfileSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: ListView(
                  children: [
                    _ProfileTile(
                      emoji: '🐄',
                      title: loc.profileLivestockOwner,
                      description: loc.profileLivestockOwnerDesc,
                      color: AppColors.secondary,
                      isSelected: _selected == UserProfileType.livestockOwner,
                      onTap: () =>
                          setState(() => _selected = UserProfileType.livestockOwner),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _ProfileTile(
                      emoji: '🌾',
                      title: loc.profileFodderLandProvider,
                      description: loc.profileFodderLandProviderDesc,
                      color: AppColors.primary,
                      isSelected:
                          _selected == UserProfileType.fodderLandProvider,
                      onTap: () => setState(
                          () => _selected = UserProfileType.fodderLandProvider),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _ProfileTile(
                      emoji: '🔄',
                      title: loc.profileBoth,
                      description: loc.profileBothDesc,
                      color: AppColors.info,
                      isSelected: _selected == UserProfileType.both,
                      onTap: () => setState(() => _selected = UserProfileType.both),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoContainer,
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.info),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        loc.profilePersonalizationNoticeMsg,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              JmButton(
                label: loc.continueBtn,
                onPressed: _selected == null || _submitting ? null : _proceed,
                isLoading: _submitting,
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withAlpha(26) : AppColors.surface,
      borderRadius: AppSpacing.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : AppColors.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: AppSpacing.cardRadius,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(description, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
