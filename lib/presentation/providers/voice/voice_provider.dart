import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/voice_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class VoiceState {
  final bool isInitialized;
  final bool isListening;
  final bool isSpeaking;
  final String transcript;
  final String? errorMessage;

  const VoiceState({
    this.isInitialized = false,
    this.isListening = false,
    this.isSpeaking = false,
    this.transcript = '',
    this.errorMessage,
  });

  VoiceState copyWith({
    bool? isInitialized,
    bool? isListening,
    bool? isSpeaking,
    String? transcript,
    String? errorMessage,
  }) =>
      VoiceState(
        isInitialized: isInitialized ?? this.isInitialized,
        isListening: isListening ?? this.isListening,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        transcript: transcript ?? this.transcript,
        errorMessage: errorMessage,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class VoiceNotifier extends StateNotifier<VoiceState> {
  VoiceNotifier() : super(const VoiceState());

  final _service = VoiceService();

  Future<bool> initialize() async {
    if (state.isInitialized) return true;
    final ok = await _service.initialize();
    state = state.copyWith(isInitialized: ok);
    return ok;
  }

  Future<void> startListening(String localeId) async {
    final ready = await initialize();
    if (!ready) {
      state = state.copyWith(
          errorMessage: 'Microphone not available. Check permissions.');
      return;
    }
    state = state.copyWith(
      isListening: true,
      transcript: '',
      errorMessage: null,
    );
    await _service.startListening(
      localeId: localeId,
      onResult: (text, isFinal) {
        state = state.copyWith(
          transcript: text,
          isListening: isFinal ? false : state.isListening,
        );
      },
    );
  }

  Future<void> stopListening() async {
    await _service.stopListening();
    state = state.copyWith(isListening: false);
  }

  Future<void> speak(String text, String localeId) async {
    state = state.copyWith(isSpeaking: true);
    await _service.speak(text, localeId: localeId);
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> stopSpeaking() async {
    await _service.stopSpeaking();
    state = state.copyWith(isSpeaking: false);
  }

  void clearTranscript() => state = state.copyWith(transcript: '');

  @override
  void dispose() {
    _service.stopListening();
    _service.stopSpeaking();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>(
  (_) => VoiceNotifier(),
);
