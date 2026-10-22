import 'package:timezone/timezone.dart' as tz;

final class BusinessDate implements Comparable<BusinessDate> {
  BusinessDate(this.year, this.month, this.day) {
    if (year < 1900 || year > 9999) {
      throw const FormatException('Year is outside the supported range.');
    }
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw const FormatException('Invalid calendar date.');
    }
  }

  factory BusinessDate.parse(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Expected YYYY-MM-DD.');
    }
    final parts = value.split('-').map(int.parse).toList();
    return BusinessDate(parts[0], parts[1], parts[2]);
  }

  factory BusinessDate.inZone(DateTime instant, String zone) {
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
    return BusinessDate(local.year, local.month, local.day);
  }

  final int year;
  final int month;
  final int day;

  String get yearMonth =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  String toString() => '$yearMonth-${day.toString().padLeft(2, '0')}';

  @override
  int compareTo(BusinessDate other) => toString().compareTo(other.toString());

  @override
  bool operator ==(Object other) =>
      other is BusinessDate && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(year, month, day);
}

final class BusinessMoment implements Comparable<BusinessMoment> {
  BusinessMoment(this.date, this.time) {
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
      throw const FormatException('Expected HH:mm.');
    }
  }

  factory BusinessMoment.inZone(DateTime instant, String zone) {
    final local = tz.TZDateTime.from(instant.toUtc(), tz.getLocation(zone));
    return BusinessMoment(
      BusinessDate(local.year, local.month, local.day),
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
    );
  }

  final BusinessDate date;
  final String time;

  void requireNotFuture(BusinessMoment now) {
    if (compareTo(now) > 0) {
      throw const FormatException('Future business times are not allowed.');
    }
  }

  @override
  int compareTo(BusinessMoment other) {
    final dateOrder = date.compareTo(other.date);
    return dateOrder == 0 ? time.compareTo(other.time) : dateOrder;
  }
}

/// The selected month owns the default date, even when entering old records.
BusinessDate defaultEntryDate(int year, int month, BusinessDate today) {
  final first = BusinessDate(year, month, 1);
  if (first.yearMonth.compareTo(today.yearMonth) > 0) {
    throw const FormatException('Cannot enter a future month.');
  }
  final daysInMonth = DateTime.utc(year, month + 1, 0).day;
  return BusinessDate(
    year,
    month,
    today.day > daysInMonth ? daysInMonth : today.day,
  );
}
