import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/l10n/app_localizations.dart';

/// Canonical severity → (color, background, icon, label) mapping. Before
/// this existed, `farmer_explore_screen.dart` computed severity color and
/// severity icon via two independent `switch (severity)` statements in the
/// same file — both correct, but a second copy that had to be kept in sync
/// by hand. Every severity-aware widget in the Disease Alerts module now
/// routes through here instead.
class AlertSeverity {
  final Color color;
  final Color background;
  final IconData icon;
  final String label;

  const AlertSeverity._(this.color, this.background, this.icon, this.label);

  static const critical =
      AlertSeverity._(AppColors.error, AppColors.errorContainer, Icons.dangerous_rounded, 'Critical');
  static const high =
      AlertSeverity._(AppColors.warning, AppColors.warningContainer, Icons.warning_rounded, 'High');
  static const medium =
      AlertSeverity._(AppColors.info, AppColors.infoContainer, Icons.info_rounded, 'Medium');
  static const low = AlertSeverity._(
      AppColors.textSecondary, AppColors.surfaceVariant, Icons.info_outline_rounded, 'Low');

  static AlertSeverity of(String severity) => switch (severity) {
        'critical' => critical,
        'high' => high,
        'medium' => medium,
        _ => low,
      };

  /// Sort weight — critical first. Matches the ordering
  /// `DiseaseAlertRepository.watchNearby` already sorts by server-side.
  static int weight(String severity) => switch (severity) {
        'critical' => 0,
        'high' => 1,
        'medium' => 2,
        _ => 3,
      };
}

/// Localized severity label. [AlertSeverity.label] itself stays English —
/// it's a `const` field baked at compile time, so it can't carry a locale.
/// This is what every UI call site should use instead.
String severityLabel(String severity, AppLocalizations loc) => switch (severity) {
      'critical' => loc.severityCriticalLabel,
      'high' => loc.severityHighLabel,
      'medium' => loc.severityMediumLabel,
      _ => loc.severityLowLabel,
    };

/// Human-readable label for the affectedSpecies enum stored on an alert.
/// There is no reliable per-species Material icon (no sheep/goat/cattle
/// glyphs), so every species shares one generic icon rather than guessing
/// at a wrong one.
const IconData speciesIcon = Icons.pets_rounded;

String speciesLabel(String affectedSpecies, AppLocalizations loc) => switch (affectedSpecies) {
      'sheep' => loc.speciesSheepLabel,
      'goat' => loc.speciesGoatLabel,
      'cattle' => loc.speciesCattleLabel,
      _ => loc.speciesAllAnimalsLabel,
    };
