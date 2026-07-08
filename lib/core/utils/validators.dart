import '../../generated/l10n/app_localizations.dart';

/// Every method takes an optional [AppLocalizations] as a trailing parameter,
/// falling back to the original English copy when it's omitted — this keeps
/// every existing call site (which passes no localizations) working exactly
/// as before, while screens that do have one in scope get translated
/// messages. Only the validators actually used by in-scope screens for this
/// localization batch (phone, name, village, otp) were extended; `price`,
/// `area`, `sheepCount`, and `required` are unchanged.
class Validators {
  static String? phone(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.phoneRequiredMsg ?? 'Phone number required';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
      return loc?.phoneInvalidMsg ?? 'Enter valid 10-digit mobile number';
    }
    return null;
  }

  static String? name(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.nameRequiredMsg ?? 'Name required';
    }
    if (value.trim().length < 2) {
      return loc?.nameTooShortMsg ?? 'Name must be at least 2 characters';
    }
    if (value.trim().length > 50) return loc?.nameTooLongMsg ?? 'Name too long';
    return null;
  }

  static String? village(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.villageRequiredMsg ?? 'Village/town required';
    }
    if (value.trim().length < 2) return loc?.villageInvalidMsg ?? 'Enter a valid location';
    return null;
  }

  static String? otp(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) return loc?.otpRequiredMsg ?? 'OTP required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return loc?.otpInvalidMsg ?? 'Enter 6-digit OTP';
    }
    return null;
  }

  /// District field on Profile Setup — kept separate from the generic
  /// [required] helper below (which takes an arbitrary field name used by
  /// several out-of-scope screens) to avoid touching those call sites.
  static String? district(String? value, [AppLocalizations? loc]) {
    if (value == null || value.trim().isEmpty) {
      return loc?.districtRequiredMsg ?? 'District required';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter valid price';
    return null;
  }

  static String? area(String? value) {
    if (value == null || value.trim().isEmpty) return 'Area required';
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter valid area';
    return null;
  }

  static String? required(String? value, [String field = 'Field']) {
    if (value == null || value.trim().isEmpty) return '$field required';
    return null;
  }

  static String? sheepCount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Flock size required';
    final n = int.tryParse(value.trim());
    if (n == null || n <= 0) return 'Enter valid count';
    if (n > 10000) return 'Count seems too high';
    return null;
  }
}
