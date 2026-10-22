import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/main.dart' as app;
import 'package:finance_app/ui/bills_page.dart';
import 'package:finance_app/ui/categories_page.dart';
import 'package:finance_app/ui/finance_widgets.dart';
import 'package:finance_app/ui/history_page.dart';
import 'package:finance_app/ui/memos_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'asset_flow_test.dart' show ready, reveal, tap, enter;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Stage 3 Android bills, category migration, memos, locales and independence',
    (tester) async {
      app.main();
      await ready(
        tester,
        () => find.byKey(const Key('open-bills')).evaluate().isNotEmpty,
      );
      final c = tester.widget<FinanceApp>(find.byType(FinanceApp)).controller;
      await c.repository.setLanguage(AppLanguage.english);
      await c.repository.setAppearance(Appearance.light);
      await ready(tester, () => c.settings!.language == AppLanguage.english);
      expect(c.ledger!.bills, isEmpty);
      expect(c.ledger!.memos, isEmpty);
      final asset = await c.repository.createProject(
        const ProjectDraft(
          name: 'QA_NATIVE_ASSET',
          type: 'asset',
          initialMinor: 100000,
        ),
      );
      final independent = await c.repository.createProject(
        const ProjectDraft(name: 'QA_NATIVE_INCOME', type: 'income_log'),
      );
      final now = bookNow(c);
      await c.repository.saveRecord(independent, amount: 777, moment: now);
      await ready(tester, () => c.totalAssets == 100000);
      final originalBalances = c.workspace!.balances.toList();
      await tap(tester, find.byKey(const Key('open-bills')));
      await tap(tester, find.byKey(const Key('previous-month')));
      final d = DateTime.utc(now.date.year, now.date.month - 1, 1);
      final month = monthKey(d.year, d.month);
      await tap(tester, find.byKey(const Key('add-bill')));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('business-date')))
            .controller!
            .text,
        defaultEntryDate(d.year, d.month, now.date).toString(),
      );
      await enter(tester, 'bill-amount', '100.00');
      await tap(tester, find.byType(DropdownButtonFormField<String>).last);
      await tap(tester, find.text('Food').last);
      await enter(tester, 'bill-note', 'native_bill_note');
      final save = find.byKey(const Key('save-bill'));
      await reveal(tester, save);
      await tester.tap(save);
      await tester.tap(save);
      await ready(tester, () => c.ledger!.bills.length == 1);
      final id = c.ledger!.bills.single.id;
      expect(c.ledger!.bills.single.businessDate.startsWith(month), isTrue);
      expect(c.workspace!.balances, originalBalances);
      await tap(tester, find.byKey(const Key('chart-income')));
      expect(find.text('No transactions in this selection.'), findsOneWidget);
      await tap(tester, find.byKey(const Key('filter-all')));
      await tap(tester, find.byKey(const Key('open-annual')));
      expect(find.byType(AnnualBillsPage), findsOneWidget);
      expect(c.ledger!.total(c.ledger!.bills, 'expense'), 10000);
      Navigator.of(tester.element(find.byType(AnnualBillsPage))).pop();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(Key('bill-$id')));
      await tap(tester, find.byKey(const Key('bill-type')));
      await tap(tester, find.text('Income').last);
      await enter(tester, 'bill-amount', '150.00');
      await enter(tester, 'business-date', '2024-02-29');
      await tap(tester, find.byKey(const Key('save-bill')));
      expect(c.ledger!.bills.single.type, 'expense');
      await tap(tester, find.byType(DropdownButtonFormField<String>).last);
      await tap(tester, find.text('Salary').last);
      await tap(tester, find.byKey(const Key('save-bill')));
      await ready(tester, () => c.ledger!.bills.single.type == 'income');
      expect(c.ledger!.month(month), isEmpty);
      expect(c.ledger!.total(c.ledger!.month('2024-02'), 'income'), 15000);
      expect(
        c.ledger!.total(
          c.ledger!.bills.where((b) => b.businessDate.startsWith('2024-')),
          'income',
        ),
        15000,
      );
      expect(c.totalAssets, 100000);
      debugPrint(
        'STAGE3: T02/T07/T08/T09 historical default, rapid save, direction/category guard, leap-day cross-year move and annual totals passed.',
      );

      Navigator.of(tester.element(find.byType(BillsPage))).pop();
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('open-bills')));
      await tap(tester, find.byKey(const Key('open-categories')));
      await tap(tester, find.byKey(const Key('new-category')));
      await enter(tester, 'category-name', 'Native custom category');
      await tap(tester, find.byKey(const Key('category-type')));
      await tap(tester, find.text('Income').last);
      await tap(tester, find.byKey(const Key('save-category')));
      await ready(
        tester,
        () => c.ledger!.categories.any(
          (t) => t.customName == 'Native custom category',
        ),
      );
      final target = c.ledger!.categories.firstWhere(
        (t) => t.customName == 'Native custom category',
      );
      final originalCategory = c.ledger!.category(
        c.ledger!.bills.single.categoryId,
      )!;
      await tap(tester, find.byKey(Key('category-${originalCategory.id}')));
      await enter(tester, 'category-name', 'Native renamed salary');
      await tap(tester, find.byType(SwitchListTile));
      await tap(tester, find.byKey(const Key('save-category')));
      await ready(
        tester,
        () => !c.ledger!.category(originalCategory.id)!.isActive,
      );
      expect(c.ledger!.bills.single.categoryId, originalCategory.id);
      await tap(tester, find.byKey(Key('category-${originalCategory.id}')));
      // Select destination in the actual migration dialog.
      await tap(tester, find.text('Delete'));
      await tap(tester, find.byType(DropdownButtonFormField<String>).last);
      await tap(tester, find.text('Native custom category').last);
      await tap(tester, find.byKey(const Key('confirm-move-category')));
      await ready(
        tester,
        () => c.ledger!.category(originalCategory.id) == null,
      );
      expect(c.ledger!.bills.single.categoryId, target.id);
      expect(c.ledger!.bills.single.amountMinor, 15000);
      expect((await c.repository.watchHistory('bill', id).first).length, 2);
      debugPrint(
        'STAGE3: T15 category creation, rename, deactivate and atomic migrate/delete passed.',
      );
      // Restore built-in category data through the repository while preserving its ID.
      await c.repository.database
          .into(c.repository.database.categories)
          .insert(originalCategory);
      await c.repository.saveBill(
        id: id,
        type: 'income',
        amount: 15000,
        categoryId: originalCategory.id,
        moment: BusinessMoment(BusinessDate(2024, 2, 29), '12:00'),
      );
      await c.repository.deleteCategory(target.id);
      Navigator.of(tester.element(find.byType(CategoriesPage))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(BillsPage))).pop();
      await tester.pumpAndSettle();
      await c.repository.clearHistory('bill', id);
      expect(
        (await c.repository.watchLedger().first).bills.single.amountMinor,
        15000,
      );
      await c.repository.deleteBill(id);
      expect(await c.repository.watchHistory('bill', id).first, isEmpty);
      expect(c.workspace!.balances, originalBalances);
      expect(c.workspace!.amount(c.workspace!.project(independent)!), 777);
      debugPrint(
        'STAGE3: full T02 and T04 bill history deletion and business deletion passed; asset/independent entry unchanged.',
      );

      await tap(tester, find.byKey(const Key('open-memos')));
      await tap(tester, find.byKey(const Key('new-memo')));
      await enter(tester, 'memo-title', 'Native 原文');
      await enter(tester, 'memo-body', 'Review ETF');
      await enter(tester, 'business-date', '2024-02-29');
      await enter(tester, 'memo-tags', '基金, ETF');
      await tap(tester, find.byKey(const Key('save-memo')));
      await ready(tester, () => c.ledger!.memos.length == 1);
      final memo = c.ledger!.memos.single.id;
      await tap(tester, find.byKey(const Key('memo-tag-基金')));
      await enter(tester, 'memo-search', 'missing');
      expect(find.text('No memos match this selection.'), findsOneWidget);
      await enter(tester, 'memo-search', 'etf');
      await tap(tester, find.byKey(Key('memo-$memo')));
      await enter(tester, 'memo-body', 'Updated plan');
      await tap(tester, find.byKey(const Key('save-memo')));
      await ready(tester, () => c.ledger!.memos.single.body == 'Updated plan');
      await tap(tester, find.byKey(Key('memo-$memo')));
      await tap(tester, find.text('Edit history'));
      expect(find.textContaining('Updated plan'), findsOneWidget);
      await tap(tester, find.text('Clear edit history'));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      expect(await c.repository.watchHistory('memo', memo).first, isEmpty);
      Navigator.of(tester.element(find.byType(HistoryPage))).pop();
      await tester.pumpAndSettle();
      for (final language in [
        AppLanguage.simplifiedChinese,
        AppLanguage.traditionalChinese,
        AppLanguage.english,
      ]) {
        await c.repository.setLanguage(language);
        await ready(tester, () => c.settings!.language == language);
        expect(
          tester
              .widget<TextFormField>(find.byKey(const Key('memo-title')))
              .controller!
              .text,
          'Native 原文',
        );
      }
      await c.repository.setAppearance(Appearance.dark);
      await ready(tester, () => c.settings!.appearance == Appearance.dark);
      expect(
        Theme.of(tester.element(find.byType(MemoEditor))).brightness,
        Brightness.dark,
      );
      await tap(tester, find.text('Delete'));
      await tap(tester, find.byKey(const Key('confirm-delete')));
      await ready(tester, () => c.ledger!.memos.isEmpty);
      expect(c.totalAssets, 100000);
      Navigator.of(tester.element(find.byType(MemosPage))).pop();
      await tester.pumpAndSettle();
      await c.repository.deleteProject(asset);
      await c.repository.deleteProject(independent);
      await c.repository.setLanguage(AppLanguage.simplifiedChinese);
      await c.repository.setAppearance(Appearance.light);
      await ready(
        tester,
        () => c.totalAssets == 0 && c.workspace!.projects.length == 9,
      );
      expect(c.ledger!.bills, isEmpty);
      expect(c.ledger!.memos, isEmpty);
      debugPrint(
        'STAGE3: T04/T15 memo combined filters, edits/history/delete, three locales, dark mode and cleanup passed.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
