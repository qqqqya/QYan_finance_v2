import 'package:finance_app/core/business_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test(
    'strict dates reject normalization, malformed dates and invalid leap days',
    () {
      for (final value in [
        '2026-02-29',
        '2026-02-30',
        '2026-13-01',
        '2026-00-01',
        '2026-1-01',
        '1899-01-01',
      ]) {
        expect(
          () => BusinessDate.parse(value),
          throwsFormatException,
          reason: value,
        );
      }
      expect(BusinessDate.parse('2024-02-29').toString(), '2024-02-29');
    },
  );

  test(
    'selected month controls the default, including month ends and cross-year',
    () {
      final today = BusinessDate(2026, 10, 31);
      expect(defaultEntryDate(2026, 9, today).toString(), '2026-09-30');
      expect(defaultEntryDate(2024, 2, today).toString(), '2024-02-29');
      expect(defaultEntryDate(2025, 2, today).toString(), '2025-02-28');
      expect(defaultEntryDate(2025, 12, today).toString(), '2025-12-31');
      expect(defaultEntryDate(2026, 10, today), today);
      expect(() => defaultEntryDate(2026, 11, today), throwsFormatException);
    },
  );

  test(
    'book time zone determines the business day independently of device zone',
    () {
      final instant = DateTime.parse('2026-10-20T18:00:00Z');
      expect(
        BusinessDate.inZone(instant, 'Asia/Shanghai').toString(),
        '2026-10-21',
      );
      expect(
        BusinessDate.inZone(instant, 'America/Los_Angeles').toString(),
        '2026-10-20',
      );
    },
  );

  test('invalid times and future moments are rejected', () {
    final date = BusinessDate(2026, 10, 21);
    for (final value in ['24:00', '12:60', '9:00', '10:00:00']) {
      expect(() => BusinessMoment(date, value), throwsFormatException);
    }
    final now = BusinessMoment(date, '18:00');
    expect(
      () => BusinessMoment(date, '18:01').requireNotFuture(now),
      throwsFormatException,
    );
    BusinessMoment(date, '17:59').requireNotFuture(now);
    now.requireNotFuture(now);
  });

  test('Android GMT identifier can initialize a zero-balance book', () {
    // Android's default emulator time zone is a valid IANA compatibility name.
    // The reduced timezone database omits it and prevented first launch.
    final moment = BusinessMoment.inZone(
      DateTime.parse('2026-10-21T18:25:00Z'),
      'GMT',
    );
    expect(moment.date.toString(), '2026-10-21');
    expect(moment.time, '18:25');
  });
}
