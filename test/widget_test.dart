import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

// SQLite notifications started during setUp use real asynchronous scheduling.
// Await an observable result instead of advancing only the fake frame clock.
Future<void> waitForController(
  WidgetTester tester,
  FinanceController controller,
  bool Function() condition,
) async {
  await tester.runAsync(() async {
    if (condition()) return;
    final ready = Completer<void>();
    void listener() {
      if (condition() && !ready.isCompleted) ready.complete();
    }

    controller.addListener(listener);
    try {
      await ready.future.timeout(const Duration(seconds: 5));
    } finally {
      controller.removeListener(listener);
    }
  });
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase database;
  late FinanceController controller;
  setUpAll(tzdata.initializeTimeZones);
  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final repo = FinanceRepository(
      database,
      clock: () => DateTime.utc(2026, 10, 21, 10),
    );
    await repo.initialize('Asia/Shanghai');
    await repo.setLanguage(AppLanguage.simplifiedChinese);
    controller = FinanceController(repo);
    await controller.start();
  });
  tearDown(() async {
    controller.dispose();
    await database.close();
  });

  testWidgets(
    'home, settings, three locales and route back use persisted preferences',
    (tester) async {
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('财管'), findsOneWidget);
      expect(find.byKey(const Key('total-assets')), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-settings')));
      await tester.pumpAndSettle();
      expect(find.text('系统设置'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('language-en')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-en')));
      await waitForController(
        tester,
        controller,
        () => controller.settings!.language == AppLanguage.english,
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(
        (await tester.runAsync(
          () => controller.repository.watchSettings().first,
        ))!.language,
        AppLanguage.english,
      );
      await tester.ensureVisible(find.byKey(const Key('language-zh-Hant')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language-zh-Hant')));
      await waitForController(
        tester,
        controller,
        () => controller.settings!.language == AppLanguage.traditionalChinese,
      );
      expect(find.text('系統設定'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('財管'), findsOneWidget);
      expect(find.text('招商銀行'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'manual theme survives system changes and system mode follows brightness',
    (tester) async {
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await controller.setAppearance(Appearance.dark);
      await waitForController(
        tester,
        controller,
        () => controller.settings!.appearance == Appearance.dark,
      );
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(HomePage))).brightness,
        Brightness.dark,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(HomePage))).brightness,
        Brightness.dark,
      );
      await controller.setAppearance(Appearance.system);
      await waitForController(
        tester,
        controller,
        () => controller.settings!.appearance == Appearance.system,
      );
      expect(
        Theme.of(tester.element(find.byType(HomePage))).brightness,
        Brightness.light,
      );
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(HomePage))).brightness,
        Brightness.dark,
      );
    },
  );

  testWidgets(
    '320dp large text and complete large amounts have no layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final asset = (await database.select(database.projects).get())
          .firstWhere((p) => p.type == 'asset');
      final balance = (await database.select(database.balanceRecords).get())
          .firstWhere((r) => r.projectId == asset.id);
      await (database.update(
        database.balanceRecords,
      )..where((row) => row.id.equals(balance.id))).write(
        const BalanceRecordsCompanion(balanceMinor: Value(999999999999)),
      );
      await waitForController(
        tester,
        controller,
        () => controller.totalAssets == 999999999999,
      );
      await tester.pumpWidget(FinanceApp(controller: controller));
      await tester.pumpAndSettle();
      expect(find.text('¥9,999,999,999.99'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('open-settings')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'Chinese scripts and unsupported system locales resolve consistently',
    () {
      const supported = [Locale('en')];
      expect(
        resolveAppLocale([const Locale('zh', 'TW')], supported).scriptCode,
        'Hant',
      );
      expect(
        resolveAppLocale([const Locale('zh', 'CN')], supported).scriptCode,
        'Hans',
      );
      expect(
        resolveAppLocale([const Locale('fr')], supported).languageCode,
        'en',
      );
    },
  );
}
