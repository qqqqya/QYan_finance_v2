import '../core/business_date.dart';
import '../core/money.dart';
import '../domain/app_settings.dart';
import '../domain/balance_snapshot.dart';
import 'app_database.dart';

bool isBalanceType(String type) => type == 'asset' || type == 'liability';

final class Workspace {
  Workspace(this.projects, this.balances, this.entries);
  final List<ProjectRow> projects;
  final List<BalanceRecordRow> balances;
  final List<ProjectEntryRow> entries;
  ProjectRow? project(String id) {
    for (final project in projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  late final List<BalanceSnapshot> snapshots = [
    for (final r in balances)
      BalanceSnapshot(
        id: r.id,
        projectId: r.projectId,
        amountMinor: r.balanceMinor,
        moment: BusinessMoment(
          BusinessDate.parse(r.businessDate),
          r.businessTime,
        ),
        orderKey: r.orderKey,
      ),
  ];
  // One pass per immutable database snapshot, rather than scanning/sorting the
  // entire record set again for every project and chart.
  late final Map<String, int> _amounts = () {
    final latest = <String, BalanceSnapshot>{};
    for (final r in snapshots) {
      final previous = latest[r.projectId];
      if (previous == null || compareSnapshots(previous, r) < 0) {
        latest[r.projectId] = r;
      }
    }
    final result = {for (final e in latest.entries) e.key: e.value.amountMinor};
    for (final r in entries) {
      result[r.projectId] = checkedSumMinor([
        result[r.projectId] ?? 0,
        r.amountMinor,
      ]);
    }
    return result;
  }();
  int amount(ProjectRow project) => _amounts[project.id] ?? 0;
  late final List<ProjectSummary> summaries = [
    for (final p in projects)
      ProjectSummary(
        id: p.id,
        type: p.type,
        nameKey: p.nameKey,
        customName: p.customName,
        included: p.includeInSummary,
        amountMinor: amount(p),
      ),
  ];
  bool hasRecords(String id) =>
      balances.any((r) => r.projectId == id) ||
      entries.any((r) => r.projectId == id);
}

final class ProjectDraft {
  const ProjectDraft({
    required this.name,
    required this.type,
    this.categoryKey = 'other',
    this.iconKey = 'wallet',
    this.colorKey = 'neutral',
    this.included = true,
    this.note = '',
    this.initialMinor = 0,
    this.initialMoment,
    this.keepBuiltInName = false,
  });
  final String name, type, categoryKey, iconKey, colorKey, note;
  final bool included, keepBuiltInName;
  final int initialMinor;
  final BusinessMoment? initialMoment;
}

final class FinanceValidation implements Exception {
  const FinanceValidation(this.code);
  final String code;
}
