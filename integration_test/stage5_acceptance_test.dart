import 'dart:convert';

import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/main.dart' as app;
import 'package:finance_app/services/backup_files.dart';
import 'package:finance_app/services/backup_manager.dart';
import 'package:finance_app/ui/bills_page.dart';
import 'package:finance_app/ui/finance_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';

import 'asset_flow_test.dart' show ready, reveal, tap;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Stage 5 real SQLite, 50 projects / 10000 records, paging and roundtrip',
    (tester) async {
      if (!const bool.fromEnvironment('FINANCE_QA_DISPOSABLE')) {
        fail(
          'Run only through the QA-only script with FINANCE_QA_DISPOSABLE=true.',
        );
      }
      app.main();
      await ready(
        tester,
        () => find.byKey(const Key('open-bills')).evaluate().isNotEmpty,
      );
      final c = tester.widget<FinanceApp>(find.byType(FinanceApp)).controller;
      final backup = BackupRepository(c.repository);
      final manager = BackupManager(backup, AndroidBackupFiles());
      await manager.reset('GMT');
      await c.refreshAfterRestore();
      await c.repository.setLanguage(AppLanguage.english);
      await c.repository.setAppearance(Appearance.light);
      await ready(tester, () => c.projects.length == 9 && c.totalAssets == 0);
      final now = bookNow(c);
      final date = '${now.date.yearMonth}-01';
      final moment = now;
      for (final (type, count) in [
        ('asset', 14),
        ('liability', 9),
        ('income_log', 9),
        ('expense_log', 9),
      ]) {
        for (var i = 0; i < count; i++) {
          await c.repository.createProject(
            ProjectDraft(name: 'QA_$type$i', type: type, initialMoment: moment),
          );
        }
      }
      await c.refreshAfterRestore();
      expect(c.projects.length, 50);
      final db = c.repository.database;
      final w = c.workspace!, ledger = c.ledger!;
      final balances = w.projects.where((p) => isBalanceType(p.type)).toList();
      final entries = w.projects.where((p) => !isBalanceType(p.type)).toList();
      final income = ledger.categories.firstWhere((c) => c.type == 'income').id;
      final expense = ledger.categories
          .firstWhere((c) => c.type == 'expense')
          .id;
      final prior = DateTime.utc(now.date.year, now.date.month - 1, 1);
      final priorDate =
          '${prior.year.toString().padLeft(4, '0')}-${prior.month.toString().padLeft(2, '0')}-01';
      const uuid = Uuid();
      final ms = DateTime.now().toUtc().millisecondsSinceEpoch;
      await db.batch((b) {
        b.insertAll(
          db.balanceRecords,
          List.generate(
            1470,
            (i) => BalanceRecordRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              projectId: balances[i % balances.length].id,
              balanceMinor: i + 1,
              businessDate: now.date.toString(),
              businessTime: now.time,
              orderKey: 10000 + i,
              note: 'QA balance $i',
            ),
          ),
        );
        b.insertAll(
          db.projectEntries,
          List.generate(
            3500,
            (i) => ProjectEntryRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              projectId: entries[i % entries.length].id,
              amountMinor: i + 1,
              businessDate: date,
              businessTime: '00:00',
              note: 'QA entry $i',
            ),
          ),
        );
        b.insertAll(
          db.bills,
          List.generate(
            5000,
            (i) => BillRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              type: i.isEven ? 'income' : 'expense',
              amountMinor: i + 1,
              categoryId: i.isEven ? income : expense,
              businessDate: [
                date,
                priorDate,
                '2024-02-29',
                '2025-12-31',
              ][i % 4],
              businessTime: '00:00',
              note: 'QA bill $i',
            ),
          ),
        );
        b.insertAll(
          db.memos,
          List.generate(
            100,
            (i) => MemoRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              title: 'QA memo $i',
              body: '中文 繁體 English',
              businessDate: date,
              tagsJson: '["QA"]',
            ),
          ),
        );
      });
      final watch = Stopwatch()..start();
      await c.refreshAfterRestore();
      await tester.pumpAndSettle(const Duration(milliseconds: 16));
      watch.stop();
      final homeMs = watch.elapsedMilliseconds;
      expect(
        c.workspace!.balances.length +
            c.workspace!.entries.length +
            c.ledger!.bills.length,
        10000,
      );
      expect(c.projects.length, 50);
      expect(c.totalAssets, greaterThan(0));
      expect(
        homeMs,
        lessThan(1000),
        reason: 'Home refresh target on this fixed QA emulator',
      );
      await tap(tester, find.byKey(const Key('open-bills')));
      final list = tester.widget<ListView>(find.byType(ListView).last);
      expect(
        (list.childrenDelegate as SliverChildListDelegate).children
            .whereType<Card>()
            .length,
        51,
      );
      await reveal(tester, find.byKey(const Key('more-bills')));
      await tester.tap(find.byKey(const Key('more-bills')));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<ListView>(find.byType(ListView).last).childrenDelegate
                as SliverChildListDelegate)
            .children
            .whereType<Card>()
            .length,
        101,
      );
      final switching = <int>[];
      for (var i = 0; i < 5; i++) {
        await reveal(
          tester,
          find.byKey(Key(i.isEven ? 'previous-month' : 'next-month')),
        );
        final timer = Stopwatch()..start();
        await tester.tap(
          find.byKey(Key(i.isEven ? 'previous-month' : 'next-month')),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 16));
        timer.stop();
        switching.add(timer.elapsedMilliseconds);
        expect(
          timer.elapsedMilliseconds,
          lessThan(1000),
          reason: 'Month-switch target on QA emulator',
        );
        expect(
          (tester.widget<ListView>(find.byType(ListView).last).childrenDelegate
                  as SliverChildListDelegate)
              .children
              .whereType<Card>()
              .length,
          51,
        );
      }
      final totalBefore = c.totalAssets;
      final captures = Stopwatch()..start();
      final a = await backup.capture();
      captures.stop();
      final restores = Stopwatch()..start();
      await backup.restore(a);
      await c.refreshAfterRestore();
      restores.stop();
      final b = await backup.capture();
      expect(b.data, a.data);
      expect(c.totalAssets, totalBefore);
      expect(tester.takeException(), isNull);
      final metrics = <String, dynamic>{
        'device': 'Finance_API_36 / emulator-5560',
        'mode': 'debug integration',
        'projects': 50,
        'financialRecords': 10000,
        'memos': 100,
        'homeRefreshMs': homeMs,
        'monthSwitchMs': switching,
        'backupBytes': a.bytes.length,
        'captureMs': captures.elapsedMilliseconds,
        'restoreMs': restores.elapsedMilliseconds,
        'roundtripEqual': true,
      };
      binding.reportData = metrics;
      debugPrint('STAGE5_METRICS=${jsonEncode(metrics)}');
      Navigator.of(tester.element(find.byType(BillsPage))).pop();
      await tester.pumpAndSettle();
      await manager.reset('GMT');
      await c.refreshAfterRestore();
      await ready(tester, () => c.projects.length == 9 && c.totalAssets == 0);
      expect(c.ledger!.bills, isEmpty);
      expect(c.ledger!.memos, isEmpty);
    },
  );
}
