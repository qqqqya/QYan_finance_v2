import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/core/money.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

BusinessMoment moment(String date, [String time = '12:00']) =>
    BusinessMoment(BusinessDate.parse(date), time);
void main() {
  late AppDatabase db;
  late FinanceRepository repo;
  var clock = DateTime.utc(2026, 10, 22, 12);
  setUpAll(tz.initializeTimeZones);
  group('in-memory asset workflow', () {
    setUp(() async {
      clock = DateTime.utc(2026, 10, 22, 12);
      db = AppDatabase(NativeDatabase.memory());
      repo = FinanceRepository(db, clock: () => clock);
      await repo.initialize('GMT');
    });
    tearDown(() => db.close());
    Future<String> create(String name, String type, [int initial = 0]) =>
        repo.createProject(
          ProjectDraft(
            name: name,
            type: type,
            initialMinor: initial,
            initialMoment: moment('2026-10-01'),
          ),
        );
    Future<Workspace> workspace() => repo.watchWorkspace().first;

    test('T01/T05 four types start empty or zero; only included balance types enter totals', () async {
      final asset = await create('A', 'asset', 100000);
      await create('B', 'asset', 200000);
      await create('Debt', 'liability', 50000);
      final income = await create('Income', 'income_log');
      final expense = await create('Expense', 'expense_log');
      await repo.saveRecord(
        income,
        amount: 77777,
        moment: moment('2026-10-02'),
      );
      await repo.saveRecord(
        expense,
        amount: 1234,
        moment: moment('2026-10-02'),
      );
      var w = await workspace();
      expect(
        checkedSumMinor(
          w.summaries
              .where((p) => p.type == 'asset' && p.included)
              .map((p) => p.amountMinor),
        ),
        300000,
      );
      expect(
        checkedSumMinor(
          w.summaries
              .where((p) => p.type == 'liability' && p.included)
              .map((p) => p.amountMinor),
        ),
        50000,
      );
      expect(w.amount(w.project(income)!), 77777);
      expect(w.amount(w.project(expense)!), 1234);
      expect(
        await db.select(db.bills).get(),
        isEmpty,
        reason: 'Full bill UI coupling acceptance is deferred to stage 3.',
      );
      await repo.editProject(
        asset,
        const ProjectDraft(name: 'A', type: 'asset', included: false),
      );
      w = await workspace();
      expect(
        checkedSumMinor(
          w.summaries
              .where((p) => p.type == 'asset' && p.included)
              .map((p) => p.amountMinor),
        ),
        200000,
      );
    });

    test('T03 old backfill, same-minute order, edited date, deleting latest and clearing', () async {
      final id = await create('Balance', 'asset', 100000);
      final newer = await repo.saveRecord(
        id,
        amount: 120000,
        moment: moment('2026-10-10'),
        note: 'later',
      );
      final old = await repo.saveRecord(
        id,
        amount: 80000,
        moment: moment('2026-09-30'),
      );
      expect(
        (await workspace()).amount((await workspace()).project(id)!),
        120000,
      );
      final sameTime = await repo.saveRecord(
        id,
        amount: 130000,
        moment: moment('2026-10-10'),
      );
      var w = await workspace();
      expect(w.amount(w.project(id)!), 130000);
      final stableOrder = w.balances.firstWhere((r) => r.id == newer).orderKey;
      await repo.saveRecord(
        id,
        recordId: newer,
        amount: 125000,
        moment: moment('2026-10-10'),
      );
      expect(
        (await workspace()).amount(w.project(id)!),
        130000,
        reason: 'Editing must not create a newer orderKey.',
      );
      await repo.saveRecord(
        id,
        recordId: old,
        amount: 90000,
        moment: moment('2026-10-11'),
        note: 'moved',
      );
      w = await workspace();
      expect(w.amount(w.project(id)!), 90000);
      expect(w.balances.firstWhere((r) => r.id == newer).orderKey, stableOrder);
      await repo.deleteRecord(id, old);
      expect((await workspace()).amount(w.project(id)!), 130000);
      await repo.deleteRecord(id, sameTime);
      expect((await workspace()).amount(w.project(id)!), 125000);
      await repo.clearRecords(id);
      w = await workspace();
      expect(w.amount(w.project(id)!), 0);
      expect(w.balances.where((r) => r.projectId == id), isEmpty);
      expect(await db.select(db.editHistories).get(), isEmpty);
    });

    test('T04 edit history captures cents, business time and notes; history deletion has no financial effect', () async {
      final id = await create('Log', 'income_log');
      final record = await repo.saveRecord(
        id,
        amount: 1,
        moment: moment('2026-09-30'),
        note: 'old',
      );
      final original = (await workspace()).entries.firstWhere(
        (r) => r.id == record,
      );
      clock = clock.add(const Duration(seconds: 1));
      await repo.saveRecord(
        id,
        recordId: record,
        amount: 1234,
        moment: moment('2026-10-01', '13:05'),
        note: 'new',
      );
      var history = await repo.watchHistory('projectEntry', record).first;
      expect(history, hasLength(1));
      expect(history.single.beforeJson, contains('"amountMinor":1'));
      expect(history.single.afterJson, contains('"businessDate":"2026-10-01"'));
      expect(history.single.afterJson, contains('"note":"new"'));
      expect(history.single.changedAtMs, clock.millisecondsSinceEpoch);
      expect(
        (await workspace()).entries
            .firstWhere((r) => r.id == record)
            .createdAtMs,
        original.createdAtMs,
      );
      await repo.deleteHistory(history.single.id);
      expect(
        (await workspace()).amount((await workspace()).project(id)!),
        1234,
      );
      await repo.saveRecord(
        id,
        recordId: record,
        amount: 999,
        moment: moment('2026-10-01'),
        note: 'another',
      );
      await repo.clearHistory('projectEntry', record);
      expect(await repo.watchHistory('projectEntry', record).first, isEmpty);
      expect((await workspace()).amount((await workspace()).project(id)!), 999);
      await repo.saveRecord(
        id,
        recordId: record,
        amount: 900,
        moment: moment('2026-10-01'),
      );
      await repo.deleteRecord(id, record);
      expect(await repo.watchHistory('projectEntry', record).first, isEmpty);
      expect((await workspace()).amount((await workspace()).project(id)!), 0);
    });

    test('record save and its history roll back together on injected SQLite failure', () async {
      final id = await create('Atomic', 'asset', 100);
      final row = (await workspace()).balances.firstWhere(
        (r) => r.projectId == id,
      );
      await db.customStatement(
        "CREATE TRIGGER fail_history BEFORE INSERT ON edit_histories BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      await expectLater(
        repo.saveRecord(
          id,
          recordId: row.id,
          amount: 200,
          moment: moment('2026-10-02'),
          note: 'must not stick',
        ),
        throwsA(isA<Exception>()),
      );
      final unchanged = (await workspace()).balances.firstWhere(
        (r) => r.id == row.id,
      );
      expect(unchanged.balanceMinor, 100);
      expect(unchanged.businessDate, '2026-10-01');
      expect(unchanged.note, '');
      expect(await db.select(db.editHistories).get(), isEmpty);
    });

    test('T06 invalid amounts, future dates and type changes cannot partially write', () async {
      final id = await create('Boundary', 'asset', maxRecordMinor);
      final count = (await workspace()).projects.length;
      for (final amount in [-1, maxRecordMinor + 1]) {
        await expectLater(
          repo.saveRecord(id, amount: amount, moment: moment('2026-10-02')),
          throwsA(isA<FinanceValidation>()),
        );
      }
      await expectLater(
        repo.createProject(
          ProjectDraft(
            name: 'future',
            type: 'asset',
            initialMoment: moment('2026-10-23'),
          ),
        ),
        throwsA(isA<FinanceValidation>()),
      );
      expect((await workspace()).projects, hasLength(count));
      await expectLater(
        repo.editProject(id, const ProjectDraft(name: 'X', type: 'income_log')),
        throwsA(isA<FinanceValidation>()),
      );
      final income = await create('Income', 'income_log');
      await expectLater(
        repo.saveRecord(income, amount: 0, moment: moment('2026-10-02')),
        throwsA(isA<FinanceValidation>()),
      );
      expect(
        (await workspace()).amount((await workspace()).project(id)!),
        maxRecordMinor,
      );
      expect(await db.select(db.editHistories).get(), isEmpty);
    });

    test('T11 exact reorder is atomic; project deletion cascades and never reseeds', () async {
      final id = await create('Delete me', 'asset', 12345);
      final p = (await workspace()).project(id)!;
      await repo.editProject(
        id,
        const ProjectDraft(name: 'Renamed', type: 'asset', note: 'metadata'),
      );
      final ids = (await workspace()).projects
          .map((p) => p.id)
          .toList()
          .reversed
          .toList();
      await repo.reorderProjects(ids);
      expect((await workspace()).projects.map((p) => p.id), ids);
      await expectLater(
        repo.reorderProjects([...ids, ids.first]),
        throwsA(isA<FinanceValidation>()),
      );
      expect((await workspace()).projects.map((p) => p.id), ids);
      expect((await workspace()).project(id)!.createdAtMs, p.createdAtMs);
      await repo.deleteProject(id);
      final defaultId = (await workspace()).projects.first.id;
      await repo.deleteProject(defaultId);
      await repo.initialize('GMT');
      final w = await workspace();
      expect(w.projects, hasLength(8));
      expect(
        w.balances.any((r) => r.projectId == id || r.projectId == defaultId),
        false,
      );
      expect(await db.select(db.editHistories).get(), isEmpty);
    });
  });
  test(
    'T21 file reopen preserves IDs, cents, metadata, history and order',
    () async {
      final temp = await Directory.systemTemp.createTemp('finance_stage2_');
      final file = File('${temp.path}/book.sqlite');
      final disk = AppDatabase(NativeDatabase(file));
      final writer = FinanceRepository(disk, clock: () => clock);
      try {
        await writer.initialize('GMT');
        final id = await writer.createProject(
          const ProjectDraft(
            name: 'Persistent',
            type: 'expense_log',
            note: 'kept',
          ),
        );
        final record = await writer.saveRecord(
          id,
          amount: 1,
          moment: moment('2026-10-01'),
        );
        await writer.saveRecord(
          id,
          recordId: record,
          amount: 12345,
          moment: moment('2026-10-02'),
          note: 'cents',
        );
        final order = (await writer.watchWorkspace().first).projects
            .map((p) => p.id)
            .toList()
            .reversed
            .toList();
        await writer.reorderProjects(order);
        await disk.close();
        final reopened = AppDatabase(NativeDatabase(file));
        try {
          final reader = FinanceRepository(reopened, clock: () => clock);
          await reader.initialize('GMT');
          final w = await reader.watchWorkspace().first;
          expect(w.projects.map((p) => p.id), order);
          expect(w.amount(w.project(id)!), 12345);
          expect(w.project(id)!.note, 'kept');
          expect(w.entries.single.id, record);
          expect(
            await reader.watchHistory('projectEntry', record).first,
            hasLength(1),
          );
        } finally {
          await reopened.close();
        }
      } finally {
        await disk.close();
        await temp.delete(recursive: true);
      }
    },
  );
}
