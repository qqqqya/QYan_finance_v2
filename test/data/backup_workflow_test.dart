import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/domain/backup_document.dart';
import 'package:finance_app/services/backup_files.dart';
import 'package:finance_app/services/backup_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

final testNow = DateTime.utc(2026, 10, 22, 12, 34, 56);
BusinessMoment at(String d, [String t = '10:00']) =>
    BusinessMoment(BusinessDate.parse(d), t);
Uint8List encodeRoot(Map<String, dynamic> root) {
  final unsigned = {...root}..remove('checksum');
  return Uint8List.fromList(utf8.encode(canonicalJson(signedBackup(unsigned))));
}

Map<String, dynamic> cloneRoot(BackupDocument d) =>
    jsonDecode(utf8.decode(d.bytes)) as Map<String, dynamic>;

class TestFiles implements BackupFiles {
  Uint8List? imported, written;
  bool cancelSave = false, failPurge = false;
  Object? failure;
  int saves = 0, shares = 0, purges = 0;
  @override
  Future<SavedBackup?> save(Uint8List bytes, String name) async {
    saves++;
    if (failure != null) throw failure!;
    if (cancelSave) return null;
    written = Uint8List.fromList(bytes);
    return SavedBackup(
      name,
      'content://test/doc/1',
      'Downloads/$name',
      bytes.length,
    );
  }

  @override
  Future<Uint8List?> open() async {
    if (failure != null) throw failure!;
    return imported;
  }

  @override
  Future<void> share(String uri, String name) async {
    shares++;
    if (failure != null) throw failure!;
  }

  @override
  Future<void> purge() async {
    purges++;
    if (failPurge) throw PlatformException(code: 'cachePurge');
  }
}

Future<void> seedEveryType(FinanceRepository repo) async {
  final asset = await repo.createProject(
    ProjectDraft(
      name: '中文資產 EN',
      type: 'asset',
      initialMinor: 123456,
      initialMoment: at('2026-10-20'),
      note: '备注 原文',
    ),
  );
  final balance = await repo.saveRecord(
    asset,
    amount: 55500,
    moment: at('2026-10-21'),
    note: 'before',
  );
  await repo.saveRecord(
    asset,
    recordId: balance,
    amount: 33333,
    moment: at('2026-10-21', '11:00'),
    note: '修改後 EN',
  );
  var w = await repo.watchWorkspace().first;
  final income = w.projects.firstWhere((p) => p.type == 'income_log').id;
  final expense = w.projects.firstWhere((p) => p.type == 'expense_log').id;
  await repo.saveRecord(income, amount: 1234, moment: at('2026-09-30'));
  await repo.saveRecord(expense, amount: 345, moment: at('2026-10-01'));
  final debt = await repo.createProject(
    ProjectDraft(
      name: 'Debt',
      type: 'liability',
      initialMinor: 10001,
      initialMoment: at('2026-10-20'),
    ),
  );
  await repo.saveRecord(debt, amount: 8888, moment: at('2026-10-21'));
  final l = await repo.watchLedger().first;
  final food = l.categories.firstWhere((c) => c.nameKey == 'food').id;
  final salary = l.categories.firstWhere((c) => c.nameKey == 'salary').id;
  final bill = await repo.saveBill(
    type: 'expense',
    amount: 99,
    categoryId: food,
    moment: at('2026-10-01'),
    note: 'before',
  );
  await repo.saveBill(
    id: bill,
    type: 'expense',
    amount: 150,
    categoryId: food,
    moment: at('2026-09-30'),
    note: '账单 修改',
  );
  await repo.saveBill(
    type: 'income',
    amount: 20040,
    categoryId: salary,
    moment: at('2026-10-02'),
  );
  final target = await repo.saveCategory(name: '收入分類 custom', type: 'income');
  await repo.saveCategory(
    id: target,
    name: '收入分类 EN',
    type: 'income',
    active: true,
  );
  await repo.deleteCategory(salary, replacementId: target);
  final memo = await repo.saveMemo(
    title: '计划 Plan',
    body: '繁體與 English\n文字',
    date: BusinessDate(2024, 2, 29),
    tags: ['中文', '繁體', 'English'],
  );
  await repo.saveMemo(
    id: memo,
    title: '计划 Plan',
    body: '已修改 Updated',
    date: BusinessDate(2024, 2, 29),
    tags: ['中文', '繁體', 'English'],
  );
  w = await repo.watchWorkspace().first;
  await repo.reorderProjects(
    w.projects.map((p) => p.id).toList().reversed.toList(),
  );
  await repo.setAppearance(Appearance.dark);
  await repo.setLanguage(AppLanguage.traditionalChinese);
}

void main() {
  setUpAll(tz.initializeTimeZones);
  test('real clock microseconds are normalized to protocol millisecond precision on export', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 22, 12, 34, 56, 123, 456);
    final f = FinanceRepository(db, clock: () => now);
    try {
      await f.initialize('GMT');
      final doc = await BackupRepository(f).capture();
      expect(doc.exportedAt, '2026-10-22T12:34:56.123Z');
      expect(BackupDocument.decode(doc.bytes, now: now).assets, 0);
    } finally {
      await db.close();
    }
  });
  group('backup workflow', () {
    late AppDatabase db;
    late FinanceRepository finance;
    late BackupRepository repo;
    late TestFiles files;
    late BackupManager manager;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      finance = FinanceRepository(db, clock: () => testNow);
      await finance.initialize('Asia/Shanghai');
      repo = BackupRepository(finance);
      files = TestFiles();
      manager = BackupManager(repo, files);
    });
    tearDown(() => db.close());
    test(
      'protocol minimal sample includes the real canonical checksum',
      () async {
        final bytes = await File('docs/backup/finance-backup-v1.minimal.json')
            .readAsBytes();
        final doc = BackupDocument.decode(bytes, now: testNow);
        expect(doc.count('projects'), 1);
        expect(doc.assets, 0);
      },
    );
    test('T16 every entity, IDs, cents, histories, ordering and settings round-trip into zero book', () async {
      await seedEveryType(finance);
      final a = await repo.capture();
      expect(a.count('editHistory'), greaterThanOrEqualTo(5));
      expect(a.assets, 33333);
      expect(a.liabilities, 8888);
      await repo.reset('GMT');
      await manager.purgePending();
      final before = await repo.capture();
      await repo.restore(a);
      final b = await repo.capture();
      expect(b.data, a.data);
      expect((await repo.recovery())!.data, before.data);
      expect(b.data.keys.toSet(), {...backupCollections, 'settings'});
      expect(b.data.containsKey('localDataStates'), isFalse);
      await repo.restore(a);
      expect(
        (await repo.capture()).data,
        a.data,
        reason: 'Repeated restore replaces, never adds rows.',
      );
      expect((await repo.recovery())!.data, a.data);
    });
    test('T16 restoring the private copy swaps it with the current snapshot, without recursive copies', () async {
      final original = await repo.capture();
      await seedEveryType(finance);
      final changed = await repo.capture();
      await repo.restore(original);
      final copy = (await repo.recovery())!;
      expect(copy.data, changed.data);
      await repo.restore(copy);
      expect((await repo.capture()).data, changed.data);
      expect((await repo.recovery())!.data, original.data);
      await repo.deleteRecovery();
      expect(await repo.recovery(), isNull);
      expect((await repo.capture()).data, changed.data);
    });
    test(
      'T17 checksum rejects modified bytes before any database writes',
      () async {
        final a = await repo.capture(), root = cloneRoot(await repo.capture());
        root['data']['projects'][0]['note'] = 'tampered';
        files.imported = Uint8List.fromList(utf8.encode(jsonEncode(root)));
        await expectLater(
          manager.pick(),
          throwsA(
            isA<BackupFailure>().having(
              (e) => e.code,
              'code',
              'backupChecksum',
            ),
          ),
        );
        expect((await repo.capture()).data, a.data);
        expect(await repo.recovery(), isNull);
      },
    );
    test('T17 semantic validation rejects bad fields, IDs, references, dates, money and owner types even with valid checksum', () async {
      await seedEveryType(finance);
      final a = await repo.capture();
      final cases = <String, void Function(Map<String, dynamic>)>{
        'missing collection': (r) => r['data'].remove('bills'),
        'unknown top field': (r) => r['extra'] = 1,
        'future version': (r) => r['schemaVersion'] = 2,
        'fractional cents': (r) => r['data']['bills'][0]['amountMinor'] = 1.5,
        'float cents': (r) => r['data']['bills'][0]['amountMinor'] = 1.0,
        'negative balance': (r) =>
            r['data']['balanceRecords'][0]['balanceMinor'] = -1,
        'over limit': (r) =>
            r['data']['bills'][0]['amountMinor'] = 1000000000000,
        'duplicate ID': (r) =>
            r['data']['projects'][1]['id'] = r['data']['projects'][0]['id'],
        'missing parent': (r) => r['data']['bills'][0]['categoryId'] =
            '11111111-1111-4111-8111-111111111111',
        'wrong category direction': (r) => r['data']['bills'][0]['type'] =
            r['data']['bills'][0]['type'] == 'income' ? 'expense' : 'income',
        'invalid date': (r) =>
            r['data']['bills'][0]['businessDate'] = '2025-02-29',
        'future date': (r) =>
            r['data']['bills'][0]['businessDate'] = '2026-10-23',
        'future minute': (r) {
          r['data']['bills'][0]['businessDate'] = '2026-10-22';
          r['data']['bills'][0]['businessTime'] = '23:59';
        },
        'invalid time': (r) => r['data']['bills'][0]['businessTime'] = '24:00',
        'invalid zone': (r) {
          r['timeZone'] = 'Bad/Zone';
          r['data']['settings']['timeZone'] = 'Bad/Zone';
        },
        'header mismatch': (r) => r['data']['settings']['currency'] = 'USD',
        'orphan history': (r) => r['data']['editHistory'][0]['entityId'] =
            '11111111-1111-4111-8111-111111111111',
        'history decimal': (r) =>
            r['data']['editHistory'][0]['after']['amountMinor'] = 0.5,
        'invalid bool': (r) => r['data']['projects'][0]['includeInSummary'] = 1,
        'unknown enum': (r) => r['data']['settings']['themeMode'] = 'sepia',
        'duplicate tags': (r) => r['data']['memos'][0]['tags'] = ['A', 'A'],
        'wrong entity type': (r) =>
            r['data']['balanceRecords'][0]['projectId'] =
                (r['data']['projects'] as List).firstWhere(
                  (p) => p['type'] == 'income_log',
                )['id'],
      };
      for (final e in cases.entries) {
        final root = cloneRoot(a);
        e.value(root);
        expect(
          () => BackupDocument.decode(encodeRoot(root), now: testNow),
          throwsA(isA<BackupFailure>()),
          reason: e.key,
        );
      }
      expect((await repo.capture()).data, a.data);
    });
    test('T17 bad encoding, JSON and unsupported resources are rejected without partial data', () async {
      final a = await repo.capture();
      for (final bytes in [
        Uint8List.fromList([0xff, 0xfe]),
        Uint8List.fromList(utf8.encode('{"broken":')),
        Uint8List(maxBackupBytes + 1),
      ]) {
        expect(
          () => BackupDocument.decode(bytes, now: testNow),
          throwsA(isA<BackupFailure>()),
        );
      }
      final root = cloneRoot(a);
      root['data']['memos'] = List.generate(
        maxBackupRows + 1,
        (_) => <String, dynamic>{},
      );
      expect(
        () => BackupDocument.decode(encodeRoot(root), now: testNow),
        throwsA(
          isA<BackupFailure>().having((e) => e.code, 'code', 'backupTooLarge'),
        ),
      );
      expect((await repo.capture()).data, a.data);
    });
    test('T18 cancel save/open and denied or full storage never record export success or alter business rows', () async {
      final before = await repo.capture();
      files.cancelSave = true;
      expect(await manager.export('备份'), isNull);
      expect((await repo.watchStatus().first).local, isNull);
      expect(await manager.pick(), isNull);
      for (final code in [
        'filePermission',
        'noSpace',
        'fileWrite',
        'fileRead',
      ]) {
        files.failure = PlatformException(code: code);
        await expectLater(
          manager.export('备份'),
          throwsA(isA<PlatformException>()),
        );
        expect((await repo.watchStatus().first).local, isNull);
      }
      expect((await repo.capture()).data, before.data);
    });
    test('T16/T18 successful export is restorable and records actual verified name, URI and size', () async {
      await seedEveryType(finance);
      final outcome = (await manager.export('财务备份'))!;
      expect(outcome.file.name, '财务备份_2026-10-22_203456.moneybak');
      expect(outcome.file.size, files.written!.length);
      final picked = BackupDocument.decode(files.written!, now: testNow);
      expect(picked.data, (await repo.capture()).data);
      final local = (await repo.watchStatus().first).local!;
      expect(local.lastExportUri, 'content://test/doc/1');
      expect(local.lastExportBytes, files.written!.length);
      await files.share(local.lastExportUri!, local.lastExportName!);
      expect(files.shares, 1);
    });
    test('T18 private-copy write failure prevents replacement and preserves the previous copy', () async {
      final a = await repo.capture();
      await seedEveryType(finance);
      await repo.restore(a);
      final copy = (await repo.recovery())!, before = await repo.capture();
      await db.customStatement(
        "CREATE TRIGGER fail_copy BEFORE UPDATE OF recovery_json ON local_data_states BEGIN SELECT RAISE(ABORT,'injected copy failure'); END",
      );
      await expectLater(repo.restore(copy), throwsA(anything));
      expect((await repo.capture()).data, before.data);
      expect((await repo.recovery())!.data, copy.data);
    });
    test('T19 injected interruption after deletion and partial inserts rolls back all entities and recovery metadata', () async {
      await seedEveryType(finance);
      final imported = await repo.capture();
      await repo.reset('GMT');
      await manager.purgePending();
      final before = await repo.capture();
      await db.customStatement(
        "CREATE TRIGGER interrupt_restore BEFORE INSERT ON bills BEGIN SELECT RAISE(ABORT,'interrupted after parents were inserted'); END",
      );
      await expectLater(repo.restore(imported), throwsA(anything));
      expect((await repo.capture()).data, before.data);
      expect(await repo.recovery(), isNull);
      expect(
        (await db.customSelect('PRAGMA foreign_key_check').get()),
        isEmpty,
      );
    });
    test('T19 factory-reset interruption restores original facts, settings and private copy', () async {
      final a = await repo.capture();
      await seedEveryType(finance);
      await repo.restore(a);
      final before = await repo.capture(), copy = (await repo.recovery())!;
      await db.customStatement(
        "CREATE TRIGGER interrupt_reset BEFORE INSERT ON projects WHEN NEW.name_key='cash' BEGIN SELECT RAISE(ABORT,'reset interrupted'); END",
      );
      await expectLater(repo.reset('GMT'), throwsA(anything));
      expect((await repo.capture()).data, before.data);
      expect((await repo.recovery())!.data, copy.data);
    });
    test('T20 reset clears all private data and metadata, seeds zero defaults and leaves exported external bytes intact', () async {
      await seedEveryType(finance);
      await manager.export('备份');
      final external = Uint8List.fromList(files.written!);
      await repo.restore(await repo.capture());
      expect(await repo.recovery(), isNotNull);
      await manager.reset('GMT');
      final doc = await repo.capture(),
          local = (await repo.watchStatus().first).local!;
      expect(doc.count('projects'), 9);
      expect(doc.assets, 0);
      expect(doc.liabilities, 0);
      for (final t in ['bills', 'memos', 'editHistory', 'projectEntries']) {
        expect(doc.count(t), 0);
      }
      expect(doc.data['settings'], {
        'themeMode': 'system',
        'languageMode': 'system',
        'currency': 'CNY',
        'timeZone': 'GMT',
      });
      expect(await repo.recovery(), isNull);
      expect(local.lastExportUri, isNull);
      expect(local.pendingCachePurge, isFalse);
      expect(files.written, external);
      expect(files.purges, 1);
    });
    test('T20 failed post-reset private-cache cleanup persists a retry flag and does not claim full success', () async {
      await seedEveryType(finance);
      files.failPurge = true;
      await expectLater(
        manager.reset('GMT'),
        throwsA(
          isA<BackupFailure>().having((e) => e.code, 'code', 'cachePurge'),
        ),
      );
      expect((await repo.capture()).assets, 0);
      expect(await repo.purgePending, isTrue);
      files.failPurge = false;
      await manager.purgePending();
      expect(await repo.purgePending, isFalse);
    });
  });
  test('v1 -> v2 migration preserves all eight business tables, IDs, histories and settings; restart resumes committed cache purge', () async {
    final dir = await Directory.systemTemp.createTemp('finance-migration-');
    final file = File('${dir.path}/finance.sqlite');
    var db = AppDatabase(NativeDatabase(file));
    var finance = FinanceRepository(db, clock: () => testNow);
    try {
      await finance.initialize('Asia/Shanghai');
      await seedEveryType(finance);
      final expected = (await BackupRepository(finance).capture()).data;
      await db.customStatement('DROP TABLE local_data_states');
      await db.customStatement('PRAGMA user_version=1');
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      finance = FinanceRepository(db, clock: () => testNow);
      final repo = BackupRepository(finance);
      expect((await repo.capture()).data, expected);
      expect(
        (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
          'user_version',
        ),
        2,
      );
      await repo.restore(await repo.capture());
      await repo.reset('GMT');
      expect(await repo.purgePending, isTrue);
      await db.close();
      db = AppDatabase(NativeDatabase(file));
      finance = FinanceRepository(db, clock: () => testNow);
      final manager = BackupManager(BackupRepository(finance), TestFiles());
      await manager.purgePending();
      expect(await manager.repository.purgePending, isFalse);
      expect((await manager.repository.capture()).assets, 0);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
