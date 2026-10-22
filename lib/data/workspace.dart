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
  int amount(ProjectRow project) => isBalanceType(project.type)
      ? currentBalanceMinor(project.id, snapshots)
      : checkedSumMinor(
          entries
              .where((r) => r.projectId == project.id)
              .map((r) => r.amountMinor),
        );
  List<ProjectSummary> get summaries => [
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
