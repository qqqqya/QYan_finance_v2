import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/domain/asset_trend.dart';
import 'package:finance_app/domain/balance_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessMoment at(String date) =>
    BusinessMoment(BusinessDate.parse(date), '12:00');
BalanceSnapshot snapshot(
  String id,
  String project,
  int cents,
  String date,
  int order,
) => BalanceSnapshot(
  id: id,
  projectId: project,
  amountMinor: cents,
  moment: at(date),
  orderKey: order,
);
void main() {
  test('T10 no invented leading zero; a single point is held to the end', () {
    final result = buildBalanceTrend(
      {'A'},
      [snapshot('one', 'A', 10000, '2026-10-10', 0)],
      start: at('2026-10-01'),
      end: at('2026-10-22'),
    );
    expect(result.map((p) => p.moment.date.toString()), [
      '2026-10-10',
      '2026-10-22',
    ]);
    expect(result.map((p) => p.amountMinor), [10000, 10000]);
    expect(
      buildBalanceTrend(
        {'A'},
        [],
        start: at('2026-10-01'),
        end: at('2026-10-22'),
      ),
      isEmpty,
    );
  });
  test('T10 carry prior balance; same-time events, exclusions and deleted rows recompute', () {
    final records = [
      snapshot('a', 'A', 10000, '2026-09-15', 0),
      snapshot('b', 'A', 12000, '2026-10-10', 1),
      snapshot('c', 'A', 12500, '2026-10-10', 2),
      snapshot('d', 'B', 5000, '2026-10-10', 0),
    ];
    final result = buildBalanceTrend(
      {'A', 'B'},
      records,
      start: at('2026-10-01'),
      end: at('2026-10-22'),
    );
    expect(result.map((p) => p.amountMinor), [10000, 17500, 17500]);
    final excluded = buildBalanceTrend(
      {'A'},
      records.where((r) => r.id != 'c'),
      start: at('2026-10-01'),
      end: at('2026-10-22'),
    );
    expect(excluded.map((p) => p.amountMinor), [10000, 12000, 12000]);
    final onlyPrior = buildBalanceTrend(
      {'A'},
      [records.first],
      start: at('2026-10-01'),
      end: at('2026-10-22'),
    );
    expect(onlyPrior.map((p) => p.amountMinor), [10000, 10000]);
  });
}
