import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/generated/l10n/app_localizations.dart';

/// Mounts a minimal MaterialApp with the same delegate/locale wiring as
/// JeevaMitraApp and returns the resolved AppLocalizations for [locale].
Future<AppLocalizations> _pumpLocale(
    WidgetTester tester, Locale locale) async {
  late AppLocalizations captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('te', 'IN'),
        Locale('hi', 'IN'),
        Locale('en', 'IN'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) {
          captured = AppLocalizations.of(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

void main() {
  testWidgets('AppLocalizations resolves for all three supported locales without throwing',
      (tester) async {
    for (final locale in const [Locale('en', 'IN'), Locale('te', 'IN'), Locale('hi', 'IN')]) {
      final loc = await _pumpLocale(tester, locale);
      expect(tester.takeException(), isNull);
      expect(loc.localeName, startsWith(locale.languageCode));
    }
  });

  testWidgets('key UI strings switch language when the locale changes', (tester) async {
    final en = await _pumpLocale(tester, const Locale('en', 'IN'));
    expect(en.sendOtp, 'Send OTP');
    expect(en.settings, 'Settings');

    final te = await _pumpLocale(tester, const Locale('te', 'IN'));
    expect(te.sendOtp, 'OTP పంపండి');
    expect(te.settings, 'సెట్టింగ్‌లు');

    final hi = await _pumpLocale(tester, const Locale('hi', 'IN'));
    expect(hi.sendOtp, 'OTP भेजें');
    expect(hi.settings, 'सेटिंग्स');

    expect(tester.takeException(), isNull);
  });

  testWidgets('placeholder substitution works for greetingName and otpSentTo',
      (tester) async {
    final en = await _pumpLocale(tester, const Locale('en', 'IN'));
    expect(en.greetingName('Ravi'), 'Hello, Ravi!');
    expect(en.otpSentTo('+919876543210'), 'OTP sent to +919876543210');
    expect(tester.takeException(), isNull);
  });

  testWidgets('pendingApprovalMsg pluralizes correctly for count=1 vs count=2',
      (tester) async {
    final en = await _pumpLocale(tester, const Locale('en', 'IN'));
    expect(en.pendingApprovalMsg(1), '1 booking awaiting your approval');
    expect(en.pendingApprovalMsg(3), '3 bookings awaiting your approval');

    final te = await _pumpLocale(tester, const Locale('te', 'IN'));
    expect(te.pendingApprovalMsg(1), contains('1'));
    expect(te.pendingApprovalMsg(3), contains('3'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('bookingSummaryMsg and tripEndsMsg interpolate all placeholders',
      (tester) async {
    final en = await _pumpLocale(tester, const Locale('en', 'IN'));
    expect(en.bookingSummaryMsg(5, 'Jan 1', '1,000'), '5 animals · Jan 1 · ₹1,000');
    expect(en.tripEndsMsg(5, 'Jan 1'), '5 animals · ends Jan 1');
    expect(tester.takeException(), isNull);
  });
}
