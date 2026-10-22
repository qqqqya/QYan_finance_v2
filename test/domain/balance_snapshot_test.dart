import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/domain/balance_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

BalanceSnapshot snapshot(
  String id,
  int day,
  int minor,
  int order, {
  String project = 'bank',
}) => BalanceSnapshot(
  id: id,
  projectId: project,
  amountMinor: minor,
  moment: BusinessMoment(BusinessDate(2026, 10, day), '12:00'),
  orderKey: order,
);

void main() {
  test('balance snapshots replace, rather than accumulate', () {
    final records = [
      snapshot('later', 10, 120000, 2),
      snapshot('earlier', 1, 100000, 1),
    ];
    expect(currentBalanceMinor('bank', records), 120000);
    expect(snapshotChanges('bank', records), {
      'earlier': 100000,
      'later': 20000,
    });
  });

  test(
    'editing and deleting history recomputes current balance and deltas',
    () {
      final earlier = snapshot('earlier', 1, 90000, 1);
      final later = snapshot('later', 10, 120000, 2);
      expect(currentBalanceMinor('bank', [earlier, later]), 120000);
      expect(snapshotChanges('bank', [earlier, later])['later'], 30000);
      expect(currentBalanceMinor('bank', [earlier]), 90000);
      expect(currentBalanceMinor('bank', []), 0);
      expect(
        currentBalanceMinor('bank', [snapshot('moved', 11, 90000, 1), later]),
        90000,
      );
    },
  );

  test(
    'ties use preserved order, other projects and future moments do not leak',
    () {
      final records = [
        snapshot('a', 10, 100, 1),
        snapshot('b', 10, 200, 2),
        snapshot('other', 20, 900000, 1, project: 'cash'),
        snapshot('future', 30, 700, 3),
      ];
      final asOf = BusinessMoment(BusinessDate(2026, 10, 21), '18:00');
      expect(currentBalanceMinor('bank', records.reversed, asOf: asOf), 200);
      expect(currentBalanceMinor('cash', records, asOf: asOf), 900000);
      expect(
        () => orderedSnapshots('bank', [
          snapshot('a', 1, 0, 1),
          snapshot('b', 2, 0, 1),
        ]),
        throwsStateError,
      );
    },
  );
}
