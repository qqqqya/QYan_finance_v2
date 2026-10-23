import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/domain/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'backup_workflow_test.dart' show testNow;

void main() {
  setUpAll(tz.initializeTimeZones);
  test('v2 SQLite upgrade adds only blue preference, preserving all facts and user order; cold reopen persists color', () async {
    final dir = await Directory.systemTemp.createTemp('finance-theme-upgrade-');
    final path = File('${dir.path}/finance.sqlite');
    var db = AppDatabase(NativeDatabase(path));
    try {
      var f = FinanceRepository(db, clock: () => testNow);
      await f.initialize('GMT');
      final old = BackupDocument.decode(
        await File('test/fixtures/backups/v1-stage4-all-types.json')
            .readAsBytes(),
        now: testNow,
      );
      await BackupRepository(f).restore(old);
      final expected = (await BackupRepository(f).capture()).data;
      final beforeOrder = (await f.watchWorkspace().first).projects
          .map((p) => p.id)
          .toList();
      await db.customStatement(
        'ALTER TABLE app_preferences DROP COLUMN theme_color',
      );
      await db.customStatement('PRAGMA user_version=2');
      await db.close();
      db = AppDatabase(NativeDatabase(path));
      f = FinanceRepository(db, clock: () => testNow);
      await f.initialize('America/New_York');
      expect((await BackupRepository(f).capture()).data, expected);
      expect(
        (await f.watchWorkspace().first).projects.map((p) => p.id),
        beforeOrder,
      );
      expect((await f.watchSettings().first).themeColor, ThemeColor.blue);
      await f.setThemeColor(ThemeColor.purple);
      await f.reorderProjects(beforeOrder.reversed.toList());
      final saved = await BackupRepository(f).capture();
      expect(saved.root['schemaVersion'], 2);
      await db.close();
      db = AppDatabase(NativeDatabase(path));
      f = FinanceRepository(db, clock: () => testNow);
      await f.initialize('GMT');
      expect((await BackupRepository(f).capture()).data, saved.data);
      expect((await f.watchSettings().first).themeColor, ThemeColor.purple);
      await BackupRepository(f).restore(old);
      expect((await BackupRepository(f).capture()).data, expected);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
  test('fresh/factory defaults put large expense then debt first without rewriting a saved custom order', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final f = FinanceRepository(db, clock: () => testNow);
      await f.initialize('GMT');
      var w = await f.watchWorkspace().first;
      expect(w.projects.take(2).map((p) => p.nameKey), [
        'largeExpense',
        'liability',
      ]);
      expect(w.summaries.every((p) => p.amountMinor == 0), isTrue);
      final ids = w.projects.reversed.map((p) => p.id).toList();
      await f.reorderProjects(ids);
      await f.initialize('GMT');
      expect((await f.watchWorkspace().first).projects.map((p) => p.id), ids);
      await BackupRepository(f).reset('GMT');
      w = await f.watchWorkspace().first;
      expect(w.projects.take(2).map((p) => p.nameKey), [
        'largeExpense',
        'liability',
      ]);
    } finally {
      await db.close();
    }
  });
}
