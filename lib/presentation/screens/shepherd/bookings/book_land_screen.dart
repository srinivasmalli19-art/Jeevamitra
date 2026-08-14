import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/repositories/booking_repository.dart';
import '../../../../data/repositories/farm_availability_repository.dart';
import '../../../providers/auth/auth_provider.dart';
import '../../../providers/booking/booking_providers.dart';
import '../../../providers/farm/farm_availability_providers.dart';
import '../../../providers/farm/farm_providers.dart';
import '../../../widgets/common/jm_button.dart';
import '../../../widgets/common/jm_loading.dart';

class BookLandScreen extends ConsumerStatefulWidget {
  final String farmId;
  const BookLandScreen({super.key, required this.farmId});

  @override
  ConsumerState<BookLandScreen> createState() => _BookLandScreenState();
}

class _BookLandScreenState extends ConsumerState<BookLandScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _animalCount = 10;
  final _notesCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int get _days =>
      (_checkOut != null && _checkIn != null)
          ? _checkOut!.difference(_checkIn!).inDays
          : 0;

  double _total(double pricePerDayPerAnimal) =>
      _days * _animalCount * pricePerDayPerAnimal;

  void _nextStep() {
    if (_step == 0) {
      if (_checkIn == null || _checkOut == null) {
        _snack('Please select check-in and check-out dates');
        return;
      }
      if (_days < 1) {
        _snack('Check-out must be after check-in');
        return;
      }
      final periods = ref
              .read(farmBlockedPeriodsProvider(widget.farmId))
              .valueOrNull ??
          [];
      if (FarmAvailabilityRepository.hasConflict(
          periods, _checkIn!, _checkOut!.add(const Duration(days: 1)))) {
        _snack(
            'Selected dates include unavailable periods. Please choose different dates.');
        return;
      }
    }
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.animateToPage(_step,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      context.pop();
    }
  }

  Future<void> _submit(BookingModel template) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userDoc = ref.read(currentUserDocProvider).valueOrNull;

    final booking = BookingModel(
      id: '',
      farmId: template.farmId,
      farmTitle: template.farmTitle,
      farmVillage: template.farmVillage,
      farmerId: template.farmerId,
      shepherdId: uid,
      shepherdName: userDoc?.name ?? '',
      animalCount: _animalCount,
      checkIn: _checkIn!,
      checkOut: _checkOut!,
      totalAmount: _total(template.totalAmount),
      advanceAmount: 0,
      status: 'pending',
      createdAt: DateTime.now(),
      shepherdPhone: userDoc?.phone,
    );

    final id = await ref.read(bookingNotifierProvider.notifier).createBooking(booking);
    setState(() => _submitting = false);

    if (!mounted) return;
    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request sent! Waiting for farmer approval.')),
      );
      context.go(RouteConstants.shepherdBookings);
    } else {
      final error = ref.read(bookingNotifierProvider).error;
      _snack(error is BookingConflictException
          ? error.message
          : 'Failed to submit booking. Please try again.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final farmAsync = ref.watch(farmDetailProvider(widget.farmId));

    return farmAsync.when(
      loading: () => const Scaffold(body: Center(child: JmLoading())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Book Land')),
        body: Center(child: Text(e.toString())),
      ),
      data: (farm) {
        if (farm == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book Land')),
            body: const Center(child: Text('Land not found')),
          );
        }
        final blockedPeriods =
            ref.watch(farmBlockedPeriodsProvider(widget.farmId)).valueOrNull ??
                [];

        return Scaffold(
          appBar: AppBar(
            title: Text('Book: ${farm.title}'),
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prevStep),
          ),
          body: Column(
            children: [
              _StepBar(current: _step),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1Dates(
                      checkIn: _checkIn,
                      checkOut: _checkOut,
                      onCheckInPick: () => _pickDate(isCheckIn: true),
                      onCheckOutPick: () => _pickDate(isCheckIn: false),
                      days: _days,
                      blockedCount: blockedPeriods.length,
                    ),
                    _Step2Herd(
                      animalCount: _animalCount,
                      notesCtrl: _notesCtrl,
                      onCountChanged: (v) => setState(() => _animalCount = v),
                      maxAnimals: farm.maxAnimals,
                    ),
                    _Step3Confirm(
                      farmTitle: farm.title,
                      farmVillage: farm.village,
                      checkIn: _checkIn,
                      checkOut: _checkOut,
                      animalCount: _animalCount,
                      days: _days,
                      pricePerDayPerAnimal: farm.pricePerDayPerAnimal,
                      total: _total(farm.pricePerDayPerAnimal),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: AppSpacing.screenPadding.copyWith(top: AppSpacing.md),
                child: _step < 2
                    ? JmButton(label: 'Next →', onPressed: _nextStep)
                    : JmButton(
                        label: 'Send Booking Request',
                        isLoading: _submitting,
                        leadingIcon: Icons.send_rounded,
                        onPressed: _submitting
                            ? null
                            : () => _submit(BookingModel(
                                  id: '',
                                  farmId: farm.id,
                                  farmTitle: farm.title,
                                  farmVillage: farm.village,
                                  farmerId: farm.ownerId,
                                  shepherdId: '',
                                  shepherdName: '',
                                  animalCount: _animalCount,
                                  checkIn: _checkIn ?? DateTime.now(),
                                  checkOut: _checkOut ?? DateTime.now(),
                                  totalAmount: farm.pricePerDayPerAnimal,
                                  advanceAmount: 0,
                                  status: 'pending',
                                  createdAt: DateTime.now(),
                                )),
                      ),
              ),
              const SizedBox(height: AppSpacing.base),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate({required bool isCheckIn}) async {
    final now = DateTime.now();
    final first =
        isCheckIn ? now : (_checkIn ?? now).add(const Duration(days: 1));
    final periods =
        ref.read(farmBlockedPeriodsProvider(widget.farmId)).valueOrNull ?? [];
    final picked = await showDatePicker(
      context: context,
      initialDate: first,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365)),
      helpText: isCheckIn ? 'Select Check-in Date' : 'Select Check-out Date',
      selectableDayPredicate: periods.isEmpty
          ? null
          : (date) => !periods.any((p) => p.containsDate(date)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut != null && !_checkOut!.isAfter(picked)) _checkOut = null;
      } else {
        _checkOut = picked;
      }
    });
  }
}

// ─── Step bar ─────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current;
  const _StepBar({required this.current});

  static const _labels = ['Dates', 'Herd Info', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      color: AppColors.surface,
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.success
                        : active
                            ? AppColors.secondary
                            : AppColors.outline,
                  ),
                  child: Center(
                    child: done
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : Text('${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : AppColors.textDisabled,
                            )),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(_labels[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                if (i < _labels.length - 1) ...[
                  const SizedBox(width: 4),
                  const Expanded(child: Divider(thickness: 1)),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Step 1: Dates ────────────────────────────────────────────────────────────

class _Step1Dates extends StatelessWidget {
  final DateTime? checkIn, checkOut;
  final VoidCallback onCheckInPick, onCheckOutPick;
  final int days;
  final int blockedCount;

  const _Step1Dates({
    required this.checkIn,
    required this.checkOut,
    required this.onCheckInPick,
    required this.onCheckOutPick,
    required this.days,
    required this.blockedCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          Text('Select Grazing Dates',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Choose when you want to bring your herd',
              style: Theme.of(context).textTheme.bodySmall),
          if (blockedCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningContainer,
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_busy_rounded,
                      size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Some dates are unavailable. Greyed-out days in the picker are blocked by the farmer.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          _DateTile(
            icon: Icons.login_rounded,
            label: 'Check-in Date',
            date: checkIn,
            onTap: onCheckInPick,
            placeholder: 'Tap to select',
          ),
          const SizedBox(height: AppSpacing.md),
          _DateTile(
            icon: Icons.logout_rounded,
            label: 'Check-out Date',
            date: checkOut,
            onTap: onCheckOutPick,
            placeholder: checkIn == null ? 'Select check-in first' : 'Tap to select',
          ),
          if (days > 0) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: AppSpacing.cardRadius,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text('$days ${days == 1 ? 'day' : 'days'} selected',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String placeholder;

  const _DateTile({
    required this.icon, required this.label,
    required this.date, required this.onTap, required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          border: Border.all(
              color: date != null ? AppColors.primary : AppColors.outline),
          borderRadius: AppSpacing.cardRadius,
          color: date != null ? AppColors.primaryContainer : AppColors.surface,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: date != null ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                Text(
                  date != null
                      ? '${date!.day} ${_monthName(date!.month)} ${date!.year}'
                      : placeholder,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: date != null
                          ? AppColors.primary
                          : AppColors.textDisabled),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];
}

// ─── Step 2: Herd info ────────────────────────────────────────────────────────

class _Step2Herd extends StatelessWidget {
  final int animalCount;
  final TextEditingController notesCtrl;
  final ValueChanged<int> onCountChanged;
  final int maxAnimals;

  const _Step2Herd({
    required this.animalCount, required this.notesCtrl,
    required this.onCountChanged, required this.maxAnimals,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          Text('Herd Information',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Land capacity: $maxAnimals animals max',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          // Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                onPressed:
                    animalCount > 1 ? () => onCountChanged(animalCount - 1) : null,
                icon: const Icon(Icons.remove_rounded),
                iconSize: 28,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    Text('$animalCount',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w700)),
                    Text('Animals',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: animalCount < maxAnimals
                    ? () => onCountChanged(animalCount + 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
                iconSize: 28,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text('Adjust in steps of 10:',
                style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [10, 25, 50, 100].map((v) {
              if (v > maxAnimals) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  label: Text('$v'),
                  onPressed: () => onCountChanged(v),
                  backgroundColor: animalCount == v
                      ? AppColors.primaryContainer
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Notes
          TextField(
            controller: notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes for farmer (optional)',
              hintText: 'e.g. arriving by evening, need water access...',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
        ],
      ),
    );
  }
}

// ─── Step 3: Confirm ──────────────────────────────────────────────────────────

class _Step3Confirm extends StatelessWidget {
  final String farmTitle, farmVillage;
  final DateTime? checkIn, checkOut;
  final int animalCount, days;
  final double pricePerDayPerAnimal, total;

  const _Step3Confirm({
    required this.farmTitle, required this.farmVillage,
    required this.checkIn, required this.checkOut,
    required this.animalCount, required this.days,
    required this.pricePerDayPerAnimal, required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.base),
          Text('Booking Summary',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xl),
          // Summary card
          Card(
            elevation: 0,
            color: AppColors.surfaceVariant,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                children: [
                  _SummaryRow('Land', farmTitle),
                  _SummaryRow('Location', farmVillage),
                  const Divider(),
                  _SummaryRow(
                    'Check-in',
                    checkIn != null ? _fmt(checkIn!) : '-',
                  ),
                  _SummaryRow(
                    'Check-out',
                    checkOut != null ? _fmt(checkOut!) : '-',
                  ),
                  _SummaryRow('Duration', '$days days'),
                  const Divider(),
                  _SummaryRow('Animals', '$animalCount'),
                  _SummaryRow(
                    'Rate',
                    '₹${pricePerDayPerAnimal.toStringAsFixed(0)} / day / animal',
                  ),
                  const Divider(),
                  _SummaryRow(
                    'Total Estimate',
                    '₹${total.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: AppSpacing.cardRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'This is a booking request. The farmer will confirm or reject within 24 hours.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day} ${const ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month]} ${d.year}';
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _SummaryRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Text(
            value,
            style: highlight
                ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)
                : Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
