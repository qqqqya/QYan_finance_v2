import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/workspace.dart';
import '../domain/balance_snapshot.dart';
import '../l10n/app_localizations.dart';
import 'balance_charts.dart';
import 'finance_widgets.dart';
import 'history_page.dart';
import 'project_editor.dart';
import 'record_editor.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.controller,
    required this.projectId,
  });
  final FinanceController controller;
  final String projectId;
  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  String? month;
  FinanceController get controller => widget.controller;
  Color? entryColor(ProjectRow project) => project.type == 'income_log'
      ? projectColors['green']
      : project.type == 'expense_log'
      ? projectColors['red']
      : null;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context)!;
      final workspace = controller.workspace!;
      final project = workspace.project(widget.projectId);
      if (project == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(s.missingProject)),
        );
      }
      final balanceType = isBalanceType(project.type);
      final changes = balanceType
          ? snapshotChanges(project.id, workspace.snapshots)
          : <String, int>{};
      final balances =
          workspace.balances.where((r) => r.projectId == project.id).toList()
            ..sort((a, b) {
              final order = (b.businessDate + b.businessTime).compareTo(
                a.businessDate + a.businessTime,
              );
              return order == 0 ? b.orderKey.compareTo(a.orderKey) : order;
            });
      final entries =
          workspace.entries.where((r) => r.projectId == project.id).toList()
            ..sort((a, b) {
              final order = (b.businessDate + b.businessTime).compareTo(
                a.businessDate + a.businessTime,
              );
              return order != 0 ? order : b.id.compareTo(a.id);
            });
      final months =
          entries.map((r) => r.businessDate.substring(0, 7)).toSet().toList()
            ..sort((a, b) => b.compareTo(a));
      final selectedMonth = months.contains(month) ? month : null;
      final filtered = entries
          .where(
            (r) =>
                selectedMonth == null ||
                r.businessDate.startsWith(selectedMonth),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: Text(s.projectDetails),
          actions: [
            IconButton(
              key: const Key('edit-project'),
              tooltip: s.editProject,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProjectEditor(controller: controller, project: project),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projectTitle(s, project),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    MoneyText(
                      workspace.amount(project),
                      size: 34,
                      color: entryColor(project),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${typeTitle(s, project.type)} · ${categoryTitle(s, project.categoryKey)}',
                    ),
                    if (project.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SelectableText(project.note),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('add-record'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RecordEditor(controller: controller, project: project),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(balanceType ? s.updateBalance : s.addEntry),
            ),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryPage(
                    controller: controller,
                    entityType: 'project',
                    entityId: project.id,
                  ),
                ),
              ),
              child: Text(s.history),
            ),
            if (balanceType) ...[
              const SizedBox(height: 16),
              BalanceTrend(
                projectIds: {project.id},
                snapshots: workspace.snapshots,
                now: bookNow(controller),
              ),
            ],
            const SizedBox(height: 24),
            Text(s.records, style: Theme.of(context).textTheme.headlineSmall),
            if (!balanceType && months.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: DropdownButtonFormField<String>(
                  key: ValueKey(selectedMonth),
                  initialValue: selectedMonth ?? '',
                  isExpanded: true,
                  decoration: InputDecoration(labelText: s.selectMonth),
                  items: [
                    DropdownMenuItem(value: '', child: Text(s.allMonths)),
                    for (final m in months)
                      DropdownMenuItem(value: m, child: Text(m)),
                  ],
                  onChanged: (v) => setState(() => month = v == '' ? null : v),
                ),
              ),
            if (!balanceType && selectedMonth != null)
              MoneyText(
                checkedSumMinor(filtered.map((r) => r.amountMinor)),
                size: 22,
                color: entryColor(project),
              ),
            if (balanceType && balances.isEmpty ||
                !balanceType && filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(s.noRecords),
              ),
            if (balanceType)
              for (final r in balances)
                _record(context, project, r, null, changes[r.id]),
            if (!balanceType)
              for (final r in filtered)
                _record(context, project, null, r, null),
            if (balances.isNotEmpty || entries.isNotEmpty)
              ChangeButton(
                key: const Key('clear-records'),
                label: s.clearRecords,
                danger: true,
                onPressed: () async {
                  if (await confirmChange(
                        context,
                        s.clearRecords,
                        s.clearRecordsWarning,
                      ) &&
                      context.mounted) {
                    await performChange(
                      context,
                      () => controller.repository.clearRecords(project.id),
                    );
                  }
                },
              ),
            const SizedBox(height: 24),
            ChangeButton(
              key: const Key('delete-project'),
              label: s.deleteProject,
              danger: true,
              onPressed: () async {
                if (await confirmChange(
                      context,
                      s.deleteProject,
                      s.deleteProjectWarning,
                    ) &&
                    context.mounted) {
                  if (await performChange(
                        context,
                        () => controller.repository.deleteProject(project.id),
                      ) &&
                      context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    },
  );

  Widget _record(
    BuildContext context,
    ProjectRow project,
    BalanceRecordRow? balance,
    ProjectEntryRow? entry,
    int? delta,
  ) {
    final s = AppLocalizations.of(context)!;
    final id = balance?.id ?? entry!.id;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        key: Key('record-$id'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecordEditor(
              controller: controller,
              project: project,
              balance: balance,
              entry: entry,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${balance?.businessDate ?? entry!.businessDate} ${balance?.businessTime ?? entry!.businessTime}',
              ),
              const SizedBox(height: 8),
              MoneyText(
                balance?.balanceMinor ?? entry!.amountMinor,
                size: 24,
                color: entryColor(project),
              ),
              if (delta != null) ...[
                const SizedBox(height: 8),
                Text(s.recordedChange),
                MoneyText(
                  delta,
                  size: 16,
                  signed: true,
                  color: delta >= 0
                      ? projectColors['green']
                      : projectColors['red'],
                ),
              ],
              if ((balance?.note ?? entry!.note).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(balance?.note ?? entry!.note),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.edit_outlined, size: 16, semanticLabel: s.edit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
