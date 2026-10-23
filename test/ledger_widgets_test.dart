import 'dart:async';

import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/ui/bill_editor.dart';
import 'package:finance_app/ui/bills_page.dart';
import 'package:finance_app/ui/memos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> updated(
  WidgetTester tester,
  FinanceController c,
  bool Function() predicate,
) async {
  await tester.runAsync(() async {
    if (predicate()) return;
    final signal = Completer<void>();
    void listener() {
      if (predicate() && !signal.isCompleted) signal.complete();
    }

    c.addListener(listener);
    try {
      await signal.future.timeout(const Duration(seconds: 5));
    } finally {
      c.removeListener(listener);
    }
  });
  await tester.pumpAndSettle();
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
        scrollable: root,
        maxScrolls: 40,
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
  final f = find.byKey(Key(key));
  await reveal(tester, f);
  await tester.enterText(f, value);
  await tester.pump();
}

void main() {
  late AppDatabase db;
  late FinanceController c;
  setUpAll(tz.initializeTimeZones);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final repo = FinanceRepository(
      db,
      clock: () => DateTime.utc(2026, 10, 31, 14),
    );
    await repo.initialize('GMT');
    await repo.setLanguage(AppLanguage.english);
    c = FinanceController(repo);
    await c.start();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });
  testWidgets(
    'T07/T09 historical month UI defaults Sep 30, saves once and syncs filters',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-bills')));
      await tap(tester, find.byKey(const Key('previous-month')));
      await tap(tester, find.byKey(const Key('add-bill')));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('business-date')))
            .controller!
            .text,
        '2026-09-30',
      );
      await enter(tester, 'bill-amount', '12.34');
      await tap(tester, find.text('Food').last);
      await enter(tester, 'bill-note', 'September note');
      final save = find.byKey(const Key('save-bill'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.tap(save);
      await updated(tester, c, () => c.ledger!.bills.length == 1);
      expect(c.ledger!.bills.single.businessDate, '2026-09-30');
      expect(find.byType(BillEditor), findsNothing);
      await tap(tester, find.byKey(const Key('chart-income')));
      expect(find.text('No transactions in this selection.'), findsOneWidget);
      await tap(tester, find.byKey(const Key('filter-all')));
      expect(
        find.byKey(Key('bill-${c.ledger!.bills.single.id}')),
        findsOneWidget,
      );
      await reveal(tester, find.byKey(const Key('choose-month')));
      expect(find.text('2026-09'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'T08 switching bill direction requires a new category and never keeps the old category',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-bills')));
      await tap(tester, find.byKey(const Key('add-bill')));
      await enter(tester, 'bill-amount', '1.00');
      await tap(tester, find.text('Food').last);
      await tap(tester, find.byKey(const Key('bill-type-income')));
      await tap(tester, find.byKey(const Key('save-bill')));
      expect(c.ledger!.bills, isEmpty);
      expect(
        find.text('Choose an active category for this direction.'),
        findsOneWidget,
      );
      expect(find.text('Food'), findsNothing);
      await tap(tester, find.text('Salary').last);
      await tap(tester, find.byKey(const Key('save-bill')));
      await updated(tester, c, () => c.ledger!.bills.isNotEmpty);
      expect(c.ledger!.bills.single.type, 'income');
      expect(
        c.ledger!.category(c.ledger!.bills.single.categoryId)!.type,
        'income',
      );
    },
  );
  testWidgets(
    'T15 memo editor, combined keyword/tag filter, history and localized user content',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-memos')));
      await tap(tester, find.byKey(const Key('new-memo')));
      await enter(tester, 'memo-title', '我的 ETF');
      await enter(tester, 'memo-body', 'Review plan');
      await enter(tester, 'memo-tags', '基金, long-term');
      await tap(tester, find.byKey(const Key('save-memo')));
      await updated(tester, c, () => c.ledger!.memos.length == 1);
      final id = c.ledger!.memos.single.id;
      await tap(tester, find.byKey(const Key('memo-tag-基金')));
      await enter(tester, 'memo-search', 'missing');
      expect(find.text('No memos match this selection.'), findsOneWidget);
      await enter(tester, 'memo-search', 'etf');
      await tap(tester, find.byKey(Key('memo-$id')));
      await enter(tester, 'memo-body', 'Updated plan');
      await tap(tester, find.byKey(const Key('save-memo')));
      await updated(
        tester,
        c,
        () => c.ledger!.memos.single.body == 'Updated plan',
      );
      await c.repository.setLanguage(AppLanguage.traditionalChinese);
      await updated(
        tester,
        c,
        () => c.settings!.language == AppLanguage.traditionalChinese,
      );
      expect(find.text('我的 ETF'), findsOneWidget);
      expect(find.text('理財備忘錄'), findsOneWidget);
      expect(c.totalAssets, 0);
      await tap(tester, find.byKey(Key('memo-$id')));
      await tap(tester, find.text('修改歷史'));
      expect(find.textContaining('Updated plan'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      // Drift defers disposing the last history query to a zero-delay timer.
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
  testWidgets(
    'new bill, annual and memo pages fit 320dp and 200 percent text in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1800);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-bills')));
      expect(tester.takeException(), isNull);
      await tap(tester, find.byKey(const Key('open-annual')));
      expect(find.byType(AnnualBillsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await c.repository.setAppearance(Appearance.dark);
      await updated(tester, c, () => c.settings!.appearance == Appearance.dark);
      expect(
        Theme.of(tester.element(find.byType(AnnualBillsPage))).brightness,
        Brightness.dark,
      );
      Navigator.of(tester.element(find.byType(AnnualBillsPage))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(BillsPage))).pop();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-memos')));
      expect(find.byType(MemosPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
