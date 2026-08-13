import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/geo_hash_helper.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/disease_alert_model.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../providers/alerts/disease_alert_providers.dart';
import '../../widgets/common/jm_button.dart';
import '../../widgets/common/jm_text_field.dart';
import 'alerts/alert_severity.dart';

class ReportAlertScreen extends ConsumerStatefulWidget {
  const ReportAlertScreen({super.key});

  @override
  ConsumerState<ReportAlertScreen> createState() => _ReportAlertScreenState();
}

class _ReportAlertScreenState extends ConsumerState<ReportAlertScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _diseaseCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  final _preventionCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _vetPhoneCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(text: 'Farmer Community Report');
  final _villageCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Andhra Pradesh');

  String _species = 'all';
  String _severity = 'medium';
  double? _lat;
  double? _lng;
  DateTime? _expiresAt;
  bool _locating = false;
  bool _submitting = false;

  static const _speciesValues = ['all', 'sheep', 'goat', 'cattle'];
  static const _severityValues = ['low', 'medium', 'high', 'critical'];

  @override
  void dispose() {
    for (final c in [
      _diseaseCtrl,
      _titleCtrl,
      _descCtrl,
      _symptomsCtrl,
      _preventionCtrl,
      _treatmentCtrl,
      _vetPhoneCtrl,
      _sourceCtrl,
      _villageCtrl,
      _districtCtrl,
      _stateCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _autoTitle() {
    if (_titleCtrl.text.isEmpty && _diseaseCtrl.text.isNotEmpty) {
      final d = _districtCtrl.text.trim();
      _titleCtrl.text =
          '${_diseaseCtrl.text.trim()} Alert${d.isNotEmpty ? ' in $d' : ''}';
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      final loc = await LocationService().getCurrentLocation();
      setState(() {
        _lat = loc.lat;
        _lng = loc.lng;
        _locating = false;
      });
    } catch (e) {
      setState(() => _locating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickOnMap() async {
    final extra = _lat != null ? {'lat': _lat, 'lng': _lng} : null;
    final result = await context
        .push<Map<String, dynamic>>(RouteConstants.mapPicker, extra: extra);
    if (result != null && mounted) {
      setState(() {
        _lat = (result['lat'] as num).toDouble();
        _lng = (result['lng'] as num).toDouble();
      });
    }
  }

  Future<void> _pickExpiry() async {
    final loc = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: loc.alertValidUntilHelp,
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    final loc = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.setLocationMsg)),
      );
      return;
    }

    setState(() => _submitting = true);

    final geohash = GeoHashHelper.encode(_lat!, _lng!);
    final now = DateTime.now();

    final alert = DiseaseAlertModel(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      disease: _diseaseCtrl.text.trim(),
      affectedSpecies: _species,
      severity: _severity,
      village: _villageCtrl.text.trim(),
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      lat: _lat!,
      lng: _lng!,
      geohash: geohash,
      radiusKm: 50,
      symptoms:
          _symptomsCtrl.text.trim().isEmpty ? null : _symptomsCtrl.text.trim(),
      prevention: _preventionCtrl.text.trim().isEmpty
          ? null
          : _preventionCtrl.text.trim(),
      treatment: _treatmentCtrl.text.trim().isEmpty
          ? null
          : _treatmentCtrl.text.trim(),
      vetContactPhone:
          _vetPhoneCtrl.text.trim().isEmpty ? null : _vetPhoneCtrl.text.trim(),
      sourceAuthority: _sourceCtrl.text.trim().isEmpty
          ? 'Farmer Community Report'
          : _sourceCtrl.text.trim(),
      isActive: true,
      issuedAt: now,
      expiresAt: _expiresAt ?? now.add(const Duration(days: 30)),
      reportedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
    );

    final ok = await ref
        .read(diseaseAlertNotifierProvider.notifier)
        .createAlert(alert);

    setState(() => _submitting = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.alertReportedMsg)),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(loc.submitFailedMsg),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.reportAlertTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ── Disease info ──────────────────────────────────────────────
            _SectionHeader(label: loc.diseaseInfoSection),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.diseaseNameLabel,
              controller: _diseaseCtrl,
              hint: loc.diseaseNameHint,
              validator: (v) => Validators.required(v, loc.diseaseNameFieldName),
              onChanged: (_) => _autoTitle(),
              prefixIcon: const Icon(Icons.coronavirus_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.alertTitleLabel,
              controller: _titleCtrl,
              hint: loc.alertTitleHint,
              validator: (v) => Validators.required(v, loc.titleFieldName),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            const SizedBox(height: AppSpacing.base),

            // Affected species
            Text(loc.affectedAnimalsLabel,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _speciesValues.map((val) {
                final selected = _species == val;
                return FilterChip(
                  label: Text(speciesLabel(val, loc)),
                  selected: selected,
                  onSelected: (_) => setState(() => _species = val),
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.base),

            // Severity
            Text(loc.severityLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _severityValues.map((val) {
                final color = AlertSeverity.of(val).color;
                final selected = _severity == val;
                return ChoiceChip(
                  label: Text(severityLabel(val, loc)),
                  selected: selected,
                  onSelected: (_) => setState(() => _severity = val),
                  selectedColor: color.withAlpha(40),
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  side: BorderSide(color: selected ? color : AppColors.outline),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Location ──────────────────────────────────────────────────
            _SectionHeader(label: loc.alertLocationSection),
            const SizedBox(height: AppSpacing.md),
            _LocationCard(
              lat: _lat,
              lng: _lng,
              locating: _locating,
              onDetect: _detectLocation,
              onPickOnMap: _pickOnMap,
              loc: loc,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.villageFieldLabel,
              controller: _villageCtrl,
              prefixIcon: const Icon(Icons.location_city_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.yourDistrict,
              controller: _districtCtrl,
              validator: (v) => Validators.required(v, loc.districtFieldName),
              prefixIcon: const Icon(Icons.map_rounded),
              onChanged: (_) => _autoTitle(),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.stateLabel,
              controller: _stateCtrl,
              validator: (v) => Validators.required(v, loc.stateFieldName),
              prefixIcon: const Icon(Icons.flag_rounded),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Details ───────────────────────────────────────────────────
            _SectionHeader(label: loc.alertDetailsSection),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.descriptionFieldLabel,
              controller: _descCtrl,
              hint: loc.descriptionHint,
              maxLines: 4,
              validator: (v) => Validators.required(v, loc.descriptionFieldName),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.symptomsFieldLabel,
              controller: _symptomsCtrl,
              hint: loc.symptomsHint,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.preventionTipsLabel,
              controller: _preventionCtrl,
              hint: loc.preventionHint,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.treatmentFieldLabel,
              controller: _treatmentCtrl,
              hint: loc.treatmentHint,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.vetContactLabel,
              controller: _vetPhoneCtrl,
              hint: loc.vetContactHint,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Source & Validity ─────────────────────────────────────────
            _SectionHeader(label: loc.sourceValiditySection),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: loc.sourceAuthorityLabel,
              controller: _sourceCtrl,
              hint: loc.sourceAuthorityHint,
              validator: (v) => Validators.required(v, loc.sourceAuthorityFieldName),
              prefixIcon: const Icon(Icons.verified_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: _pickExpiry,
              borderRadius: AppSpacing.cardRadius,
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.outline),
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_rounded,
                        color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.alertValidUntilLabel,
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(
                            _expiresAt != null
                                ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                : loc.defaultValidityMsg,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    color: _expiresAt != null
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            JmButton(
              label: loc.submitAlertBtn,
              leadingIcon: Icons.add_alert_rounded,
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700));
  }
}

class _LocationCard extends StatelessWidget {
  final double? lat;
  final double? lng;
  final bool locating;
  final VoidCallback onDetect;
  final VoidCallback onPickOnMap;
  final AppLocalizations loc;

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.locating,
    required this.onDetect,
    required this.onPickOnMap,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    final hasLoc = lat != null && lng != null;
    return Column(
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color:
                hasLoc ? AppColors.primaryContainer : AppColors.surfaceVariant,
            borderRadius: AppSpacing.cardRadius,
            border: Border.all(
                color: hasLoc ? AppColors.primary : AppColors.outline),
          ),
          child: Row(
            children: [
              Icon(
                hasLoc
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: hasLoc ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasLoc
                      ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                      : loc.noLocationSetMsg,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasLoc
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight:
                            hasLoc ? FontWeight.w600 : FontWeight.normal,
                      ),
                ),
              ),
              if (locating)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                TextButton(
                  onPressed: onDetect,
                  child: Text(hasLoc ? loc.updateBtn : loc.detectBtn),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onPickOnMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(hasLoc ? loc.adjustOnMapBtn : loc.pickOnMapBtn),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }
}
