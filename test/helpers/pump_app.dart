import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jeevamitra/generated/l10n/app_localizations.dart';

/// Same delegate/locale list `JeevaMitraApp` wires in production — every
/// widget test that pumps a widget touching `AppLocalizations.of(context)`
/// needs this, or the lookup returns null and crashes.
const testLocalizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
const testSupportedLocales = [
  Locale('te', 'IN'),
  Locale('hi', 'IN'),
  Locale('en', 'IN'),
];

/// Pumps [child] inside a [ProviderScope] + minimal [MaterialApp] so widget
/// tests can exercise Riverpod-backed widgets without booting the full app
/// (and therefore without touching real Firebase plugin channels).
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        supportedLocales: testSupportedLocales,
        home: child,
      ),
    ),
  );
}

/// A bare (no Riverpod) localized [MaterialApp] wrapper for widget tests
/// that don't need a `ProviderScope` but do render localized text.
MaterialApp localizedTestApp(Widget home) => MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      supportedLocales: testSupportedLocales,
      home: home,
    );
