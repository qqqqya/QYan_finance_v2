import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/main.dart' as app;
import 'package:finance_app/ui/finance_widgets.dart';
import 'package:finance_app/ui/record_editor.dart';
import 'package:finance_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

Future<void> ready(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (condition()) {
      await tester.pumpAndSettle();
      return;
    }
  }
  fail('Android UI/data did not reach the expected state within 30 seconds.');
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    final root = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    tester.state<ScrollableState>(root).position.jumpTo(0);
    await tester.pumpAndSettle();
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        250,
        maxScrolls: 40,
        scrollable: root,
      );
    }
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await reveal(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await reveal(tester, field);
  await tester.enterText(field, value);
  await tester.pump();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Stage 2 Android projects, snapshots, audit, charts, drag and locales',
    (tester) async {
      app.main();
      await ready(
        tester,
        () => find.byKey(const Key('new-project')).evaluate().isNotEmpty,
      );
      final c = tester.widget<FinanceApp>(find.byType(FinanceApp)).controller;
      await c.repository.setLanguage(AppLanguage.english);
      await ready(tester, () => c.settings!.language == AppLanguage.english);
      expect(c.totalAssets, 0);
      expect(c.workspace!.projects, hasLength(9));
      debugPrint('STAGE2: T01 initialized zero data.');
      final today = bookNow(c).date;
      String day(int daysAgo) {
        final d = DateTime.utc(
          today.year,
          today.month,
          today.day,
        ).subtract(Duration(days: daysAgo));
        return BusinessDate(d.year, d.month, d.day).toString();
      }

      Future<String> create(String name, String type, String amount) async {
        await tap(tester, find.byKey(const Key('new-project')));
        await enter(tester, 'project-name', name);
        if (type != 'asset') {
          await tap(tester, find.byKey(const Key('project-type')));
          await tap(
            tester,
            find.text(switch (type) {
              'liability' => 'Liability',
              'income_log' => 'Independent income',
              _ => 'Independent expense',
            }).last,
          );
        }
        if (isBalanceType(type)) {
          await enter(tester, 'initial-amount', amount);
          await enter(tester, 'business-date', day(10));
          await enter(tester, 'business-time', '12:00');
        }
        await tap(tester, find.byKey(const Key('save-project')));
        await ready(
          tester,
          () => c.workspace!.projects.any((p) => p.customName == name),
        );
        return c.workspace!.projects.firstWhere((p) => p.customName == name).id;
      }

      Future<void> open(String id) =>
          tap(tester, find.byKey(Key('project-$id')));
      Future<void> add(
        String amount,
        String date,
        String note, {
        bool doubleSave = false,
      }) async {
        await tap(tester, find.byKey(const Key('add-record')));
        await enter(tester, 'record-amount', amount);
        await enter(tester, 'business-date', date);
        await enter(tester, 'business-time', '12:00');
        await enter(tester, 'record-note', note);
        final save = find.byKey(const Key('save-record'));
        await reveal(tester, save);
        await tester.tap(save);
        if (doubleSave) await tester.tap(save);
        await ready(tester, () => find.byType(RecordEditor).evaluate().isEmpty);
      }

      Future<void> back() async {
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
      }

      final asset = await create('Native asset', 'asset', '1000.01');
      await open(asset);
      await add('900.01', day(15), 'Earlier balance');
      expect(c.workspace!.amount(c.workspace!.project(asset)!), 100001);
      await add('1200.02', day(5), 'Same minute one');
      final editedId = c.workspace!.balances
          .firstWhere((r) => r.note == 'Same minute one')
          .id;
      final orderKey = c.workspace!.balances
          .firstWhere((r) => r.id == editedId)
          .orderKey;
      await add('1300.03', day(5), 'Same minute two');
      final latestId = c.workspace!.balances
          .firstWhere((r) => r.note == 'Same minute two')
          .id;
      expect(c.workspace!.amount(c.workspace!.project(asset)!), 130003);
      await tap(tester, find.byKey(Key('record-$editedId')));
      await enter(tester, 'record-amount', '1250.04');
      await enter(tester, 'record-note', 'Edited note');
      await tap(tester, find.byKey(const Key('save-record')));
      await ready(
        tester,
        () => c.workspace!.balances.any(
          (r) => r.id == editedId && r.balanceMinor == 125004,
        ),
      );
      expect(c.workspace!.amount(c.workspace!.project(asset)!), 130003);
      expect(
        c.workspace!.balances.firstWhere((r) => r.id == editedId).orderKey,
        orderKey,
      );
      final oldId = c.workspace!.balances
          .firstWhere((r) => r.note == 'Earlier balance')
          .id;
      await tap(tester, find.byKey(Key('record-$oldId')));
      await enter(tester, 'business-date', day(2));
      await enter(tester, 'record-note', 'Moved date');
      await tap(tester, find.byKey(const Key('save-record')));
      await ready(
        tester,
        () => c.workspace!.amount(c.workspace!.project(asset)!) == 90001,
      );
      debugPrint(
        'STAGE2: T03 earlier backfill, same-minute keys, money/note/date editing passed.',
      );
      await tap(tester, find.byKey(Key('record-$oldId')));
      await tap(tester, find.text('Edit history'));
      expect(find.textContaining('Moved date'), findsWidgets);
      await tap(tester, find.text('Clear edit history'));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(
        tester,
        () => find.text('No edits recorded.').evaluate().isNotEmpty,
      );
      expect(c.workspace!.amount(c.workspace!.project(asset)!), 90001);
      await back();
      await tap(tester, find.text('Delete').last);
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(
        tester,
        () => c.workspace!.amount(c.workspace!.project(asset)!) == 130003,
      );
      await tap(tester, find.byKey(Key('record-$latestId')));
      await tap(tester, find.text('Delete').last);
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(
        tester,
        () => c.workspace!.amount(c.workspace!.project(asset)!) == 125004,
      );
      await tap(tester, find.byKey(const Key('clear-records')));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(
        tester,
        () => c.workspace!.balances.every((r) => r.projectId != asset),
      );
      expect(c.workspace!.amount(c.workspace!.project(asset)!), 0);
      await add('1000.00', day(1), 'Re-established balance');
      await back();
      debugPrint(
        'STAGE2: T04 history clear preserves money; record deletion and clear recompute correctly.',
      );
      final secondAsset = await create(
        'Native second asset',
        'asset',
        '2000.00',
      );
      final debt = await create('Native debt', 'liability', '500.00');
      final income = await create('Native income', 'income_log', '0');
      await open(income);
      await add('333.33', day(1), 'One income only', doubleSave: true);
      await back();
      final expense = await create('Native expense', 'expense_log', '0');
      await open(expense);
      await add('7.77', day(1), 'Independent expense');
      await back();
      expect(c.totalAssets, 300000);
      expect(c.totalLiabilities, 50000);
      expect(c.netAssets, 250000);
      expect(
        c.workspace!.entries.where((r) => r.projectId == income),
        hasLength(1),
      );
      expect(
        await c.repository.database.select(c.repository.database.bills).get(),
        isEmpty,
      );
      debugPrint(
        'STAGE2: T05 four project types, totals, independent logs; T21 rapid save passed. Full T02 deferred.',
      );
      await tap(tester, find.byKey(const Key('open-overview')));
      await reveal(tester, find.text('Asset composition'));
      expect(find.text('Native asset'), findsOneWidget);
      expect(find.text('Native second asset'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('balance-trend-plot')));
      expect(find.byKey(const Key('balance-trend-plot')), findsOneWidget);
      expect(find.text('Amount · CNY'), findsOneWidget);
      await tap(tester, find.text('12 months'));
      await back();
      final first = c.projects[0].id, second = c.projects[1].id;
      await reveal(tester, find.byKey(Key('project-$first')));
      final target = tester.getCenter(find.byKey(Key('project-$second')));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Key('drag-project-$first'))),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Delete project'), findsNothing);
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 250));
      await gesture.up();
      await ready(tester, () => c.projects.first.id == second);
      expect(
        (await c.repository.watchWorkspace().first).projects.first.id,
        second,
      );
      debugPrint(
        'STAGE2: T10 multi-project legend/trend and T11 native grid long-press/drop passed.',
      );
      for (final language in [
        AppLanguage.simplifiedChinese,
        AppLanguage.traditionalChinese,
        AppLanguage.english,
      ]) {
        await c.repository.setLanguage(language);
        await ready(tester, () => c.settings!.language == language);
        await open(asset);
        expect(find.text('Native asset'), findsOneWidget);
        await tap(tester, find.byKey(const Key('add-record')));
        final s = AppLocalizations.of(
          tester.element(find.byType(RecordEditor)),
        )!;
        expect(find.text('${s.balanceAmount} · CNY'), findsOneWidget);
        await back();
        await back();
      }
      await open(secondAsset);
      await tap(tester, find.byKey(const Key('edit-project')));
      await enter(tester, 'project-name', 'Native renamed');
      await enter(tester, 'project-note', 'Project note retained');
      await tap(tester, find.byKey(const Key('save-project')));
      await ready(
        tester,
        () => c.workspace!.project(secondAsset)!.customName == 'Native renamed',
      );
      expect(find.text('Project note retained'), findsOneWidget);
      await tap(tester, find.byKey(const Key('delete-project')));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(tester, () => c.workspace!.project(secondAsset) == null);
      expect(c.totalAssets, 100000);
      // Remove both a default and custom project through their detail actions.
      await open(first);
      await tap(tester, find.byKey(const Key('delete-project')));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(tester, () => c.workspace!.project(first) == null);
      expect(c.workspace!.project(debt), isNotNull);
      expect(tester.takeException(), isNull);
      debugPrint(
        'STAGE2: project metadata, localized forms, custom/default deletion and cascades passed.',
      );
    },
  );
}
