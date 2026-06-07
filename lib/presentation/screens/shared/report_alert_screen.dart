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
import '../../providers/alerts/disease_alert_providers.dart';
import '../../widgets/common/jm_button.dart';
import '../../widgets/common/jm_text_field.dart';

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
  final _preventionCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _vetPhoneCtrl = TextEditingController();
  final _sourceCtrl =
      TextEditingController(text: 'Farmer Community Report');
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController(text: 'Andhra Pradesh');

  String _species = 'all';
  String _severity = 'medium';
  double? _lat;
  double? _lng;
  DateTime? _expiresAt;
  bool _locating = false;
  bool _submitting = false;

  static const _speciesOptions = [
    ('all', 'All Animals'),
    ('sheep', 'Sheep'),
    ('goat', 'Goat'),
    ('cattle', 'Cattle'),
  ];

  static const _severityOptions = [
    ('low', 'Low', AppColors.textSecondary),
    ('medium', 'Medium', AppColors.info),
    ('high', 'High', AppColors.warning),
    ('critical', 'Critical', AppColors.error),
  ];

  @override
  void dispose() {
    for (final c in [
      _diseaseCtrl, _titleCtrl, _descCtrl, _preventionCtrl,
      _treatmentCtrl, _vetPhoneCtrl, _sourceCtrl, _districtCtrl, _stateCtrl,
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
              content: Text(e.toString()),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _pickOnMap() async {
    final extra =
        _lat != null ? {'lat': _lat, 'lng': _lng} : null;
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
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Alert valid until',
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lat == null || _lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set the alert location')),
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
      district: _districtCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      lat: _lat!,
      lng: _lng!,
      geohash: geohash,
      radiusKm: 50,
      prevention:
          _preventionCtrl.text.trim().isEmpty ? null : _preventionCtrl.text.trim(),
      treatment:
          _treatmentCtrl.text.trim().isEmpty ? null : _treatmentCtrl.text.trim(),
      vetContactPhone:
          _vetPhoneCtrl.text.trim().isEmpty ? null : _vetPhoneCtrl.text.trim(),
      sourceAuthority: _sourceCtrl.text.trim().isEmpty
          ? 'Farmer Community Report'
          : _sourceCtrl.text.trim(),
      isActive: true,
      issuedAt: now,
      expiresAt: _expiresAt ?? now.add(const Duration(days: 30)),
    );

    final ok = await ref
        .read(diseaseAlertNotifierProvider.notifier)
        .createAlert(alert);

    setState(() => _submitting = false);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert reported. Thank you!')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit. Please try again.'),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Disease Alert')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: AppSpacing.sm),

            // ── Disease info ──────────────────────────────────────────────
            _SectionHeader(label: 'Disease Information'),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Disease Name *',
              controller: _diseaseCtrl,
              hint: 'e.g. Foot & Mouth Disease',
              validator: (v) => Validators.required(v, 'Disease name'),
              onChanged: (_) => _autoTitle(),
              prefixIcon: const Icon(Icons.coronavirus_rounded),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Alert Title *',
              controller: _titleCtrl,
              hint: 'e.g. FMD Alert in Guntur',
              validator: (v) => Validators.required(v, 'Title'),
              prefixIcon: const Icon(Icons.title_rounded),
            ),
            const SizedBox(height: AppSpacing.base),

            // Affected species
            Text('Affected Animals',
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _speciesOptions.map((opt) {
                final (val, label) = opt;
                final selected = _species == val;
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _species = val),
                  selectedColor: AppColors.primaryContainer,
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.base),

            // Severity
            Text('Severity', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: _severityOptions.map((opt) {
                final (val, label, color) = opt;
                final selected = _severity == val;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (_) => setState(() => _severity = val),
                  selectedColor: color.withAlpha(40),
                  labelStyle: TextStyle(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.normal,
                  ),
                  side: BorderSide(
                      color: selected ? color : AppColors.outline),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Location ──────────────────────────────────────────────────
            _SectionHeader(label: 'Alert Location'),
            const SizedBox(height: AppSpacing.md),
            _LocationCard(
              lat: _lat,
              lng: _lng,
              locating: _locating,
              onDetect: _detectLocation,
              onPickOnMap: _pickOnMap,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'District *',
              controller: _districtCtrl,
              validator: (v) => Validators.required(v, 'District'),
              prefixIcon: const Icon(Icons.map_rounded),
              onChanged: (_) => _autoTitle(),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'State *',
              controller: _stateCtrl,
              validator: (v) => Validators.required(v, 'State'),
              prefixIcon: const Icon(Icons.flag_rounded),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Details ───────────────────────────────────────────────────
            _SectionHeader(label: 'Alert Details'),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Description *',
              controller: _descCtrl,
              hint: 'Describe the symptoms and spread pattern…',
              maxLines: 4,
              validator: (v) => Validators.required(v, 'Description'),
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Prevention Tips (optional)',
              controller: _preventionCtrl,
              hint: 'What farmers can do to protect their animals…',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Treatment (optional)',
              controller: _treatmentCtrl,
              hint: 'Recommended treatment or medication…',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Vet Contact Number (optional)',
              controller: _vetPhoneCtrl,
              hint: '+91 98765 43210',
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.phone_rounded),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Source & Validity ─────────────────────────────────────────
            _SectionHeader(label: 'Source & Validity'),
            const SizedBox(height: AppSpacing.md),
            JmTextField(
              label: 'Source Authority *',
              controller: _sourceCtrl,
              hint: 'e.g. Animal Husbandry Dept., Farmer Community',
              validator: (v) => Validators.required(v, 'Source authority'),
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
                          Text('Alert Valid Until',
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(
                            _expiresAt != null
                                ? '${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year}'
                                : '30 days from today (default)',
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
              label: 'Submit Alert',
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

  const _LocationCard({
    required this.lat,
    required this.lng,
    required this.locating,
    required this.onDetect,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final hasLoc = lat != null && lng != null;
    return Column(
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: hasLoc
                ? AppColors.primaryContainer
                : AppColors.surfaceVariant,
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
                color:
                    hasLoc ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  hasLoc
                      ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                      : 'No location set',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasLoc
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: hasLoc
                            ? FontWeight.w600
                            : FontWeight.normal,
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
                  child: Text(hasLoc ? 'Update' : 'Detect'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onPickOnMap,
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(hasLoc ? 'Adjust on Map' : 'Pick on Map'),
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
