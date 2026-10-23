import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

void main() {
  late AppDatabase database;
  late FinanceRepository repository;
  setUpAll(tzdata.initializeTimeZones);
  group('in-memory repository', () {
    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      repository = FinanceRepository(
        database,
        clock: () => DateTime.utc(2026, 10, 21, 10),
      );
      await repository.initialize('Asia/Shanghai');
    });
    tearDown(() => database.close());

    test(
      'fresh initialization seeds only zero snapshots and no fake flows',
      () async {
        expect(database.allTables.length, 9);
        expect(await database.select(database.projects).get(), hasLength(9));
        final balances = await database.select(database.balanceRecords).get();
        expect(balances, hasLength(7));
        expect(balances.every((row) => row.balanceMinor == 0), isTrue);
        expect(await database.select(database.projectEntries).get(), isEmpty);
        expect(await database.select(database.bills).get(), isEmpty);
        expect(await database.select(database.memos).get(), isEmpty);
        expect(await database.select(database.categories).get(), hasLength(9));
        final projects = await repository.watchDashboard().first;
        expect(projects.every((project) => project.amountMinor == 0), isTrue);
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.read<int>('user_version'), 3);
      },
    );

    test(
      'restarting initialization preserves deletions and saved preferences',
      () async {
        final project = (await database.select(database.projects).get()).first;
        await (database.delete(
          database.projects,
        )..where((row) => row.id.equals(project.id))).go();
        await repository.setAppearance(Appearance.dark);
        await repository.setLanguage(AppLanguage.traditionalChinese);
        await repository.initialize('America/Los_Angeles');
        expect(await database.select(database.projects).get(), hasLength(8));
        final settings = await repository.watchSettings().first;
        expect(settings.appearance, Appearance.dark);
        expect(settings.language, AppLanguage.traditionalChinese);
        expect(settings.timeZone, 'Asia/Shanghai');
      },
    );

    test(
      'a failed transaction rolls back both settings and balance changes',
      () async {
        final balance =
            (await database.select(database.balanceRecords).get()).first;
        await expectLater(
          database.transaction(() async {
            await repository.setLanguage(AppLanguage.english);
            await (database.update(
              database.balanceRecords,
            )..where((row) => row.id.equals(balance.id))).write(
              const BalanceRecordsCompanion(balanceMinor: Value(12345)),
            );
            throw StateError('Simulated write interruption');
          }),
          throwsStateError,
        );
        expect(
          (await repository.watchSettings().first).language,
          AppLanguage.system,
        );
        final unchanged = await (database.select(
          database.balanceRecords,
        )..where((row) => row.id.equals(balance.id))).getSingle();
        expect(unchanged.balanceMinor, 0);
      },
    );

    test(
      'SQL prevents wrong project types and mismatched bill categories',
      () async {
        final projects = await database.select(database.projects).get();
        final incomeProject = projects.firstWhere(
          (row) => row.type == 'income_log',
        );
        await expectLater(
          database
              .into(database.balanceRecords)
              .insert(
                BalanceRecordsCompanion.insert(
                  id: 'wrong-balance',
                  projectId: incomeProject.id,
                  balanceMinor: 0,
                  businessDate: '2026-10-20',
                  businessTime: '12:00',
                  orderKey: 1,
                  createdAtMs: 0,
                  updatedAtMs: 0,
                ),
              ),
          throwsA(anything),
        );
        final category = (await database.select(database.categories).get())
            .firstWhere((row) => row.type == 'income');
        await expectLater(
          database
              .into(database.bills)
              .insert(
                BillsCompanion.insert(
                  id: 'wrong-category',
                  type: 'expense',
                  amountMinor: 1,
                  categoryId: category.id,
                  businessDate: '2026-10-20',
                  businessTime: '12:00',
                  createdAtMs: 0,
                  updatedAtMs: 0,
                ),
              ),
          throwsA(anything),
        );
        expect(await database.select(database.bills).get(), isEmpty);
      },
    );

    test('bills do not modify assets, snapshot deletes fall back, and edit-history deletes preserve balances', () async {
      final initial =
          (await database.select(database.balanceRecords).get()).first;
      await database
          .into(database.balanceRecords)
          .insert(
            BalanceRecordsCompanion.insert(
              id: 'latest',
              projectId: initial.projectId,
              balanceMinor: 120000,
              businessDate: '2026-10-21',
              businessTime: '17:00',
              orderKey: 1,
              createdAtMs: 1,
              updatedAtMs: 1,
            ),
          );
      // Move the initial zero snapshot before the explicit balance update.
      await (database.update(
        database.balanceRecords,
      )..where((row) => row.id.equals(initial.id))).write(
        const BalanceRecordsCompanion(businessDate: Value('2026-10-01')),
      );
      final category = (await database.select(database.categories).get())
          .firstWhere((row) => row.type == 'expense');
      await database
          .into(database.bills)
          .insert(
            BillsCompanion.insert(
              id: 'bill',
              type: 'expense',
              amountMinor: 10000,
              categoryId: category.id,
              businessDate: '2026-09-30',
              businessTime: '12:00',
              createdAtMs: 1,
              updatedAtMs: 1,
            ),
          );
      await database
          .into(database.editHistories)
          .insert(
            EditHistoriesCompanion.insert(
              id: 'history',
              entityType: 'balanceRecord',
              entityId: 'latest',
              changedAtMs: 1,
              beforeJson: '{"balanceMinor":0}',
              afterJson: '{"balanceMinor":120000}',
            ),
          );
      await database.delete(database.editHistories).go();
      var dashboard = await repository.watchDashboard().first;
      expect(
        dashboard.firstWhere((row) => row.id == initial.projectId).amountMinor,
        120000,
      );
      await (database.delete(
        database.balanceRecords,
      )..where((row) => row.id.equals('latest'))).go();
      dashboard = await repository.watchDashboard().first;
      expect(
        dashboard.firstWhere((row) => row.id == initial.projectId).amountMinor,
        0,
      );
      expect(await database.select(database.bills).get(), hasLength(1));
    });
  });

  test(
    'file database survives close and reopen without reseeding or losing cents',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'finance-persistence-',
      );
      final file = File('${directory.path}/test.sqlite');
      var persistent = AppDatabase(NativeDatabase(file));
      var repo = FinanceRepository(persistent);
      try {
        await repo.initialize('Asia/Shanghai');
        await repo.setAppearance(Appearance.dark);
        await repo.setLanguage(AppLanguage.english);
        final balance =
            (await persistent.select(persistent.balanceRecords).get()).first;
        await (persistent.update(persistent.balanceRecords)
              ..where((row) => row.id.equals(balance.id)))
            .write(const BalanceRecordsCompanion(balanceMinor: Value(1)));
        await persistent.close();
        persistent = AppDatabase(NativeDatabase(file));
        repo = FinanceRepository(persistent);
        await repo.initialize('America/Los_Angeles');
        expect((await repo.watchSettings().first).appearance, Appearance.dark);
        expect(
          (await repo.watchSettings().first).language,
          AppLanguage.english,
        );
        expect((await repo.watchSettings().first).timeZone, 'Asia/Shanghai');
        final records = await persistent
            .select(persistent.balanceRecords)
            .get();
        expect(records, hasLength(7));
        expect(
          records.firstWhere((row) => row.id == balance.id).balanceMinor,
          1,
        );
      } finally {
        await persistent.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
