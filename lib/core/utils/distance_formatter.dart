import '../../generated/l10n/app_localizations.dart';

/// Formats a distance in kilometers as a short, human-readable label —
/// "850 m away" below 1km, "2.1 km away" above it. Never format or display
/// raw latitude/longitude to a user; this is the only distance text that
/// should reach the UI.
String formatDistanceAway(double km, AppLocalizations loc) {
  if (km < 1) {
    return loc.distanceMetersAway((km * 1000).round());
  }
  return loc.distanceKm(km.toStringAsFixed(1));
}
