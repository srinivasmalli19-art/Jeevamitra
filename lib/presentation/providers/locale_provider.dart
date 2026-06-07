import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('te', 'IN')) {
    _load();
  }

  void _load() {
    final box = Hive.box(AppConstants.hiveBoxSettings);
    final lang = box.get(AppConstants.prefLanguage, defaultValue: 'te') as String;
    state = Locale(lang, _countryFor(lang));
  }

  Future<void> setLanguage(String langCode) async {
    final box = Hive.box(AppConstants.hiveBoxSettings);
    await box.put(AppConstants.prefLanguage, langCode);
    state = Locale(langCode, _countryFor(langCode));
  }

  String _countryFor(String lang) {
    switch (lang) {
      case 'te': return 'IN';
      case 'hi': return 'IN';
      default: return 'IN';
    }
  }

  bool get isTelugu => state.languageCode == 'te';
  bool get isHindi => state.languageCode == 'hi';
  bool get isEnglish => state.languageCode == 'en';
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (_) => LocaleNotifier(),
);
