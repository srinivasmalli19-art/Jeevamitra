import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/responsive_center.dart';
import '../../widgets/common/standard_app_bar.dart';

/// Settings screen consolidating account-level options that previously had
/// no dedicated home (language, sign out, delete account) into one place,
/// reachable from Profile's AppBar. Only wires up functionality that
/// already exists elsewhere (`localeProvider`, `authNotifierProvider`) —
/// no theme/notification-preference/About-Privacy-Terms sections, since
/// none of that functionality exists in the app yet.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: StandardAppBar(title: loc.settings),
      body: ResponsiveCenter(
        maxWidth: 560,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.base),
            _SettingsSection(
              title: loc.language,
              icon: Icons.language_rounded,
              child: _LanguageOptions(
                selected: locale.languageCode,
                onSelect: (code) =>
                    ref.read(localeProvider.notifier).setLanguage(code),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SettingsSection(
              title: loc.accountLabel,
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    label: loc.logout,
                    onTap: () => _signOut(context, ref),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: AppColors.error,
                    labelColor: AppColors.error,
                    label: loc.deleteAccountTitle,
                    subtitle: loc.deleteAccountSubtitle,
                    onTap: () => _deleteAccount(context, ref, uid),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Center(
              child: Text(
                'JeevaMitra v1.0.0',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textDisabled),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await _confirmDialog(
      context,
      title: loc.logout,
      body: loc.logoutConfirm,
      confirmLabel: loc.logout,
      destructive: false,
    );
    if (confirmed != true) return;
    await ref.read(authNotifierProvider.notifier).signOut();
    if (context.mounted) context.go(RouteConstants.phoneLogin);
  }

  Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref, String uid) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await _confirmDialog(
      context,
      title: loc.deleteAccountTitle,
      body: loc.deleteAccountBody,
      confirmLabel: loc.deleteBtn,
      destructive: true,
    );
    if (confirmed != true) return;
    final error = await ref.read(authNotifierProvider.notifier).deleteAccount(uid);
    if (!context.mounted) return;
    if (error == null) {
      context.go(RouteConstants.phoneLogin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) {
    final loc = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancelBtn)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: destructive
                ? TextButton.styleFrom(foregroundColor: AppColors.error)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Section card ───────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.cardRadius,
            boxShadow: AppShadows.sm,
            border: Border.all(color: AppColors.outline),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─── Language options ────────────────────────────────────────────────────────

class _LanguageOptions extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _LanguageOptions({required this.selected, required this.onSelect});

  static const _langs = [
    ('te', 'తెలుగు', 'Telugu'),
    ('hi', 'हिन्दी', 'Hindi'),
    ('en', 'English', 'English'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _langs.map((lang) {
        final active = lang.$1 == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: InkWell(
              onTap: () => onSelect(lang.$1),
              borderRadius: AppSpacing.cardRadius,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md, horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryContainer
                      : AppColors.surfaceVariant,
                  borderRadius: AppSpacing.cardRadius,
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.outline,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(lang.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        )),
                    Text(lang.$3,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Tappable settings row ───────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color? labelColor;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.label,
    this.labelColor,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w600, color: labelColor),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }
}
