import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

/// Platform-aware logging for the phone-OTP authentication flow.
///
/// Uses `[OTP_FLOW_IOS]` on iOS (per the iOS-first audit), `[OTP_FLOW]`
/// elsewhere (Android/desktop), and `[OTP_FLOW_WEB]` on web — the same
/// underlying call sites from the Android audit now report correctly no
/// matter which platform actually runs them. `debugPrint` is not stripped
/// in release builds, so these are visible via Xcode's Console while
/// running on a real iPhone (or `adb logcat` / `flutter logs` elsewhere)
/// regardless of build mode.
String get otpFlowTag {
  if (kIsWeb) return '[OTP_FLOW_WEB]';
  if (Platform.isIOS) return '[OTP_FLOW_IOS]';
  return '[OTP_FLOW]';
}

void otpFlowLog(String message) => debugPrint('$otpFlowTag $message');
