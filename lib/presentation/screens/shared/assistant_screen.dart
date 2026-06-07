import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../providers/auth/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/voice/voice_provider.dart';
import '../../widgets/common/jm_voice_button.dart';

// ── Command intents ────────────────────────────────────────────────────────────

enum _Intent {
  bookings,
  lands,
  discover,
  vets,
  emergency,
  addLand,
  explore,
  profile,
  notifications,
  unknown,
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  String _response = '';
  bool _navigating = false;

  @override
  void dispose() {
    ref.read(voiceProvider.notifier).stopListening();
    ref.read(voiceProvider.notifier).stopSpeaking();
    super.dispose();
  }

  String get _localeId {
    final lang = ref.read(localeProvider).languageCode;
    return switch (lang) {
      'te' => 'te_IN',
      'hi' => 'hi_IN',
      _ => 'en_IN',
    };
  }

  String get _ttsLocale {
    final lang = ref.read(localeProvider).languageCode;
    return switch (lang) {
      'te' => 'te-IN',
      'hi' => 'hi-IN',
      _ => 'en-IN',
    };
  }

  Future<void> _toggleListening() async {
    final voice = ref.read(voiceProvider);
    if (voice.isListening) {
      await ref.read(voiceProvider.notifier).stopListening();
    } else {
      setState(() => _response = '');
      await ref.read(voiceProvider.notifier).startListening(_localeId);

      // Wait for final transcript then process
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;

      final transcript = ref.read(voiceProvider).transcript;
      if (transcript.isNotEmpty) {
        _processCommand(transcript);
      }
    }
  }

  void _processCommand(String text) {
    final intent = _parseIntent(text);
    final (response, action) = _responseFor(intent);

    setState(() => _response = response);
    ref.read(voiceProvider.notifier).speak(response, _ttsLocale);

    if (action != null && !_navigating) {
      _navigating = true;
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        _navigating = false;
        action();
      });
    }
  }

  _Intent _parseIntent(String text) {
    final t = text.toLowerCase();
    if (_matches(t, ['booking', 'bookings', 'బుకింగ్', 'my trips', 'trips', 'బుకింగులు'])) {
      return _Intent.bookings;
    }
    if (_matches(t, ['add land', 'new land', 'create land', 'list land', 'భూమి జోడించు', 'పొలం జోడించు'])) {
      return _Intent.addLand;
    }
    if (_matches(t, ['find land', 'discover', 'search land', 'nearby land', 'మేత భూమి'])) {
      return _Intent.discover;
    }
    if (_matches(t, ['my land', 'my lands', 'నా భూమి', 'నా పొలం', 'lands'])) {
      return _Intent.lands;
    }
    if (_matches(t, ['vet', 'vets', 'doctor', 'పశువైద్య', 'డాక్టర్', 'veterinary'])) {
      return _Intent.vets;
    }
    if (_matches(t, ['emergency', 'అత్యవసర', 'help', 'danger', 'urgent', '1962'])) {
      return _Intent.emergency;
    }
    if (_matches(t, ['alert', 'disease', 'explore', 'వ్యాధి', 'హెచ్చరిక', 'advisory'])) {
      return _Intent.explore;
    }
    if (_matches(t, ['profile', 'account', 'settings', 'ప్రొఫైల్'])) {
      return _Intent.profile;
    }
    if (_matches(t, ['notification', 'notifications', 'నోటిఫికేషన్'])) {
      return _Intent.notifications;
    }
    return _Intent.unknown;
  }

  bool _matches(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  (String, VoidCallback?) _responseFor(_Intent intent) {
    final doc = ref.read(currentUserDocProvider).valueOrNull;
    final isFarmer = doc?.isFarmer ?? true;

    return switch (intent) {
      _Intent.bookings => (
          isFarmer
              ? 'మీ బుకింగులు తెరుస్తున్నాను. Opening your bookings.'
              : 'మీ ట్రిప్పులు తెరుస్తున్నాను. Opening your trips.',
          () => context.go(isFarmer ? RouteConstants.farmerBookings : RouteConstants.shepherdBookings),
        ),
      _Intent.lands => (
          'మీ భూముల జాబితా తెరుస్తున్నాను. Opening your lands.',
          () => context.go(RouteConstants.farmerLands),
        ),
      _Intent.discover => (
          'దగ్గర్లో మేత భూమి వెతుకుతున్నాను. Finding nearby grazing land.',
          () => context.go(RouteConstants.shepherdDiscover),
        ),
      _Intent.addLand => (
          'భూమి చేర్చే పేజీ తెరుస్తున్నాను. Opening add land form.',
          () => context.push(RouteConstants.farmerAddLand),
        ),
      _Intent.vets => (
          'దగ్గర్లో పశువైద్యులు వెతుకుతున్నాను. Finding vets nearby.',
          () => context.go(RouteConstants.shepherdVets),
        ),
      _Intent.emergency => (
          'అత్యవసర సహాయం తెరుస్తున్నాను. Opening emergency help.',
          () => context.push(RouteConstants.emergency),
        ),
      _Intent.explore => (
          'వ్యాధి హెచ్చరికలు తెరుస్తున్నాను. Opening disease alerts.',
          () => context.go(isFarmer ? RouteConstants.farmerExplore : RouteConstants.farmerExplore),
        ),
      _Intent.profile => (
          'మీ ప్రొఫైల్ తెరుస్తున్నాను. Opening your profile.',
          () => context.go(isFarmer ? RouteConstants.farmerProfile : RouteConstants.shepherdProfile),
        ),
      _Intent.notifications => (
          'నోటిఫికేషన్లు తెరుస్తున్నాను. Opening notifications.',
          () => context.push(RouteConstants.notifications),
        ),
      _Intent.unknown => (
          'అర్థం కాలేదు. Try: "my bookings", "find vet", "add land", or "emergency".',
          null,
        ),
    };
  }

  void _runQuickCommand(_Intent intent) {
    final (response, action) = _responseFor(intent);
    setState(() => _response = response);
    ref.read(voiceProvider.notifier).speak(response, _ttsLocale);
    if (action != null && !_navigating) {
      _navigating = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        _navigating = false;
        action();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final voice = ref.watch(voiceProvider);
    final doc = ref.watch(currentUserDocProvider).valueOrNull;
    final isFarmer = doc?.isFarmer ?? true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _LangChips(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Main mic area ──────────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StateIcon(voice: voice),
                  const SizedBox(height: AppSpacing.xl),
                  _StateLabel(voice: voice),
                  const SizedBox(height: AppSpacing.xxl),
                  JmVoiceButton(
                    onTap: _toggleListening,
                    isListening: voice.isListening,
                    size: 80,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (voice.transcript.isNotEmpty)
                    _TranscriptBubble(text: voice.transcript),
                  if (_response.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _ResponseBubble(text: _response),
                  ],
                  if (voice.errorMessage != null)
                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Text(
                        voice.errorMessage!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            // ── Quick commands ─────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick commands',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (isFarmer) ...[
                        _QuickChip(
                          icon: Icons.calendar_month_rounded,
                          label: 'My Bookings',
                          onTap: () => _runQuickCommand(_Intent.bookings),
                        ),
                        _QuickChip(
                          icon: Icons.landscape_rounded,
                          label: 'My Lands',
                          onTap: () => _runQuickCommand(_Intent.lands),
                        ),
                        _QuickChip(
                          icon: Icons.add_location_alt_rounded,
                          label: 'Add Land',
                          onTap: () => _runQuickCommand(_Intent.addLand),
                        ),
                        _QuickChip(
                          icon: Icons.coronavirus_rounded,
                          label: 'Disease Alerts',
                          onTap: () => _runQuickCommand(_Intent.explore),
                        ),
                      ] else ...[
                        _QuickChip(
                          icon: Icons.search_rounded,
                          label: 'Find Land',
                          onTap: () => _runQuickCommand(_Intent.discover),
                        ),
                        _QuickChip(
                          icon: Icons.calendar_month_rounded,
                          label: 'My Trips',
                          onTap: () => _runQuickCommand(_Intent.bookings),
                        ),
                        _QuickChip(
                          icon: Icons.medical_services_rounded,
                          label: 'Find Vet',
                          onTap: () => _runQuickCommand(_Intent.vets),
                        ),
                      ],
                      _QuickChip(
                        icon: Icons.emergency_rounded,
                        label: 'Emergency',
                        color: AppColors.error,
                        onTap: () => _runQuickCommand(_Intent.emergency),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StateIcon extends StatelessWidget {
  final VoiceState voice;
  const _StateIcon({required this.voice});

  @override
  Widget build(BuildContext context) {
    if (voice.isListening) {
      return const Icon(Icons.graphic_eq_rounded,
          size: 56, color: AppColors.primary);
    }
    if (voice.isSpeaking) {
      return const Icon(Icons.volume_up_rounded,
          size: 56, color: AppColors.secondary);
    }
    return const Icon(Icons.mic_none_rounded,
        size: 56, color: AppColors.textDisabled);
  }
}

class _StateLabel extends StatelessWidget {
  final VoiceState voice;
  const _StateLabel({required this.voice});

  @override
  Widget build(BuildContext context) {
    final label = voice.isListening
        ? 'వింటున్నాను…  Listening…'
        : voice.isSpeaking
            ? 'చెప్తున్నాను…  Speaking…'
            : 'మాట్లాడండి  Tap to speak';

    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: voice.isListening
                ? AppColors.primary
                : voice.isSpeaking
                    ? AppColors.secondary
                    : AppColors.textSecondary,
          ),
      textAlign: TextAlign.center,
    );
  }
}

class _TranscriptBubble extends StatelessWidget {
  final String text;
  const _TranscriptBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Row(
        children: [
          const Icon(Icons.person_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponseBubble extends StatelessWidget {
  final String text;
  const _ResponseBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.smart_toy_rounded,
              size: 16, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(60)),
      labelStyle: TextStyle(fontSize: 12, color: color),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _LangChips extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider).languageCode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (code, label) in [('te', 'తె'), ('hi', 'हि'), ('en', 'En')])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => ref.read(localeProvider.notifier).setLanguage(code),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: lang == code
                      ? AppColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color:
                        lang == code ? AppColors.primary : AppColors.outline,
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: lang == code
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
