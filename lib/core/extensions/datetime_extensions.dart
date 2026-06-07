extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  bool get isFuture => isAfter(DateTime.now());
  bool get isPast => isBefore(DateTime.now());

  String get relativeLabel {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    final diff = DateTime.now().difference(this);
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String get ddMmmYyyy {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${day.toString().padLeft(2,'0')} ${months[month - 1]} $year';
  }

  String get hhmm {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String get ddMmmYyyyHhmm => '$ddMmmYyyy, $hhmm';

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  int get daysUntil => startOfDay.difference(DateTime.now().startOfDay).inDays;
}

extension NullableDateTimeX on DateTime? {
  String get orNa => this == null ? 'N/A' : this!.ddMmmYyyy;
}
