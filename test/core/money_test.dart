import 'package:finance_app/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decimal parsing preserves cents without float rounding', () {
    expect(parseMoneyMinor('0.01'), 1);
    expect(parseMoneyMinor('12.3'), 1230);
    expect(parseMoneyMinor(' 0012.34 '), 1234);
    expect(parseMoneyMinor('9999999999.99'), maxRecordMinor);
    expect(
      checkedSumMinor([parseMoneyMinor('0.1'), parseMoneyMinor('0.2')]),
      30,
    );
  });

  test('invalid, zero-flow and out-of-range amounts are rejected', () {
    for (final input in [
      '',
      '-1',
      '+1',
      '1.001',
      '1.',
      '.1',
      '1e3',
      'NaN',
      '1,000',
      '10000000000',
      '9999999999999999999999999',
    ]) {
      expect(
        () => parseMoneyMinor(input),
        throwsFormatException,
        reason: input,
      );
    }
    expect(parseMoneyMinor('0'), 0);
    expect(
      () => parseMoneyMinor('0.00', allowZero: false),
      throwsFormatException,
    );
  });

  test('totals can exceed per-record limit but reject signed-64 overflow', () {
    expect(checkedSumMinor([maxRecordMinor, maxRecordMinor]), 1999999999998);
    expect(checkedSumMinor([100, -300]), -200);
    expect(() => checkedSumMinor([9223372036854775807, 1]), throwsRangeError);
    expect(() => checkedSumMinor([-9223372036854775808, -1]), throwsRangeError);
  });

  test('formatting keeps full precision and complete large values', () {
    expect(formatMoneyMinor(1), '0.01');
    expect(formatMoneyMinor(maxRecordMinor), '9,999,999,999.99');
    expect(formatMoneyMinor(-123456), '-1,234.56');
    expect(
      formatMoneyMinor(-9223372036854775808),
      '-92,233,720,368,547,758.08',
    );
  });
}
