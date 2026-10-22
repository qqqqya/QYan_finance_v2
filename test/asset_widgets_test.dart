import 'dart:async';

import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/workspace.dart';
import 'package:finance_app/core/money.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/ui/project_detail_page.dart';
import 'package:finance_app/ui/record_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> updated(
  WidgetTester tester,
  FinanceController controller,
  bool Function() condition,
) async {
  await tester.runAsync(() async {
    if (condition()) return;
    final completer = Completer<void>();
    void listener() {
      if (condition() && !completer.isCompleted) completer.complete();
    }

    controller.addListener(listener);
    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } finally {
      controller.removeListener(listener);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;
  late FinanceController controller;
  setUpAll(tz.initializeTimeZones);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final repo = FinanceRepository(
      db,
      clock: () => DateTime.utc(2026, 10, 22, 12),
    );
    await repo.initialize('GMT');
    await repo.setLanguage(AppLanguage.english);
    controller = FinanceController(repo);
    await controller.start();
  });
  tearDown(() async {
    controller.dispose();
    await db.close();
  });

  testWidgets(
    'custom category matching a built-in key stays literal after language switch',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const Key('new-project')));
      await tester.enterText(
        find.byKey(const Key('project-name')),
        'Literal category',
      );
      await tester.enterText(find.byKey(const Key('custom-category')), 'bank');
      final save = find.byKey(const Key('save-project'));
      if (save.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          save,
          250,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await tap(tester, save);
      await updated(
        tester,
        controller,
        () => controller.workspace!.projects.any(
          (p) => p.customName == 'Literal category',
        ),
      );
      final project = controller.workspace!.projects.firstWhere(
        (p) => p.customName == 'Literal category',
      );
      await tap(tester, find.byKey(Key('project-${project.id}')));
      expect(find.text('Asset · bank'), findsOneWidget);
      await controller.repository.setLanguage(AppLanguage.simplifiedChinese);
      await updated(
        tester,
        controller,
        () => controller.settings!.language == AppLanguage.simplifiedChinese,
      );
      expect(find.text('资产 · bank'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'T21 two rapid save taps add exactly one entry and immediately refresh the detail',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      final project = controller.projects.firstWhere(
        (p) => p.type == 'income_log',
      );
      await tap(tester, find.byKey(Key('project-${project.id}')));
      await tap(tester, find.byKey(const Key('add-record')));
      await tester.enterText(find.byKey(const Key('record-amount')), '0.01');
      await tester.enterText(find.byKey(const Key('record-note')), 'One only');
      final save = find.byKey(const Key('save-record'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.tap(save);
      await updated(
        tester,
        controller,
        () =>
            controller.workspace!.entries.any((r) => r.projectId == project.id),
      );
      expect(
        controller.workspace!.entries.where((r) => r.projectId == project.id),
        hasLength(1),
      );
      expect(find.byType(ProjectDetailPage), findsOneWidget);
      expect(find.text('One only'), findsOneWidget);
      expect(find.text('¥0.01'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid amount stays in the form; unsaved Back can continue or discard',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      final project = controller.projects.firstWhere(
        (p) => p.type == 'expense_log',
      );
      await tap(tester, find.byKey(Key('project-${project.id}')));
      await tap(tester, find.byKey(const Key('add-record')));
      await tester.enterText(find.byKey(const Key('record-amount')), '0');
      await tap(tester, find.byKey(const Key('save-record')));
      expect(find.byType(RecordEditor), findsOneWidget);
      expect(controller.workspace!.entries, isEmpty);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tap(tester, find.text('Keep editing'));
      expect(find.byType(RecordEditor), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tap(tester, find.text('Discard'));
      expect(find.byType(ProjectDetailPage), findsOneWidget);
      expect(controller.workspace!.entries, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('T11 home long press only drags; drop persists the grid order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(FinanceApp(controller: controller));
    await tester.pumpAndSettle();
    final first = controller.projects[0].id, second = controller.projects[1].id;
    final source = tester.getCenter(find.byKey(Key('project-$first')));
    final target = tester.getCenter(find.byKey(Key('project-$second')));
    final gesture = await tester.startGesture(source);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(ProjectDetailPage), findsNothing);
    expect(find.text('Delete project'), findsNothing);
    await gesture.moveTo(target);
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await updated(
      tester,
      controller,
      () => controller.projects.first.id == second,
    );
    expect(
      (await tester.runAsync(
        () => controller.repository.watchWorkspace().first,
      ))!.projects.first.id,
      second,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('T10 overview zero state works at 320dp and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1600);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(FinanceApp(controller: controller));
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('open-overview')));
    expect(find.text('No positive balances to display.'), findsWidgets);
    expect(find.byKey(const Key('balance-trend-plot')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'T06/T10 positive single-point chart, large totals and long legends fit narrow large-text screens',
    (tester) async {
      const longName =
          'Long asset name to verify full legend wrapping without truncation';
      await tester.runAsync(() async {
        await controller.repository.createProject(
          const ProjectDraft(
            name: longName,
            type: 'asset',
            initialMinor: maxRecordMinor,
          ),
        );
        await controller.repository.createProject(
          const ProjectDraft(
            name: 'Second asset',
            type: 'asset',
            initialMinor: maxRecordMinor,
          ),
        );
      });
      await updated(
        tester,
        controller,
        () => controller.totalAssets == maxRecordMinor * 2,
      );
      tester.view.physicalSize = const Size(640, 1800);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('total-assets'))).data,
        '¥19,999,999,999.98',
      );
      await tap(tester, find.byKey(const Key('open-overview')));
      final root = find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text(longName),
        250,
        scrollable: root,
      );
      await tester.pumpAndSettle();
      expect(find.text(longName), findsOneWidget);
      expect(find.text('50.00%'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('balance-trend-plot')),
        250,
        scrollable: root,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('balance-trend-plot')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
