import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/money.dart';
import '../data/finance_repository.dart';
import '../data/workspace.dart';
import '../data/ledger_workspace.dart';
import '../domain/app_settings.dart';

final class FinanceController extends ChangeNotifier {
  FinanceController(this.repository);

  final FinanceRepository repository;
  StreamSubscription<AppSettings>? _settingsSubscription;
  StreamSubscription<Workspace>? _dashboardSubscription;
  StreamSubscription<LedgerWorkspace>? _ledgerSubscription;
  LedgerWorkspace? ledger;
  Workspace? workspace;
  AppSettings? settings;
  List<ProjectSummary> projects = const [];
  bool dashboardLoaded = false;
  bool saving = false;
  bool hasError = false;
  bool hasSaveError = false;
  bool _disposed = false;

  int get totalAssets => checkedSumMinor(
    projects
        .where((project) => project.type == 'asset' && project.included)
        .map((project) => project.amountMinor),
  );
  int get totalLiabilities => checkedSumMinor(
    projects
        .where((project) => project.type == 'liability' && project.included)
        .map((project) => project.amountMinor),
  );
  int get netAssets => checkedSumMinor([totalAssets, -totalLiabilities]);

  Future<void> start() async {
    settings = await repository.watchSettings().first;
    workspace = await repository.watchWorkspace().first;
    ledger = await repository.watchLedger().first;
    projects = workspace!.summaries;
    dashboardLoaded = true;
    _settingsSubscription = repository.watchSettings().listen((value) {
      settings = value;
      _notify();
    }, onError: _onError);
    _dashboardSubscription = repository.watchWorkspace().listen((value) {
      workspace = value;
      projects = value.summaries;
      dashboardLoaded = true;
      _notify();
    }, onError: _onError);
    _ledgerSubscription = repository.watchLedger().listen((value) {
      ledger = value;
      _notify();
    }, onError: _onError);
  }

  Future<void> setAppearance(Appearance value) =>
      _save(() => repository.setAppearance(value));
  Future<void> setThemeColor(ThemeColor value) =>
      _save(() => repository.setThemeColor(value));
  Future<void> refreshAfterRestore() async {
    final values = await Future.wait<Object>([
      repository.watchSettings().first,
      repository.watchWorkspace().first,
      repository.watchLedger().first,
    ]);
    settings = values[0] as AppSettings;
    workspace = values[1] as Workspace;
    ledger = values[2] as LedgerWorkspace;
    projects = workspace!.summaries;
    hasError = false;
    _notify();
  }

  Future<void> setLanguage(AppLanguage value) =>
      _save(() => repository.setLanguage(value));

  Future<void> _save(Future<void> Function() action) async {
    if (saving) return;
    saving = true;
    hasSaveError = false;
    _notify();
    try {
      await action();
    } catch (_) {
      hasSaveError = true;
    } finally {
      saving = false;
      _notify();
    }
  }

  void _onError(Object error, StackTrace stack) {
    hasError = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_settingsSubscription?.cancel());
    unawaited(_dashboardSubscription?.cancel());
    unawaited(_ledgerSubscription?.cancel());
    super.dispose();
  }
}
