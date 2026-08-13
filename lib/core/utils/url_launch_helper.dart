import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';

/// Single canonical "open an external URL, tell the user if it fails"
/// primitive for the Explore ecosystem. Before this existed, every card
/// and detail screen that called `canLaunchUrl`/`launchUrl` handled the
/// failure case differently — some (`VetDetailScreen._call`,
/// `_whatsapp`) showed a SnackBar, others (`NearbyLandCard._navigate`,
/// `PremiumVetCard._navigate`/`_book`, `AlertDetailScreen._navigate`)
/// silently did nothing, so tapping "Navigate" with no maps app installed
/// looked identical to a working tap. Every external-URL call site in
/// this ecosystem now routes through here for one consistent behavior.
Future<bool> launchExternalUrl(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
  required String failureMessage,
}) async {
  final canLaunch = await canLaunchUrl(uri);
  if (canLaunch) {
    final launched = await launchUrl(uri, mode: mode);
    if (launched) return true;
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failureMessage), backgroundColor: AppColors.error),
    );
  }
  return false;
}

Uri telUri(String phone) => Uri.parse('tel:$phone');

Uri whatsappUri(String phone, {String? text}) {
  final number = phone.replaceAll(RegExp(r'\D'), '');
  return Uri.parse(
      'https://wa.me/91$number${text != null ? '?text=${Uri.encodeComponent(text)}' : ''}');
}

Uri mapsSearchUri(double lat, double lng) =>
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
