import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/backup_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'backup_workflow_test.dart' show testNow;

Uint8List bytes(Object value) =>
    Uint8List.fromList(utf8.encode(jsonEncode(value)));
void main() {
  setUpAll(tz.initializeTimeZones);
  for (final name in [
    'v0.0-all-types',
    'v1-stage4-all-types',
    'v1-pre-checksum-sample',
    'v2-theme-all-types',
  ]) {
    test(
      'frozen $name backup -> zero database -> current v2 export preserves every business field',
      () async {
        final raw = await File('test/fixtures/backups/$name.json')
            .readAsBytes();
        final original = jsonDecode(utf8.decode(raw)) as Map<String, dynamic>;
        final doc = BackupDocument.decode(raw, now: testNow);
        final expected = {
          ...original['data'] as Map<String, dynamic>,
          'settings': {
            ...original['data']['settings'] as Map<String, dynamic>,
            'themeColor': original['data']['settings']['themeColor'] ?? 'blue',
          },
        };
        expect(doc.data, expected);
        expect(
          doc.sourceFormatVersion,
          name.startsWith('v0')
              ? 0
              : name.startsWith('v2')
              ? 2
              : 1,
        );
        expect(
          doc.integrityVerified,
          name == 'v1-stage4-all-types' || name.startsWith('v2'),
        );
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final finance = FinanceRepository(db, clock: () => testNow);
          await finance.initialize('GMT');
          final repo = BackupRepository(finance);
          await repo.restore(doc);
          final exported = await repo.capture();
          expect(exported.data, expected);
          expect(exported.root['schemaVersion'], currentBackupFormatVersion);
          expect(exported.root.containsKey('backupFormatVersion'), isFalse);
          expect(
            BackupDocument.decode(
              exported.bytes,
              now: testNow,
            ).integrityVerified,
            isTrue,
          );
          await repo.restore(doc);
          expect((await repo.capture()).data, expected);
        } finally {
          await db.close();
        }
      },
    );
  }
  test('alias v1 is verified before header normalization; conflicting or fractional markers are rejected', () async {
    final original = jsonDecode(
      await File('test/fixtures/backups/v1-stage4-all-types.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    original.remove('checksum');
    original['backupFormatVersion'] = original.remove('schemaVersion');
    final alias = signedBackup(original);
    final doc = BackupDocument.decode(bytes(alias), now: testNow);
    expect(doc.converted, isTrue);
    expect(doc.integrityVerified, isTrue);
    expect(doc.data, {
      ...original['data'] as Map<String, dynamic>,
      'settings': {
        ...original['data']['settings'] as Map<String, dynamic>,
        'themeColor': 'blue',
      },
    });
    for (final bad in [2, 1.0, '1']) {
      final conflict = {
        ...original,
        'schemaVersion': 1,
        'backupFormatVersion': bad,
      };
      expect(
        () =>
            BackupDocument.decode(bytes(signedBackup(conflict)), now: testNow),
        throwsA(isA<BackupFailure>()),
      );
    }
    alias['data']['projects'][0]['note'] = 'tampered';
    expect(
      () => BackupDocument.decode(bytes(alias), now: testNow),
      throwsA(
        isA<BackupFailure>().having((e) => e.code, 'code', 'backupChecksum'),
      ),
    );
  });
  test('future format fails with upgrade instruction; missing modern checksum never falls back to legacy', () async {
    final root = jsonDecode(
      await File('test/fixtures/backups/v1-stage4-all-types.json')
          .readAsString(),
    ) as Map<String, dynamic>;
    root.remove('checksum');
    root['schemaVersion'] = currentBackupFormatVersion + 1;
    expect(
      () => BackupDocument.decode(bytes(signedBackup(root)), now: testNow),
      throwsA(
        isA<BackupFailure>().having(
          (e) => e.code,
          'code',
          'backupFutureVersion',
        ),
      ),
    );
    root['schemaVersion'] = 1;
    root['appVersion'] = backupAppVersion;
    expect(
      () => BackupDocument.decode(bytes(root), now: testNow),
      throwsA(
        isA<BackupFailure>().having((e) => e.code, 'code', 'backupChecksum'),
      ),
    );
  });
  test('v0.0 is not permission to guess missing tables, amounts, IDs or references', () async {
    final source = await File('test/fixtures/backups/v0.0-all-types.json')
        .readAsString();
    for (final mutate in <void Function(Map<String, dynamic>)>[
      (r) => r['data'].remove('categories'),
      (r) => r['data']['bills'][0]['amountMinor'] = 1.1,
      (r) => r['data']['projects'][0].remove('id'),
      (r) => r['data']['bills'][0]['categoryId'] =
          '11111111-1111-4111-8111-111111111111',
      (r) => r.remove('format'),
    ]) {
      final root = jsonDecode(source) as Map<String, dynamic>;
      mutate(root);
      expect(
        () => BackupDocument.decode(bytes(root), now: testNow),
        throwsA(isA<BackupFailure>()),
      );
    }
  });
  test('v2 requires an exact known theme color; v1 never silently accepts new keys', () async {
    final source = await File('test/fixtures/backups/v2-theme-all-types.json')
        .readAsString();
    for (final change in <void Function(Map<String, dynamic>)>[
      (r) => r['data']['settings'].remove('themeColor'),
      (r) => r['data']['settings']['themeColor'] = 'neon',
      (r) => r['data']['settings']['themeColor'] = 1,
      (r) => r['schemaVersion'] = 1,
    ]) {
      final root = jsonDecode(source) as Map<String, dynamic>;
      root.remove('checksum');
      change(root);
      expect(
        () => BackupDocument.decode(bytes(signedBackup(root)), now: testNow),
        throwsA(isA<BackupFailure>()),
      );
    }
  });
}
