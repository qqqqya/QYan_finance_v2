import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/ui/app_theme.dart';
import 'package:finance_app/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'ledger_widgets_test.dart' show tap, updated, reveal;

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  setUpAll(tz.initializeTimeZones);
  for (final color in ThemeColor.values) {
    for (final mode in [Brightness.light, Brightness.dark]) {
      test('${color.name} $mode theme provides readable paired colors', () {
        final theme = buildAppTheme(mode, color), s = theme.colorScheme;
        for (final pair in [
          (s.onSurface, s.surface),
          (s.onSurfaceVariant, s.surfaceContainerLow),
          (s.onPrimary, s.primary),
          (s.onPrimaryContainer, s.primaryContainer),
        ]) {
          expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        }
      });
    }
  }
  late AppDatabase db;
  late FinanceController c;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final f = FinanceRepository(
      db,
      clock: () => DateTime.utc(2026, 10, 23, 12),
    );
    await f.initialize('GMT');
    await f.setLanguage(AppLanguage.english);
    c = FinanceController(f);
    await c.start();
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  testWidgets(
    'entry button is visible immediately and stays visible after scrolling; annual chart has no redundant monthly cards',
    (tester) async {
      final category = c.ledger!.categories.firstWhere(
        (r) => r.nameKey == 'food',
      );
      await tester.runAsync(() async {
        await c.repository.saveBill(
          type: 'expense',
          amount: 1234,
          categoryId: category.id,
          moment: BusinessMoment(BusinessDate(2026, 10, 1), '12:00'),
        );
        await c.refreshAfterRestore();
      });
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-bills')));
      expect(find.byKey(const Key('add-bill')).hitTestable(), findsOneWidget);
      final position = tester.getRect(find.byKey(const Key('add-bill')));
      await tester.drag(find.byType(ListView).last, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(const Key('add-bill'))), position);
      await tap(tester, find.byKey(const Key('open-annual')));
      await reveal(tester, find.byKey(const Key('annual-plot')));
      expect(find.byKey(const Key('annual-plot')), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.text('2026-01'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'card long press opens menu, cancel preserves everything, confirmed delete cascades only its facts and histories',
    (tester) async {
      final p = c.workspace!.projects.firstWhere((p) => p.type == 'asset');
      final record = c.workspace!.balances.firstWhere(
        (r) => r.projectId == p.id,
      );
      await tester.runAsync(() async {
        await c.repository.saveRecord(
          p.id,
          recordId: record.id,
          amount: 1234,
          moment: BusinessMoment(BusinessDate(2026, 10, 1), '12:00'),
          note: 'edited record',
        );
        await c.repository.saveBill(
          type: 'expense',
          amount: 100,
          categoryId: c.ledger!.categories
              .firstWhere((r) => r.nameKey == 'food')
              .id,
          moment: BusinessMoment(BusinessDate(2026, 10, 1), '12:00'),
        );
        final ids = c.projects.map((p) => p.id).toList();
        await c.repository.reorderProjects([
          p.id,
          ...ids.where((id) => id != p.id),
        ]);
        await c.refreshAfterRestore();
      });
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      final card = find.byKey(Key('project-body-${p.id}'));
      await reveal(tester, card);
      final handle = find.byKey(Key('drag-project-${p.id}'));
      expect(
        tester.getRect(handle).top -
            tester.getRect(find.byKey(Key('project-menu-${p.id}'))).bottom,
        greaterThan(48),
      );
      await tester.longPress(card);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-delete-project')), findsOneWidget);
      await tap(tester, find.byKey(const Key('menu-delete-project')));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 records and 1 edit histories'),
        findsOneWidget,
      );
      await tap(tester, find.text('Cancel'));
      expect(c.workspace!.project(p.id), isNotNull);
      expect(c.totalAssets, 1234);
      await tap(tester, find.byKey(Key('project-menu-${p.id}')));
      await tap(tester, find.byKey(const Key('menu-delete-project')));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 15)),
      );
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await updated(tester, c, () => c.workspace!.project(p.id) == null);
      expect(c.totalAssets, 0);
      expect(c.ledger!.bills, hasLength(1));
      expect(
        (await tester.runAsync(
          () => c.repository.watchHistory('balanceRecord', record.id).first,
        ))!,
        isEmpty,
      );
      expect(find.byType(HomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ordinary body scroll never starts sorting or opens the action menu',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: c));
      await tester.pumpAndSettle();
      final ids = c.projects.map((p) => p.id).toList();
      final first = find.byKey(Key('project-body-${ids.first}'));
      await reveal(tester, first);
      await tester.timedDrag(
        first,
        const Offset(0, -250),
        const Duration(milliseconds: 150),
      );
      await tester.pumpAndSettle();
      expect(c.projects.map((p) => p.id), ids);
      expect(find.byKey(const Key('menu-delete-project')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
