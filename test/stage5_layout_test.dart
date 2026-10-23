import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:finance_app/app/finance_app.dart';
import 'package:finance_app/app/finance_controller.dart';
import 'package:finance_app/core/money.dart';
import 'package:finance_app/data/app_database.dart';
import 'package:finance_app/data/finance_repository.dart';
import 'package:finance_app/data/backup_repository.dart';
import 'package:finance_app/services/backup_manager.dart';
import 'package:finance_app/domain/app_settings.dart';
import 'package:finance_app/ui/asset_overview_page.dart';
import 'package:finance_app/ui/bill_editor.dart';
import 'package:finance_app/ui/bills_page.dart';
import 'package:finance_app/ui/categories_page.dart';
import 'package:finance_app/ui/data_management_page.dart';
import 'package:finance_app/ui/history_page.dart';
import 'package:finance_app/ui/memos_page.dart';
import 'package:finance_app/ui/project_detail_page.dart';
import 'package:finance_app/ui/project_editor.dart';
import 'package:finance_app/ui/record_editor.dart';
import 'package:finance_app/ui/settings_page.dart';
import 'package:finance_app/ui/sort_projects_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'data/backup_workflow_test.dart' show seedEveryType, testNow;
import 'data/backup_workflow_test.dart' show TestFiles;
import 'backup_widgets_test.dart' show visible;
import 'ledger_widgets_test.dart' show reveal;

import 'dart:io';

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 8)),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(tz.initializeTimeZones);
  final layouts = <(Size, double)>[
    for (final w in [320.0, 360.0, 480.0])
      for (final scale in [1.0, 1.5, 2.0]) (Size(w, 900), scale),
    (const Size(720, 320), 1),
    (const Size(800, 360), 1.5),
    (const Size(800, 360), 2),
  ];
  for (final language in [
    AppLanguage.english,
    AppLanguage.simplifiedChinese,
    AppLanguage.traditionalChinese,
  ]) {
    for (final color in ThemeColor.values) {
      for (final appearance in Appearance.values) {
        for (final (size, scale) in layouts) {
          testWidgets(
            'T22 ${color.name} ${language.code} ${appearance.name} ${size.width.toInt()}x${size.height.toInt()}@$scale',
            (tester) async {
              final db = AppDatabase(NativeDatabase.memory());
              final f = FinanceRepository(db, clock: () => testNow);
              await tester.runAsync(() async {
                await f.initialize('Asia/Shanghai');
                await seedEveryType(f);
                await f.setAppearance(appearance);
                await f.setThemeColor(color);
                await f.setLanguage(language);
                final w = await f.watchWorkspace().first;
                final p = w.projects.firstWhere(
                  (p) => p.customName == '中文資產 EN',
                );
                await (db.update(
                  db.projects,
                )..where((r) => r.id.equals(p.id))).write(
                  const ProjectsCompanion(
                    customName: Value(
                      '用户原文 Long asset name with wrapping 中文繁體 repeated to verify card alignment',
                    ),
                  ),
                );
                await (db.update(
                  db.balanceRecords,
                )..where((r) => r.projectId.equals(p.id))).write(
                  const BalanceRecordsCompanion(
                    balanceMinor: Value(maxRecordMinor),
                  ),
                );
                await f.reorderProjects([
                  p.id,
                  ...w.projects.where((x) => x.id != p.id).map((x) => x.id),
                ]);
              });
              final c = FinanceController(f);
              await tester.runAsync(c.start);
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              tester.platformDispatcher.platformBrightnessTestValue =
                  Brightness.dark;
              if (size.width > size.height) {
                tester.view.padding = const FakeViewPadding(
                  left: 70,
                  right: 20,
                  top: 24,
                  bottom: 24,
                );
              }
              addTearDown(() async {
                c.dispose();
                await db.close();
                tester.view.resetPhysicalSize();
                tester.view.resetDevicePixelRatio();
                tester.view.resetPadding();
                tester.platformDispatcher.clearTextScaleFactorTestValue();
                tester.platformDispatcher.clearPlatformBrightnessTestValue();
              });
              await tester.pumpWidget(FinanceApp(controller: c));
              await settle(tester);
              final nav = tester.state<NavigatorState>(
                find.byType(Navigator).first,
              );
              final p = c.workspace!.projects.first;
              expect(c.totalAssets, maxRecordMinor);
              expect(
                tester.getSize(find.byKey(const Key('asset-overview'))).width,
                closeTo(
                  size.width - (size.width > size.height ? 90 : 0) - 40,
                  .1,
                ),
              );
              expect(
                Theme.of(
                  tester.element(find.byKey(const Key('asset-overview'))),
                ).brightness,
                appearance == Appearance.light
                    ? Brightness.light
                    : Brightness.dark,
              );
              final rows = find.byKey(const Key('project-row-0'));
              if (rows.evaluate().isNotEmpty) {
                final pair = c.workspace!.projects.take(2).toList();
                expect(
                  tester
                      .getSize(find.byKey(Key('project-${pair[0].id}')))
                      .height,
                  tester
                      .getSize(find.byKey(Key('project-${pair[1].id}')))
                      .height,
                );
                expect(
                  tester
                      .getCenter(find.byKey(Key('drag-project-${pair[0].id}')))
                      .dy,
                  closeTo(
                    tester
                        .getCenter(
                          find.byKey(Key('drag-project-${pair[1].id}')),
                        )
                        .dy,
                    .1,
                  ),
                );
              }
              final pages = <Widget>[
                SettingsPage(controller: c),
                DataManagementPage(
                  controller: c,
                  manager: BackupManager(
                    BackupRepository(f),
                    TestFiles()
                      ..imported = await tester.runAsync(
                        () =>
                            File('test/fixtures/backups/v0.0-all-types.json')
                                .readAsBytes(),
                      ),
                  ),
                ),
                ProjectEditor(controller: c),
                SortProjectsPage(controller: c),
                ProjectDetailPage(controller: c, projectId: p.id),
                RecordEditor(controller: c, project: p),
                AssetOverviewPage(controller: c),
                BillsPage(controller: c),
                BillEditor(controller: c, selectedMonth: '2026-09'),
                AnnualBillsPage(controller: c, initialYear: 2026),
                CategoriesPage(controller: c),
                CategoryEditor(controller: c),
                MemosPage(controller: c),
                MemoEditor(controller: c, memo: c.ledger!.memos.first),
                HistoryPage(
                  controller: c,
                  entityType: 'balanceRecord',
                  entityId: c.workspace!.balances
                      .firstWhere((r) => r.projectId == p.id)
                      .id,
                ),
              ];
              for (final page in pages) {
                nav.push(MaterialPageRoute<void>(builder: (_) => page));
                await settle(tester);
                if (page is BillsPage) {
                  await tester.tap(find.byKey(const Key('choose-month')));
                  await tester.pumpAndSettle();
                  expect(
                    tester.takeException(),
                    isNull,
                    reason: 'Month dialog $size @$scale',
                  );
                  nav.pop();
                  await settle(tester);
                }
                if (page is DataManagementPage) {
                  await reveal(tester, find.byKey(const Key('import-backup')));
                  await tester.tap(find.byKey(const Key('import-backup')));
                  await visible(
                    tester,
                    find.byKey(const Key('confirm-restore')),
                  );
                  expect(find.textContaining('v0.0'), findsOneWidget);
                  expect(
                    tester.takeException(),
                    isNull,
                    reason: 'Legacy import dialog $size @$scale',
                  );
                  nav.pop();
                  await settle(tester);
                  await reveal(tester, find.byKey(const Key('factory-reset')));
                  await tester.tap(find.byKey(const Key('factory-reset')));
                  await tester.pumpAndSettle();
                  expect(
                    tester.takeException(),
                    isNull,
                    reason: 'Factory-reset dialog layout',
                  );
                  nav.pop();
                  await settle(tester);
                }
                final lists = find.byType(Scrollable);
                if (lists.evaluate().isNotEmpty) {
                  final position = tester
                      .state<ScrollableState>(lists.first)
                      .position;
                  position.jumpTo(position.maxScrollExtent);
                  await tester.pumpAndSettle();
                }
                expect(
                  tester.takeException(),
                  isNull,
                  reason:
                      '${page.runtimeType}, $language, $appearance, $size @$scale',
                );
                nav.pop();
                await settle(tester);
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump(const Duration(milliseconds: 1));
            },
            tags: const ['layout-matrix'],
          );
        }
      }
    }
  }
}
