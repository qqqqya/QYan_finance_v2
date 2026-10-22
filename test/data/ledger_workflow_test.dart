import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/ledger_workspace.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

BusinessMoment at(String date) =>
    BusinessMoment(BusinessDate.parse(date), '12:00');
void main() {
  setUpAll(tz.initializeTimeZones);
  group('ledger and memos', () {
    late AppDatabase db;
    late FinanceRepository repo;
    var clock = DateTime.utc(2026, 10, 31, 14);
    setUp(() async {
      clock = DateTime.utc(2026, 10, 31, 14);
      db = AppDatabase(NativeDatabase.memory());
      repo = FinanceRepository(db, clock: () => clock);
      await repo.initialize('GMT');
    });
    tearDown(() => db.close());
    Future<LedgerWorkspace> ledger() => repo.watchLedger().first;
    Future<String> category(String type) async =>
        (await ledger()).categories.firstWhere((c) => c.type == type).id;
    Future<String> bill(
      int amount, {
      String date = '2026-09-30',
      String type = 'expense',
      String? id,
      String? categoryId,
      String note = '',
    }) async => repo.saveBill(
      id: id,
      type: type,
      amount: amount,
      categoryId: categoryId ?? await category(type),
      moment: at(date),
      note: note,
    );

    test('T02 full bill create/edit/delete and independent entry never write asset snapshots', () async {
      final asset = await repo.createProject(
        const ProjectDraft(name: 'A', type: 'asset', initialMinor: 100000),
      );
      final original = (await repo.watchWorkspace().first).balances;
      final id = await bill(10000);
      expect((await repo.watchWorkspace().first).balances, original);
      await bill(15000, id: id, date: '2026-10-02');
      final log = await repo.createProject(
        const ProjectDraft(name: 'I', type: 'income_log'),
      );
      await repo.saveRecord(log, amount: 777, moment: at('2026-10-03'));
      expect(
        (await ledger()).total((await ledger()).month('2026-10'), 'expense'),
        15000,
      );
      await repo.deleteBill(id);
      final w = await repo.watchWorkspace().first;
      expect(w.amount(w.project(asset)!), 100000);
      expect(w.amount(w.project(log)!), 777);
      expect(w.balances, original);
      expect((await ledger()).bills, isEmpty);
    });
    test('T07/T08 historical default, leap year and cross-year grouping use business date', () async {
      final today = BusinessDate(2026, 10, 31);
      for (final pair in [
        (2026, 9, '2026-09-30'),
        (2024, 2, '2024-02-29'),
        (2025, 2, '2025-02-28'),
        (2025, 12, '2025-12-31'),
      ]) {
        final date = defaultEntryDate(pair.$1, pair.$2, today).toString();
        expect(date, pair.$3);
        await bill(1, date: date);
      }
      final id = await bill(10000);
      await bill(15000, id: id, date: '2026-10-01');
      var l = await ledger();
      expect(l.total(l.month('2026-09'), 'expense'), 1);
      expect(l.total(l.month('2026-10'), 'expense'), 15000);
      expect(
        l.total(
          l.bills.where((b) => b.businessDate.startsWith('2026-')),
          'expense',
        ),
        15001,
      );
      await bill(16000, id: id, date: '2025-12-31', type: 'income');
      l = await ledger();
      expect(l.total(l.month('2026-10'), 'expense'), 0);
      expect(l.total(l.month('2025-12'), 'income'), 16000);
      expect(l.month('2026-01'), isEmpty);
    });
    test('T04 bill history preserves creation, before/after values and UTC system times; delete traces does not change facts', () async {
      final id = await bill(1234, note: 'before');
      final created = (await ledger()).bills.single.createdAtMs;
      clock = clock.add(const Duration(minutes: 1));
      await bill(5678, id: id, date: '2026-10-02', note: 'after');
      final history = (await repo.watchHistory('bill', id).first).single;
      expect(jsonDecode(history.beforeJson)['amountMinor'], 1234);
      expect(jsonDecode(history.afterJson)['businessDate'], '2026-10-02');
      expect(jsonDecode(history.afterJson)['note'], 'after');
      expect(jsonDecode(history.afterJson)['createdAt'], endsWith('Z'));
      expect(history.changedAtMs, clock.millisecondsSinceEpoch);
      expect((await ledger()).bills.single.createdAtMs, created);
      await repo.deleteHistory(history.id);
      expect((await ledger()).bills.single.amountMinor, 5678);
      await bill(6789, id: id);
      await repo.clearHistory('bill', id);
      expect((await ledger()).bills.single.amountMinor, 6789);
      await bill(7890, id: id);
      await repo.deleteBill(id);
      expect(await repo.watchHistory('bill', id).first, isEmpty);
    });
    test('T08/T09 distribution filters direction and recomputes after final record removed', () async {
      final ex = await bill(100, date: '2026-10-01');
      await bill(200, type: 'income', date: '2026-10-02');
      var l = await ledger();
      expect(l.distribution('2026-10', 'expense').values.single, 100);
      expect(l.distribution('2026-10', 'income').values.single, 200);
      expect(l.month('2026-10', 'expense').single.id, ex);
      await repo.deleteBill(ex);
      l = await ledger();
      expect(l.distribution('2026-10', 'expense'), isEmpty);
      expect(l.distribution('2026-10', 'income').values.single, 200);
    });
    test('T15 inactive category stays on old bills; wrong direction, inactive selection and direct referenced deletion are rejected', () async {
      final c = await category('expense'), id = await bill(100);
      await repo.saveCategory(
        id: c,
        name: '自定义 FOOD',
        type: 'expense',
        active: false,
      );
      await bill(200, id: id, categoryId: c);
      expect((await ledger()).category(c)!.customName, '自定义 FOOD');
      await expectLater(
        bill(1, categoryId: c),
        throwsA(isA<FinanceValidation>()),
      );
      await expectLater(
        bill(1, type: 'income', categoryId: c),
        throwsA(isA<FinanceValidation>()),
      );
      await expectLater(
        repo.deleteCategory(c),
        throwsA(isA<FinanceValidation>()),
      );
      expect((await ledger()).bills.single.amountMinor, 200);
    });
    test('T15 migration and deletion retain amounts, dates and original category history labels', () async {
      final c = await category('expense'), id = await bill(1234);
      final target = await repo.saveCategory(name: '迁移目标', type: 'expense');
      await repo.deleteCategory(c, replacementId: target);
      final l = await ledger(), b = l.bills.single;
      expect(l.category(c), isNull);
      expect(b.categoryId, target);
      expect(b.amountMinor, 1234);
      expect(b.businessDate, '2026-09-30');
      final h = (await repo.watchHistory('bill', id).first).single;
      expect(jsonDecode(h.beforeJson)['categoryNameKey'], 'food');
      expect(jsonDecode(h.afterJson)['categoryCustomName'], '迁移目标');
    });
    test('T04/T15 memo text, tags and date edit/search/history/delete do not change money', () async {
      await bill(900);
      final workspace = await repo.watchWorkspace().first;
      final id = await repo.saveMemo(
        title: '投资计划',
        body: 'Review ETF',
        date: BusinessDate(2024, 2, 29),
        tags: ['基金', 'ETF', '基金', ' '],
      );
      var l = await ledger();
      expect(memoTags(l.memos.single), ['基金', 'ETF']);
      expect(l.searchMemos('etf', '基金').single.id, id);
      expect(l.searchMemos('missing', null), isEmpty);
      await repo.saveMemo(
        id: id,
        title: '新标题',
        body: '已更新',
        date: BusinessDate(2026, 10, 1),
        tags: ['长期'],
      );
      l = await ledger();
      expect(l.searchMemos('etf', null), isEmpty);
      expect(l.searchMemos('新', '长期').single.id, id);
      final h = (await repo.watchHistory('memo', id).first).single;
      expect(jsonDecode(h.beforeJson)['tags'], ['基金', 'ETF']);
      await repo.clearHistory('memo', id);
      expect((await ledger()).memos.single.title, '新标题');
      await repo.deleteMemo(id);
      expect((await ledger()).memos, isEmpty);
      expect((await ledger()).bills.single.amountMinor, 900);
      expect((await repo.watchWorkspace().first).balances, workspace.balances);
    });
    test('transaction failure rolls back category migration, deletion and all bill histories', () async {
      final c = await category('expense');
      await bill(111);
      await bill(222);
      final target = await repo.saveCategory(name: 'Target', type: 'expense');
      await db.customStatement(
        "CREATE TRIGGER fail_bill_history BEFORE INSERT ON edit_histories WHEN NEW.entity_type = 'bill' BEGIN SELECT RAISE(ABORT,'injected failure'); END",
      );
      await expectLater(
        repo.deleteCategory(c, replacementId: target),
        throwsA(anything),
      );
      final l = await ledger();
      expect(l.category(c), isNotNull);
      expect(l.bills.every((b) => b.categoryId == c), isTrue);
      expect(await db.select(db.editHistories).get(), isEmpty);
    });
    test('invalid amounts, future dates, empty memo and tag limits write no partial rows', () async {
      for (final value in [0, -1, 1000000000000]) {
        await expectLater(bill(value), throwsA(isA<FinanceValidation>()));
      }
      await expectLater(
        bill(1, date: '2026-11-01'),
        throwsA(isA<FinanceValidation>()),
      );
      await expectLater(
        repo.saveMemo(
          title: ' ',
          body: '',
          date: BusinessDate(2026, 10, 1),
          tags: [],
        ),
        throwsA(isA<FinanceValidation>()),
      );
      await expectLater(
        repo.saveMemo(
          title: 'a',
          body: '',
          date: BusinessDate(2026, 10, 1),
          tags: List.generate(11, (i) => '$i'),
        ),
        throwsA(isA<FinanceValidation>()),
      );
      expect((await ledger()).bills, isEmpty);
      expect((await ledger()).memos, isEmpty);
    });
  });
  test('T04/T21 file reopening preserves bill/memo edits and deleted histories stay deleted', () async {
    final dir = await Directory.systemTemp.createTemp('finance-stage3-');
    final file = File('${dir.path}/ledger.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var repo = FinanceRepository(
      db,
      clock: () => DateTime.utc(2026, 10, 31, 14),
    );
    try {
      await repo.initialize('GMT');
      final category = (await repo.watchLedger().first).categories
          .firstWhere((c) => c.type == 'expense')
          .id;
      final id = await repo.saveBill(
        type: 'expense',
        amount: 1234,
        categoryId: category,
        moment: at('2026-09-30'),
      );
      await repo.saveBill(
        id: id,
        type: 'expense',
        amount: 5678,
        categoryId: category,
        moment: at('2026-10-01'),
        note: 'persisted',
      );
      await repo.clearHistory('bill', id);
      final memo = await repo.saveMemo(
        title: '持久化',
        body: 'body',
        date: BusinessDate(2024, 2, 29),
        tags: ['标签'],
      );
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      repo = FinanceRepository(db);
      final l = await repo.watchLedger().first;
      expect(l.bills.single.id, id);
      expect(l.bills.single.amountMinor, 5678);
      expect(l.bills.single.note, 'persisted');
      expect(l.memos.single.id, memo);
      expect(memoTags(l.memos.single), ['标签']);
      expect(await repo.watchHistory('bill', id).first, isEmpty);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
