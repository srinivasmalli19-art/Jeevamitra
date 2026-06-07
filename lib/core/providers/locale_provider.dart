// DEPRECATED — Replaced by Riverpod providers in lib/presentation/providers/
import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale get locale => const Locale('te', 'IN');
  bool get isTelugu => true;
  String t(String en, String te) => te;
}
