import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/main.dart' as app;
import 'package:finance_app/services/backup_files.dart';
import 'package:finance_app/services/backup_manager.dart';
import 'package:finance_app/ui/app_theme.dart';
import 'package:finance_app/ui/bill_editor.dart';
import 'package:finance_app/ui/bills_page.dart';
import 'package:finance_app/ui/finance_widgets.dart';
import 'package:finance_app/ui/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'asset_flow_test.dart' show ready, reveal, tap;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android refinements: direct bill choices, annual, isolated reorder/menu and persisted four palettes',
    (tester) async {
      if (!const bool.fromEnvironment('FINANCE_QA_DISPOSABLE')) {
        fail('Dedicated disposable QA emulator only.');
      }
      app.main();
      await ready(
        tester,
        () => find.byKey(const Key('open-bills')).evaluate().isNotEmpty,
      );
      final c = tester.widget<FinanceApp>(find.byType(FinanceApp)).controller;
      final manager = BackupManager(
        BackupRepository(c.repository),
        AndroidBackupFiles(),
      );
      await manager.reset('GMT');
      await c.refreshAfterRestore();
      await c.setLanguage(AppLanguage.english);
      await c.setAppearance(Appearance.light);
      await ready(tester, () => c.settings!.language == AppLanguage.english);
      expect(c.projects.take(2).map((p) => p.nameKey), [
        'largeExpense',
        'liability',
      ]);
      await tap(tester, find.byKey(const Key('open-bills')));
      expect(find.byKey(const Key('add-bill')).hitTestable(), findsOneWidget);
      await tap(tester, find.byKey(const Key('previous-month')));
      final month =
          tester.widget<TextButton>(find.byKey(const Key('choose-month'))).child
              as Text;
      final selectedMonth = month.data!;
      await tap(tester, find.byKey(const Key('add-bill')));
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('business-date')))
            .controller!
            .text
            .startsWith(selectedMonth),
        isTrue,
      );
      await tap(tester, find.byKey(const Key('bill-type-income')));
      final salary = c.ledger!.categories.firstWhere(
        (r) => r.nameKey == 'salary',
      );
      final food = c.ledger!.categories.firstWhere((r) => r.nameKey == 'food');
      await tap(tester, find.byKey(Key('bill-category-option-${salary.id}')));
      await tap(tester, find.byKey(const Key('bill-type-expense')));
      expect(
        find.byKey(Key('bill-category-option-${salary.id}')),
        findsNothing,
      );
      await tap(tester, find.byKey(Key('bill-category-option-${food.id}')));
      await reveal(tester, find.byKey(const Key('bill-amount')));
      await tester.enterText(find.byKey(const Key('bill-amount')), '12.34');
      await tap(tester, find.byKey(const Key('save-bill')));
      await ready(
        tester,
        () =>
            find.byType(BillEditor).evaluate().isEmpty &&
            c.ledger!.bills.length == 1,
      );
      expect(
        c.ledger!.bills.single.businessDate.startsWith(selectedMonth),
        isTrue,
      );
      await tap(tester, find.byKey(const Key('open-annual')));
      await reveal(tester, find.byKey(const Key('annual-plot')));
      expect(find.byType(Card), findsOneWidget);
      Navigator.of(tester.element(find.byType(AnnualBillsPage))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(BillsPage))).pop();
      await tester.pumpAndSettle();
      debugPrint(
        'REFINEMENT: fixed entry, direct direction/category with clearing, historical month and compact annual chart passed.',
      );

      final id = await c.repository.createProject(
        ProjectDraft(
          name: 'QA_menu_asset',
          type: 'asset',
          initialMinor: 5000,
          initialMoment: bookNow(c),
        ),
      );
      await c.refreshAfterRestore();
      final r = c.workspace!.balances.firstWhere((r) => r.projectId == id);
      await c.repository.saveRecord(
        id,
        recordId: r.id,
        amount: 6000,
        moment: bookNow(c),
        note: 'QA history',
      );
      await c.repository.reorderProjects([
        id,
        ...c.projects.where((p) => p.id != id).map((p) => p.id),
      ]);
      await ready(
        tester,
        () => c.projects.first.id == id && c.totalAssets == 6000,
      );
      final second = c.projects[1].id;
      await reveal(tester, find.byKey(Key('project-$id')));
      await tester.longPress(find.byKey(Key('project-body-$id')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('menu-delete-project')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final target = tester.getCenter(find.byKey(Key('project-$second')));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(Key('drag-project-$id'))),
      );
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.byKey(const Key('menu-delete-project')), findsNothing);
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.up();
      await ready(tester, () => c.projects.first.id == second);
      final savedOrder = c.projects.map((p) => p.id).toList();
      expect(
        (await c.repository.watchWorkspace().first).projects.map((p) => p.id),
        savedOrder,
      );
      await tap(tester, find.byKey(Key('project-menu-$id')));
      await tap(tester, find.byKey(const Key('menu-delete-project')));
      await ready(
        tester,
        () => find.byKey(const Key('confirm-delete')).evaluate().isNotEmpty,
      );
      expect(
        find.textContaining('1 records and 1 edit histories'),
        findsOneWidget,
      );
      await tap(tester, find.text('Cancel'));
      expect(c.totalAssets, 6000);
      await tap(tester, find.byKey(Key('project-menu-$id')));
      await tap(tester, find.byKey(const Key('menu-delete-project')));
      await ready(
        tester,
        () => find.byKey(const Key('confirm-delete')).evaluate().isNotEmpty,
      );
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(tester, () => c.workspace!.project(id) == null);
      expect(c.totalAssets, 0);
      expect(c.ledger!.bills, hasLength(1));
      expect(
        await c.repository.watchHistory('balanceRecord', r.id).first,
        isEmpty,
      );
      debugPrint(
        'REFINEMENT: separate handle drag persists; body long press opens menu; cancel preserves; confirmation cascades records/history and keeps bills.',
      );

      await tap(tester, find.byKey(const Key('open-settings')));
      for (final color in ThemeColor.values) {
        await tap(tester, find.byKey(Key('accent-${color.name}')));
        await ready(tester, () => c.settings!.themeColor == color);
        for (final appearance in [Appearance.light, Appearance.dark]) {
          await tap(tester, find.byKey(Key('theme-${appearance.name}')));
          await ready(tester, () => c.settings!.appearance == appearance);
          final brightness = appearance == Appearance.dark
              ? Brightness.dark
              : Brightness.light;
          expect(
            Theme.of(tester.element(find.byType(SettingsPage)))
                .colorScheme
                .primary,
            buildAppTheme(brightness, color).colorScheme.primary,
          );
          expect((await c.repository.watchSettings().first).themeColor, color);
        }
      }
      final saved = await manager.repository.capture();
      expect(saved.root['schemaVersion'], 2);
      await manager.repository.restore(saved);
      await c.refreshAfterRestore();
      expect((await manager.repository.capture()).data, saved.data);
      debugPrint(
        'REFINEMENT: all four palettes in both modes apply globally and persist; full v2 roundtrip preserves preferences and order.',
      );
      await manager.reset('GMT');
      await c.refreshAfterRestore();
      Navigator.of(tester.element(find.byType(SettingsPage))).pop();
      await tester.pumpAndSettle();
      expect(c.projects.take(2).map((p) => p.nameKey), [
        'largeExpense',
        'liability',
      ]);
      expect(c.projects.every((p) => p.amountMinor == 0), isTrue);
      debugPrint(
        'REFINEMENT: QA reset to zero defaults only; original user emulator untouched.',
      );
    },
  );
}
