import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../generated/l10n/app_localizations.dart';
import 'alert_filter.dart';
import 'alert_severity.dart';

/// Advanced Filters sheet for the Alert Dashboard: severity, species,
/// village, district, radius, and issued-date range — the same
/// draggable-sheet-with-Reset/Apply shape already established by Nearby
/// Lands' and Vets Nearby's filter sheets.
class AlertFilterSheet extends StatefulWidget {
  final AlertFilterState initial;
  final ValueChanged<AlertFilterState> onApply;

  const AlertFilterSheet({super.key, required this.initial, required this.onApply});

  @override
  State<AlertFilterSheet> createState() => _AlertFilterSheetState();
}

class _AlertFilterSheetState extends State<AlertFilterSheet> {
  late AlertFilterState _filter;
  late final _villageCtrl = TextEditingController(text: widget.initial.village);
  late final _districtCtrl = TextEditingController(text: widget.initial.district);

  static const _radii = [10.0, 25.0, 50.0, 100.0, 150.0];
  static const _severities = ['critical', 'high', 'medium', 'low'];
  static const _speciesValues = ['all', 'sheep', 'goat', 'cattle'];

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
  }

  @override
  void dispose() {
    _villageCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final loc = AppLocalizations.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _filter.issuedFrom : _filter.issuedTo) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: isFrom ? loc.issuedFromHelp : loc.issuedUntilHelp,
    );
    if (picked == null) return;
    setState(() {
      _filter = isFrom ? _filter.copyWith(issuedFrom: picked) : _filter.copyWith(issuedTo: picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.outline, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Text(loc.filtersLabel, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = const AlertFilterState();
                    _villageCtrl.clear();
                    _districtCtrl.clear();
                  }),
                  child: Text(loc.resetBtn),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: AppSpacing.screenPadding,
              children: [
                Text(loc.radiusLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: _radii.map((r) {
                    final selected = r == _filter.radiusKm;
                    return ChoiceChip(
                      label: Text(loc.kmChipLabel(r.toInt())),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = _filter.copyWith(radiusKm: r)),
                      selectedColor: AppColors.primaryContainer,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.severityLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: _severities.map((s) {
                    final severity = AlertSeverity.of(s);
                    final selected = _filter.severities.contains(s);
                    return FilterChip(
                      avatar: Icon(severity.icon, size: 16, color: selected ? severity.color : null),
                      label: Text(severityLabel(s, loc)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        final next = {..._filter.severities};
                        v ? next.add(s) : next.remove(s);
                        _filter = _filter.copyWith(severities: next);
                      }),
                      selectedColor: severity.background,
                      checkmarkColor: severity.color,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.affectedAnimalsLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: _speciesValues.map((val) {
                    final selected = _filter.species.contains(val);
                    return FilterChip(
                      label: Text(speciesLabel(val, loc)),
                      selected: selected,
                      onSelected: (v) => setState(() {
                        final next = {..._filter.species};
                        v ? next.add(val) : next.remove(val);
                        _filter = _filter.copyWith(species: next);
                      }),
                      selectedColor: AppColors.primaryContainer,
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.locationLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _villageCtrl,
                  decoration: InputDecoration(
                    labelText: loc.villageFieldLabel,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => _filter = _filter.copyWith(village: v),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _districtCtrl,
                  decoration: InputDecoration(
                    labelText: loc.yourDistrict,
                    prefixIcon: const Icon(Icons.map_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => _filter = _filter.copyWith(district: v),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(loc.issuedDateLabel, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: true),
                        icon: const Icon(Icons.event_rounded, size: 16),
                        label: Text(_filter.issuedFrom == null
                            ? loc.issuedFromBtn
                            : '${_filter.issuedFrom!.day}/${_filter.issuedFrom!.month}/${_filter.issuedFrom!.year}'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickDate(isFrom: false),
                        icon: const Icon(Icons.event_rounded, size: 16),
                        label: Text(_filter.issuedTo == null
                            ? loc.issuedUntilBtn
                            : '${_filter.issuedTo!.day}/${_filter.issuedTo!.month}/${_filter.issuedTo!.year}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
            child: FilledButton(
              onPressed: () {
                final applied = _filter.copyWith(
                  village: _villageCtrl.text,
                  district: _districtCtrl.text,
                );
                widget.onApply(applied);
                Navigator.of(context).pop();
              },
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSpacing.buttonHeight)),
              child: Text(loc.applyFiltersBtn),
            ),
          ),
        ],
      ),
    );
  }
}
