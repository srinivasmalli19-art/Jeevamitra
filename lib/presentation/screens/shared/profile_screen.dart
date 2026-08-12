import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/booking/booking_providers.dart';
import '../../providers/farm/farm_providers.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/common/responsive_center.dart';
import '../../widgets/common/standard_app_bar.dart';

// ─── Shared profile screen ────────────────────────────────────────────────────

class ProfileScreen extends ConsumerStatefulWidget {
  final String role; // 'farmer' | 'shepherd'
  const ProfileScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;

  late final _nameCtrl = TextEditingController();
  late final _villageCtrl = TextEditingController();
  late final _districtCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  void _startEdit(userDoc) {
    _nameCtrl.text = userDoc?.name ?? '';
    _villageCtrl.text = userDoc?.village ?? '';
    _districtCtrl.text = userDoc?.district ?? '';
    setState(() => _editing = true);
  }

  Future<void> _saveEdit(String uid) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final ok = await ref.read(authNotifierProvider.notifier).updateProfile(
          uid: uid,
          name: _nameCtrl.text.trim(),
          village: _villageCtrl.text.trim(),
          district: _districtCtrl.text.trim(),
          preferredLanguage: ref.read(localeProvider).languageCode,
        );
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    if (mounted && !ok) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.genericSaveFailedMsg)),
      );
    }
  }

  Future<void> _signOut() async {
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
    if (mounted) context.go(RouteConstants.phoneLogin);
  }

  Future<void> _deleteAccount(String uid) async {
    final loc = AppLocalizations.of(context);
    final confirmed = await _confirmDialog(
      context,
      title: loc.deleteAccountTitle,
      body: loc.deleteAccountBody,
      confirmLabel: loc.deleteBtn,
      destructive: true,
    );
    if (confirmed != true) return;
    final error =
        await ref.read(authNotifierProvider.notifier).deleteAccount(uid);
    if (!mounted) return;
    if (error == null) {
      context.go(RouteConstants.phoneLogin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(currentUserDocProvider).valueOrNull;
    final locale = ref.watch(localeProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: StandardAppBar(
        title: loc.profile,
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: loc.editBtn,
              onPressed: () => _startEdit(userDoc),
            ),
          if (_editing)
            TextButton(
              onPressed:
                  _saving ? null : () => setState(() => _editing = false),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(loc.cancelBtn),
            ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: 560,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.base),
            // ── Avatar + name header ─────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: widget.role == 'farmer'
                        ? AppColors.primaryContainer
                        : AppColors.secondaryContainer,
                    child: Text(
                      (userDoc?.name.isNotEmpty == true)
                          ? userDoc!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: widget.role == 'farmer'
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    userDoc?.name ?? '—',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: widget.role == 'farmer'
                              ? AppColors.primaryContainer
                              : AppColors.secondaryContainer,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Text(
                          widget.role == 'farmer'
                              ? '🌾 ${loc.roleFarmer}'
                              : '🐑 ${loc.roleShepherd}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.role == 'farmer'
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        userDoc?.phone ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Stats ────────────────────────────────────────────────────────
            _StatsRow(role: widget.role),
            const SizedBox(height: AppSpacing.xl),
            // ── Edit form ────────────────────────────────────────────────────
            if (_editing) ...[
              _SectionHeader(loc.editProfileTitle),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.yourName,
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _villageCtrl,
                decoration: InputDecoration(
                  labelText: loc.yourVillage,
                  prefixIcon: const Icon(Icons.location_city_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _districtCtrl,
                decoration: InputDecoration(
                  labelText: loc.yourDistrict,
                  prefixIcon: const Icon(Icons.map_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              FilledButton.icon(
                onPressed: _saving ? null : () => _saveEdit(uid),
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded),
                label: Text(loc.saveBtn),
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, AppSpacing.buttonHeight),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              // Read-only info
              _SectionHeader(loc.profileInfoLabel),
              const SizedBox(height: AppSpacing.sm),
              _InfoCard(children: [
                _InfoRow(
                    Icons.person_rounded, loc.yourName, userDoc?.name ?? '—'),
                _InfoRow(Icons.phone_rounded, loc.mobileNumber,
                    userDoc?.phone ?? '—'),
                _InfoRow(Icons.location_city_rounded, loc.yourVillage,
                    userDoc?.village ?? '—'),
                _InfoRow(Icons.map_rounded, loc.yourDistrict,
                    userDoc?.district ?? '—'),
              ]),
              const SizedBox(height: AppSpacing.xl),
            ],
            // ── Language preference ──────────────────────────────────────────
            _SectionHeader(loc.language),
            const SizedBox(height: AppSpacing.sm),
            _LanguageSelector(
              selected: locale.languageCode,
              onSelect: (code) async {
                await ref.read(localeProvider.notifier).setLanguage(code);
                if (uid.isNotEmpty) {
                  await ref.read(authNotifierProvider.notifier).updateProfile(
                        uid: uid,
                        name: userDoc?.name ?? '',
                        village: userDoc?.village ?? '',
                        district: userDoc?.district ?? '',
                        preferredLanguage: code,
                      );
                }
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Account actions ──────────────────────────────────────────────
            _SectionHeader(loc.accountLabel),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.textSecondary),
              title: Text(loc.logout),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled),
              onTap: _signOut,
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.error),
              title: Text(loc.deleteAccountTitle,
                  style: const TextStyle(color: AppColors.error)),
              subtitle: Text(loc.deleteAccountSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textDisabled),
              onTap: () => _deleteAccount(uid),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── App version ──────────────────────────────────────────────────
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

  Future<bool?> _confirmDialog(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    required bool destructive,
  }) =>
      showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
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

// ─── Stats row (role-specific) ────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  final String role;
  const _StatsRow({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    if (role == 'farmer') {
      final farms = ref.watch(myFarmsProvider).valueOrNull ?? [];
      final bookings = ref.watch(farmerBookingsProvider).valueOrNull ?? [];
      final pending = bookings.where((b) => b.isPending).length;
      final completed = bookings.where((b) => b.isCompleted).length;
      return Row(children: [
        _StatChip(value: '${farms.length}', label: loc.landsLabel),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$pending', label: loc.bookingPending),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$completed', label: loc.bookingCompleted),
      ]);
    } else {
      final bookings = ref.watch(shepherdBookingsProvider).valueOrNull ?? [];
      final active = bookings.where((b) => b.isActive || b.isConfirmed).length;
      final completed = bookings.where((b) => b.isCompleted).length;
      return Row(children: [
        _StatChip(value: '${bookings.length}', label: loc.totalTripsLabel),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$active', label: loc.bookingActive),
        const SizedBox(width: AppSpacing.sm),
        _StatChip(value: '$completed', label: loc.bookingCompleted),
      ]);
    }
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppSpacing.cardRadius,
        ),
        child: Column(
          children: [
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Language selector ────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _LanguageSelector({required this.selected, required this.onSelect});

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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        )),
                    Text(lang.$3, style: Theme.of(context).textTheme.bodySmall),
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

// ─── Small widgets ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: AppColors.textSecondary),
      );
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        color: AppColors.surfaceVariant,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(children: children),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
