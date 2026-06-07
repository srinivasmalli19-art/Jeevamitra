// DEPRECATED — Replaced by lib/presentation/providers/auth/auth_provider.dart
// Removed Provider + SharedPreferences dependency.
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool get isLoggedIn => false;
}
