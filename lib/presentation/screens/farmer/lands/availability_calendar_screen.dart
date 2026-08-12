import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/firebase_error_translator.dart';
import '../../../../data/models/farm_blocked_period.dart';
import '../../../../data/repositories/farm_availability_repository.dart';
import '../../../providers/farm/farm_availability_providers.dart';
import '../../../widgets/common/jm_button.dart';
import '../../../widgets/common/jm_error_state.dart';
import '../../../widgets/common/jm_loading.dart';
import '../../../widgets/common/standard_app_bar.dart';

class AvailabilityCalendarScreen extends ConsumerStatefulWidget {
  final String farmId;
  const AvailabilityCalendarScreen({super.key, required this.farmId});

  @override
  ConsumerState<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends ConsumerState<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  bool _isBlocked(DateTime day, List<FarmBlockedPeriod> periods) =>
      periods.any((p) => p.containsDate(day));

  void _clearSelection() => setState(() {
        _rangeStart = null;
        _rangeEnd = null;
        _reasonCtrl.clear();
      });

  Future<void> _save(List<FarmBlockedPeriod> existing) async {
    final start = _rangeStart;
    final end = _rangeEnd ?? _rangeStart;
    if (start == null || end == null) return;

    if (FarmAvailabilityRepository.hasConflict(
        existing, start, end.add(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Selected range overlaps an existing blocked period.')),
      );
      return;
    }

    setState(() => _saving = true);
    final error = await ref
        .read(farmAvailabilityNotifierProvider.notifier)
        .addBlockedPeriod(widget.farmId, start, end, _reasonCtrl.text.trim());
    setState(() => _saving = false);

    if (!mounted) return;
    if (error == null) {
      _clearSelection();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dates blocked successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(friendlyFirebaseMessage(error)),
            backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _delete(FarmBlockedPeriod period) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Blocked Period?'),
        content: Text(
            'Allow bookings for ${_fmt(period.startDate)} – ${_fmt(period.endDate)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref
        .read(farmAvailabilityNotifierProvider.notifier)
        .removeBlockedPeriod(widget.farmId, period.id);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(friendlyFirebaseMessage(error)),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(farmBlockedPeriodsProvider(widget.farmId));

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Manage Availability',
        actions: [
          if (_rangeStart != null)
            TextButton(
              onPressed: _clearSelection,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: periodsAsync.when(
        loading: () => const Center(child: JmLoading()),
        error: (e, _) => JmErrorState(
          message: friendlyFirebaseMessage(e),
          onRetry: () => ref.invalidate(farmBlockedPeriodsProvider(widget.farmId)),
        ),
        data: (periods) => _Body(
          periods: periods,
          focusedDay: _focusedDay,
          rangeStart: _rangeStart,
          rangeEnd: _rangeEnd,
          reasonCtrl: _reasonCtrl,
          saving: _saving,
          isBlocked: (d) => _isBlocked(d, periods),
          onRangeSelected: (start, end, focused) => setState(() {
            _focusedDay = focused;
            _rangeStart = start;
            _rangeEnd = end;
          }),
          onPageChanged: (day) => setState(() => _focusedDay = day),
          onSave: () => _save(periods),
          onDelete: _delete,
          fmt: _fmt,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<FarmBlockedPeriod> periods;
  final DateTime focusedDay;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final TextEditingController reasonCtrl;
  final bool saving;
  final bool Function(DateTime) isBlocked;
  final void Function(DateTime?, DateTime?, DateTime) onRangeSelected;
  final void Function(DateTime) onPageChanged;
  final VoidCallback onSave;
  final Future<void> Function(FarmBlockedPeriod) onDelete;
  final String Function(DateTime) fmt;

  const _Body({
    required this.periods,
    required this.focusedDay,
    required this.rangeStart,
    required this.rangeEnd,
    required this.reasonCtrl,
    required this.saving,
    required this.isBlocked,
    required this.onRangeSelected,
    required this.onPageChanged,
    required this.onSave,
    required this.onDelete,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // ── Legend ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.md, AppSpacing.base, 0),
          child: Row(
            children: [
              _LegendDot(color: AppColors.error, label: 'Blocked'),
              const SizedBox(width: AppSpacing.base),
              _LegendDot(color: AppColors.primary, label: 'Selected range'),
            ],
          ),
        ),

        // ── Calendar ────────────────────────────────────────────────────────
        TableCalendar(
          firstDay: DateTime.now(),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: focusedDay,
          rangeStartDay: rangeStart,
          rangeEndDay: rangeEnd,
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          onRangeSelected: onRangeSelected,
          onPageChanged: onPageChanged,
          headerStyle: const HeaderStyle(formatButtonVisible: false),
          calendarStyle: CalendarStyle(
            rangeHighlightColor: AppColors.primary.withAlpha(40),
            rangeStartDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            withinRangeDecoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
            ),
            withinRangeTextStyle: const TextStyle(color: AppColors.primary),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) =>
                isBlocked(day) ? _BlockedCell(day: day) : null,
            outsideBuilder: (context, day, _) =>
                isBlocked(day) ? _BlockedCell(day: day, outside: true) : null,
          ),
        ),

        // ── Selection panel ────────────────────────────────────────────────
        if (rangeStart != null) ...[
          const Divider(height: 1),
          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rangeEnd != null
                            ? '${fmt(rangeStart!)} – ${fmt(rangeEnd!)}'
                            : fmt(rangeStart!),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (rangeEnd != null)
                      Text(
                        '${rangeEnd!.difference(rangeStart!).inDays + 1} days',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (optional)',
                    hintText: 'e.g. Harvesting season, personal use…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                JmButton(
                  label: 'Block These Dates',
                  leadingIcon: Icons.block_rounded,
                  isLoading: saving,
                  onPressed: saving ? null : onSave,
                ),
              ],
            ),
          ),
        ],

        // ── Existing blocked periods ───────────────────────────────────────
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
          child: Text('Blocked Periods (${periods.length})',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        if (periods.isEmpty)
          Padding(
            padding: const EdgeInsets.only(
                left: AppSpacing.base, bottom: AppSpacing.xl),
            child: Text('No blocked periods — all dates available.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          )
        else
          ...periods.map(
            (p) => ListTile(
              leading: const Icon(Icons.block_rounded,
                  color: AppColors.error, size: 20),
              title: Text('${fmt(p.startDate)} – ${fmt(p.endDate)}'),
              subtitle: p.reason != null
                  ? Text(p.reason!,
                      style: Theme.of(context).textTheme.bodySmall)
                  : Text(
                      '${p.lengthInDays} day${p.lengthInDays == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                tooltip: 'Remove',
                onPressed: () => onDelete(p),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _BlockedCell extends StatelessWidget {
  final DateTime day;
  final bool outside;
  const _BlockedCell({required this.day, this.outside = false});

  @override
  Widget build(BuildContext context) {
    final alpha = outside ? 15 : 30;
    final textAlpha = outside ? 100 : 220;
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.error.withAlpha(alpha),
        shape: BoxShape.circle,
        border: outside ? null : Border.all(color: AppColors.error, width: 1),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.error.withAlpha(textAlpha),
            fontWeight: outside ? FontWeight.normal : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
