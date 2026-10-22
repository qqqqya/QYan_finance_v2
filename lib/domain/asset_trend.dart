import '../core/business_date.dart';
import '../core/money.dart';
import 'balance_snapshot.dart';

final class TrendPoint {
  const TrendPoint(this.moment, this.amountMinor);
  final BusinessMoment moment;
  final int amountMinor;
}

/// A step-held balance; no synthetic zeros before the first known snapshot.
List<TrendPoint> buildBalanceTrend(
  Set<String> projectIds,
  Iterable<BalanceSnapshot> snapshots, {
  required BusinessMoment start,
  required BusinessMoment end,
}) {
  final records =
      snapshots
          .where(
            (r) =>
                projectIds.contains(r.projectId) &&
                r.moment.compareTo(end) <= 0,
          )
          .toList()
        ..sort((a, b) {
          final time = a.moment.compareTo(b.moment);
          if (time != 0) return time;
          final project = a.projectId.compareTo(b.projectId);
          return project != 0 ? project : a.orderKey.compareTo(b.orderKey);
        });
  if (records.isEmpty || start.compareTo(end) > 0) return [];
  final balances = <String, int>{};
  final points = <TrendPoint>[];
  var hasPrior = false;
  for (var i = 0; i < records.length;) {
    final moment = records[i].moment;
    final previousTotal = checkedSumMinor(balances.values);
    while (i < records.length && records[i].moment.compareTo(moment) == 0) {
      balances[records[i].projectId] = records[i].amountMinor;
      i++;
    }
    if (moment.compareTo(start) < 0) {
      hasPrior = true;
      continue;
    }
    if (points.isEmpty && hasPrior && moment.compareTo(start) > 0) {
      points.add(TrendPoint(start, previousTotal));
    }
    points.add(TrendPoint(moment, checkedSumMinor(balances.values)));
  }
  if (points.isEmpty && hasPrior) {
    points.add(TrendPoint(start, checkedSumMinor(balances.values)));
  }
  if (points.isNotEmpty && points.last.moment.compareTo(end) < 0) {
    points.add(TrendPoint(end, points.last.amountMinor));
  }
  return points;
}
