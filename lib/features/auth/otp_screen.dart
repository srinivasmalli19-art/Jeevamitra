// DEPRECATED — Replaced by lib/presentation/screens/auth/otp_verification_screen.dart
import 'package:flutter/material.dart';

class OtpScreen extends StatelessWidget {
  final String phone;
  final String? redirectTo;
  const OtpScreen({required this.phone, this.redirectTo, super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
