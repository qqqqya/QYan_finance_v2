import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/services/backup_manager.dart';
import 'package:finance_app/ui/data_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'data/backup_workflow_test.dart' show TestFiles, testNow, seedEveryType;
import 'ledger_widgets_test.dart' show reveal;

Future<void> visible(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 300; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Expected backup UI was not shown: $finder');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);
  late AppDatabase db;
  late FinanceController c;
  late TestFiles files;
  late BackupRepository repo;
  late BackupManager manager;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final f = FinanceRepository(db, clock: () => testNow);
    await f.initialize('GMT');
    await f.setLanguage(AppLanguage.english);
    c = FinanceController(f);
    await c.start();
    repo = BackupRepository(f);
    files = TestFiles();
    manager = BackupManager(repo, files);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          (call) async => 'GMT',
        );
  });
  tearDown(() async {
    c.dispose();
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_timezone'),
          null,
        );
  });
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(FinanceApp(controller: c));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(
        builder: (_) => DataManagementPage(controller: c, manager: manager),
      ),
    );
    await visible(tester, find.text('Current data'));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets(
    'T18 export success uses actual file data, shares directly; failed write never shows success',
    (tester) async {
      await open(tester);
      await tap(tester, find.byKey(const Key('export-backup')));
      await visible(tester, find.text('Backup saved'));
      expect(files.written, isNotNull);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate(
            (w) =>
                w is SelectableText &&
                w.data == 'Finance_backup_2026-10-22_123456.moneybak',
          ),
        ),
        findsOneWidget,
      );
      await tap(tester, find.byKey(const Key('share-export')));
      await tester.pumpAndSettle();
      expect(files.shares, 1);
      await tap(tester, find.byKey(const Key('finish-export')));
      await tester.pumpAndSettle();
      files.failure = PlatformException(code: 'noSpace');
      await tap(tester, find.byKey(const Key('export-backup')));
      await visible(tester, find.text('Operation not completed'));
      expect(find.textContaining('Not enough storage'), findsOneWidget);
      expect(find.text('Backup saved'), findsNothing);
      await tap(tester, find.text('Done'));
      await tester.pumpAndSettle();
      await close(tester);
    },
  );
  testWidgets(
    'T16 preview cancel keeps data; confirmation restores settings and allows deleting private copy',
    (tester) async {
      await tester.runAsync(() async {
        await seedEveryType(c.repository);
        final expected = await repo.capture();
        await repo.reset('GMT');
        await manager.purgePending();
        await c.repository.setLanguage(AppLanguage.english);
        await c.refreshAfterRestore();
        files.imported = expected.bytes;
      });
      await open(tester);
      await tap(tester, find.byKey(const Key('import-backup')));
      await visible(tester, find.text('Restore preview'));
      expect(find.textContaining('ALL current financial'), findsOneWidget);
      await tap(tester, find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.totalAssets, 0);
      expect(await tester.runAsync(() => repo.recovery()), isNull);
      await tap(tester, find.byKey(const Key('import-backup')));
      await visible(tester, find.byKey(const Key('confirm-restore')));
      await tap(tester, find.byKey(const Key('confirm-restore')));
      await visible(tester, find.text('還原完成'));
      expect(c.totalAssets, 33333);
      expect(c.settings!.language, AppLanguage.traditionalChinese);
      await tap(tester, find.text('完成'));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('restore-private-copy')));
      await visible(tester, find.byKey(const Key('confirm-restore')));
      await tap(tester, find.byKey(const Key('confirm-restore')));
      await visible(tester, find.text('Restore complete'));
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('還原完成'), findsNothing);
      expect(c.totalAssets, 0);
      await tap(tester, find.text('Done'));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('restore-private-copy')));
      await visible(tester, find.byKey(const Key('confirm-restore')));
      await tap(tester, find.byKey(const Key('confirm-restore')));
      await visible(tester, find.text('還原完成'));
      expect(find.text('完成'), findsOneWidget);
      expect(find.text('Restore complete'), findsNothing);
      await tap(tester, find.text('完成'));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('delete-private-copy')));
      await visible(tester, find.byKey(const Key('confirm-delete')));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await visible(tester, find.text('暫無還原副本。'));
      expect(c.totalAssets, 33333);
      await close(tester);
    },
  );
  testWidgets(
    'T20 factory reset cancellation preserves data; confirm resets to zero and system settings',
    (tester) async {
      await tester.runAsync(() async {
        await seedEveryType(c.repository);
        await c.repository.setLanguage(AppLanguage.english);
        await c.refreshAfterRestore();
      });
      await open(tester);
      await tap(tester, find.byKey(const Key('factory-reset')));
      await visible(tester, find.byKey(const Key('confirm-reset')));
      await tap(tester, find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(c.totalAssets, 33333);
      await tap(tester, find.byKey(const Key('factory-reset')));
      await visible(tester, find.byKey(const Key('confirm-reset')));
      await tap(tester, find.byKey(const Key('confirm-reset')));
      await visible(tester, find.text('Factory reset complete'));
      expect(c.totalAssets, 0);
      expect(c.settings!.language, AppLanguage.system);
      expect(files.purges, 1);
      await tap(tester, find.text('Done'));
      await tester.pumpAndSettle();
      await close(tester);
    },
  );
  testWidgets(
    'data management and export dialog fit 320dp and 200 percent text in dark mode',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1800);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(() async {
        await c.repository.setAppearance(Appearance.dark);
        await c.refreshAfterRestore();
      });
      await open(tester);
      await tap(tester, find.byKey(const Key('export-backup')));
      await visible(tester, find.byKey(const Key('finish-export')));
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const Key('finish-export')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await close(tester);
    },
  );
}
