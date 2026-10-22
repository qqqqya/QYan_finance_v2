import 'dart:convert';

import '../core/money.dart';
import 'app_database.dart';

class LedgerWorkspace {
  const LedgerWorkspace(this.categories, this.bills, this.memos);
  final List<CategoryRow> categories;
  final List<BillRow> bills;
  final List<MemoRow> memos;
  CategoryRow? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<BillRow> month(String month, [String? type]) =>
      bills
          .where(
            (b) =>
                b.businessDate.startsWith(month) &&
                (type == null || b.type == type),
          )
          .toList()
        ..sort((a, b) {
          final time = '${b.businessDate} ${b.businessTime}'.compareTo(
            '${a.businessDate} ${a.businessTime}',
          );
          if (time != 0) return time;
          final created = b.createdAtMs.compareTo(a.createdAtMs);
          return created == 0 ? b.id.compareTo(a.id) : created;
        });
  int total(Iterable<BillRow> rows, String type) => checkedSumMinor(
    rows.where((b) => b.type == type).map((b) => b.amountMinor),
  );
  Map<String, int> distribution(String month, String type) {
    final groups = <String, List<int>>{};
    for (final b in this.month(month, type)) {
      (groups[b.categoryId] ??= []).add(b.amountMinor);
    }
    return {for (final e in groups.entries) e.key: checkedSumMinor(e.value)};
  }

  List<MemoRow> searchMemos(String keyword, String? tag) {
    final query = keyword.trim().toLowerCase();
    return memos.where((m) {
      final tags = memoTags(m);
      return (tag == null || tags.contains(tag)) &&
          (query.isEmpty ||
              '${m.title}\n${m.body}\n${tags.join(' ')}'.toLowerCase().contains(
                query,
              ));
    }).toList()..sort((a, b) {
      final date = b.businessDate.compareTo(a.businessDate);
      return date != 0 ? date : b.createdAtMs.compareTo(a.createdAtMs);
    });
  }
}

List<String> memoTags(MemoRow memo) =>
    (jsonDecode(memo.tagsJson) as List).cast<String>();
