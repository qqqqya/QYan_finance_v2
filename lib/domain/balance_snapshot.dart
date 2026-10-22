import '../core/business_date.dart';
import '../core/money.dart';

final class BalanceSnapshot {
  BalanceSnapshot({
    required this.id,
    required this.projectId,
    required this.amountMinor,
    required this.moment,
    required this.orderKey,
  }) {
    if (amountMinor < 0 || amountMinor > maxRecordMinor || orderKey < 0) {
      throw RangeError('Invalid balance snapshot.');
    }
  }

  final String id;
  final String projectId;
  final int amountMinor;
  final BusinessMoment moment;
  final int orderKey;
}

int compareSnapshots(BalanceSnapshot a, BalanceSnapshot b) {
  final timeOrder = a.moment.compareTo(b.moment);
  return timeOrder == 0 ? a.orderKey.compareTo(b.orderKey) : timeOrder;
}

List<BalanceSnapshot> orderedSnapshots(
  String projectId,
  Iterable<BalanceSnapshot> source, {
  BusinessMoment? asOf,
}) {
  final records = source
      .where((record) => record.projectId == projectId)
      .toList();
  final seenOrderKeys = <int>{};
  for (final record in records) {
    if (!seenOrderKeys.add(record.orderKey)) {
      throw StateError('Snapshot orderKey must be unique within a project.');
    }
  }
  records.removeWhere(
    (record) => asOf != null && record.moment.compareTo(asOf) > 0,
  );
  records.sort(compareSnapshots);
  return records;
}

int currentBalanceMinor(
  String projectId,
  Iterable<BalanceSnapshot> source, {
  BusinessMoment? asOf,
}) {
  final records = orderedSnapshots(projectId, source, asOf: asOf);
  return records.isEmpty ? 0 : records.last.amountMinor;
}

Map<String, int> snapshotChanges(
  String projectId,
  Iterable<BalanceSnapshot> source,
) {
  var previous = 0;
  final changes = <String, int>{};
  for (final record in orderedSnapshots(projectId, source)) {
    changes[record.id] = record.amountMinor - previous;
    previous = record.amountMinor;
  }
  return changes;
}
