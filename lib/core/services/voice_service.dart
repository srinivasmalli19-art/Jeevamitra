import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService _instance = VoiceService._();
  factory VoiceService() => _instance;
  VoiceService._();

  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();
  bool _initialized = false;

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onStatus: (s) => debugPrint('[Voice] status: $s'),
        onError: (e) => debugPrint('[Voice] error: $e'),
      );
      if (_initialized) {
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(0.45);
      }
      return _initialized;
    } catch (e) {
      debugPrint('[Voice] init failed: $e');
      return false;
    }
  }

  Future<void> startListening({
    required String localeId,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_initialized) return;
    await _speech.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      localeId: localeId,
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
    );
  }

  Future<void> stopListening() => _speech.stop();

  Future<void> speak(String text, {String localeId = 'te-IN'}) async {
    try {
      await _tts.setLanguage(localeId);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[Voice] TTS error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;
}
