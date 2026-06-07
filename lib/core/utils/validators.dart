class Validators {
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) return 'Enter valid 10-digit mobile number';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name too long';
    return null;
  }

  static String? village(String? value) {
    if (value == null || value.trim().isEmpty) return 'Village/town required';
    if (value.trim().length < 2) return 'Enter a valid location';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'OTP required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Enter 6-digit OTP';
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
