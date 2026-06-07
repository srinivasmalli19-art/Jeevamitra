class Formatters {
  static String currency(double amount, {String symbol = '₹'}) {
    if (amount >= 10000000) return '$symbol${(amount / 10000000).toStringAsFixed(1)}Cr';
    if (amount >= 100000) return '$symbol${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String area(double sqMeters, String unit) {
    switch (unit) {
      case 'acre': return '${(sqMeters / 4046.856).toStringAsFixed(2)} Acres';
      case 'hectare': return '${(sqMeters / 10000).toStringAsFixed(2)} Ha';
      case 'guntha': return '${(sqMeters / 101.17).toStringAsFixed(1)} Guntha';
      case 'cent': return '${(sqMeters / 40.47).toStringAsFixed(1)} Cents';
      default: return '${sqMeters.toStringAsFixed(0)} m²';
    }
  }

  static String distance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m';
    if (km < 10) return '${km.toStringAsFixed(1)}km';
    return '${km.toStringAsFixed(0)}km';
  }

  static String phone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.length == 10) {
      return '+91 ${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return raw;
  }

  static String duration(int days) {
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days == 7) return '1 week';
    if (days < 30) return '${(days / 7).floor()} weeks';
    if (days < 365) return '${(days / 30).floor()} months';
    return '${(days / 365).floor()} years';
  }

  static String flockSize(int count) {
    if (count == 1) return '1 animal';
    if (count < 10) return '$count animals';
    if (count < 100) return '$count animals';
    return '${(count / 10).round() * 10}+ animals';
  }
}
