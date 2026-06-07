extension StringX on String {
  String get capitalize =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[\s\-+]'), '');
    return RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned);
  }

  bool get isValidName => trim().length >= 2 && RegExp(r'^[ఀ-౿ऀ-ॿa-zA-Z\s]+$').hasMatch(trim());

  String get toE164Phone {
    final cleaned = replaceAll(RegExp(r'[\s\-]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('0')) return '+91${cleaned.substring(1)}';
    return '+91$cleaned';
  }

  String get maskedPhone {
    if (length < 10) return this;
    return '${substring(0, 3)}****${substring(length - 3)}';
  }

  bool get isNullOrEmpty => trim().isEmpty;

  String truncate(int maxLength, {String suffix = '...'}) =>
      length <= maxLength ? this : '${substring(0, maxLength)}$suffix';

  String get toSnakeCase => replaceAllMapped(
    RegExp(r'([A-Z])'),
    (m) => '_${m.group(0)!.toLowerCase()}',
  ).replaceAll(RegExp(r'^_'), '');

  int? get toIntOrNull => int.tryParse(trim());
  double? get toDoubleOrNull => double.tryParse(trim());
}

extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;
  String get orEmpty => this ?? '';
}
