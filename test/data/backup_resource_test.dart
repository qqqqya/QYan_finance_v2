import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:uuid/uuid.dart';

import 'backup_workflow_test.dart' show testNow, seedEveryType;

void main() {
  setUpAll(tz.initializeTimeZones);
  test('near-limit complete backup validates and restores 10,000 entries without field loss', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final f = FinanceRepository(db, clock: () => testNow);
    final repo = BackupRepository(f);
    try {
      await f.initialize('Asia/Shanghai');
      await seedEveryType(f);
      final small = await repo.capture();
      const emit = bool.fromEnvironment('FINANCE_WRITE_QA_FIXTURES');
      if (emit) {
        await File('artifacts/verification/stage4-all-types.moneybak')
            .writeAsBytes(small.bytes);
      }
      final project = (await f.watchWorkspace().first).projects.firstWhere(
        (p) => p.type == 'income_log',
      );
      const uuid = Uuid();
      final ms = testNow.millisecondsSinceEpoch;
      await db.batch((b) {
        b.insertAll(
          db.projectEntries,
          List.generate(
            10000,
            (i) => ProjectEntryRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              projectId: project.id,
              amountMinor: i + 1,
              businessDate: '2026-10-20',
              businessTime: '12:00',
              note: 'QA resource record',
            ),
          ),
        );
        final body = 'A' * 19000;
        b.insertAll(
          db.memos,
          List.generate(
            1450,
            (i) => MemoRow(
              id: uuid.v4(),
              createdAtMs: ms,
              updatedAtMs: ms,
              title: 'QA resource memo $i',
              body: body,
              businessDate: '2026-10-20',
              tagsJson: jsonEncode(['QA']),
            ),
          ),
        );
      });
      final large = await repo.capture();
      expect(large.bytes.length, greaterThan(28 * 1024 * 1024));
      expect(large.bytes.length, lessThan(maxBackupBytes));
      expect(large.count('projectEntries'), 10002);
      if (emit) {
        await File('artifacts/verification/stage4-large-fixture.moneybak')
            .writeAsBytes(large.bytes);
      }
      await repo.reset('GMT');
      await repo.restore(large);
      expect((await repo.capture()).data, large.data);
      expect((await repo.recovery())!.assets, 0);
    } finally {
      await db.close();
    }
  });
}
