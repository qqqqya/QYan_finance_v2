import 'dart:async';

import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/money.dart';
import '../domain/app_settings.dart';
import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'settings_page.dart';
import 'asset_overview_page.dart';
import 'project_detail_page.dart';
import 'project_editor.dart';
import 'sort_projects_page.dart';
import 'finance_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});
  final FinanceController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FinanceController get controller => widget.controller;
  final scroll = ScrollController();
  bool sorting = false;
  Timer? dragScroll;
  double scrollDelta = 0;

  @override
  void dispose() {
    dragScroll?.cancel();
    scroll.dispose();
    super.dispose();
  }

  void autoScroll(DragUpdateDetails details) {
    if (!scroll.hasClients) return;
    final height = MediaQuery.sizeOf(context).height;
    final y = details.globalPosition.dy;
    final delta = y > height - 110
        ? 24.0
        : y < 150
        ? -24.0
        : 0.0;
    scrollDelta = delta;
    if (delta == 0) {
      stopScroll();
      return;
    }
    dragScroll ??= Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!scroll.hasClients) {
        stopScroll();
        return;
      }
      scroll.jumpTo(
        (scroll.offset + scrollDelta).clamp(
          0.0,
          scroll.position.maxScrollExtent,
        ),
      );
    });
  }

  void stopScroll() {
    dragScroll?.cancel();
    dragScroll = null;
  }

  Future<void> reorder(String source, String target) async {
    if (sorting || source == target) return;
    setState(() => sorting = true);
    final ids = controller.projects.map((p) => p.id).toList();
    final index = ids.indexOf(target);
    ids.remove(source);
    ids.insert(index, source);
    await performChange(
      context,
      () => controller.repository.reorderProjects(ids),
    );
    if (mounted) setState(() => sorting = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appName, style: theme.textTheme.titleMedium),
        leading: IconButton(
          key: const Key('open-settings'),
          tooltip: strings.settings,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => SettingsPage(controller: controller),
            ),
          ),
        ),
        actions: [
          IconButton(
            key: const Key('new-project'),
            tooltip: strings.newProject,
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProjectEditor(controller: controller),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (controller.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.dataError),
                ),
              );
            }
            if (!controller.dashboardLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                InkWell(
                  key: const Key('open-overview'),
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssetOverviewPage(controller: controller),
                    ),
                  ),
                  child: _AssetOverview(controller: controller),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.myProjects,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      '${controller.projects.length}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      key: const Key('sort-projects'),
                      tooltip: strings.sortProjects,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SortProjectsPage(controller: controller),
                        ),
                      ),
                      icon: const Icon(Icons.swap_vert),
                    ),
                  ],
                ),
                Text(strings.sortHint, style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final singleColumn =
                        constraints.maxWidth < 340 ||
                        MediaQuery.textScalerOf(context).scale(16) > 21;
                    final width = singleColumn
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final project in controller.projects)
                          SizedBox(
                            width: width,
                            child: DragTarget<String>(
                              onWillAcceptWithDetails: (details) =>
                                  !sorting && details.data != project.id,
                              onAcceptWithDetails: (details) =>
                                  reorder(details.data, project.id),
                              builder: (context, candidates, rejected) =>
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      border: candidates.isNotEmpty
                                          ? Border.all(
                                              color: theme.colorScheme.primary,
                                              width: 2,
                                            )
                                          : null,
                                    ),
                                    child: LongPressDraggable<String>(
                                      data: project.id,
                                      maxSimultaneousDrags: sorting ? 0 : 1,
                                      onDragUpdate: autoScroll,
                                      onDragEnd: (_) => stopScroll(),
                                      feedback: SizedBox(
                                        width: width,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: _ProjectCard(
                                            project: project,
                                            controller: controller,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.25,
                                        child: _ProjectCard(
                                          project: project,
                                          controller: controller,
                                        ),
                                      ),
                                      child: _ProjectCard(
                                        project: project,
                                        controller: controller,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.localOnly,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssetOverview extends StatelessWidget {
  const _AssetOverview({required this.controller});
  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Container(
      key: const Key('asset-overview'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF202024),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.totalAssets,
            style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 15),
          ),
          const SizedBox(height: 14),
          _Amount(
            amount: controller.totalAssets,
            size: 34,
            color: Colors.white,
            valueKey: const Key('total-assets'),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final items = [
                _OverviewMetric(
                  label: strings.totalLiabilities,
                  amount: controller.totalLiabilities,
                ),
                _OverviewMetric(
                  label: strings.netAssets,
                  amount: controller.netAssets,
                ),
              ];
              if (MediaQuery.textScalerOf(context).scale(16) > 22 ||
                  constraints.maxWidth < 260) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [items[0], const SizedBox(height: 16), items[1]],
                );
              }
              return Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 16),
                  Expanded(child: items[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({required this.label, required this.amount});
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xFFCCCCD0), fontSize: 13),
      ),
      const SizedBox(height: 6),
      _Amount(amount: amount, size: 20, color: Colors.white),
    ],
  );
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.amount,
    required this.size,
    required this.color,
    this.valueKey,
  });
  final int amount;
  final double size;
  final Color color;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'CNY ${formatMoneyMinor(amount)}',
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '¥${formatMoneyMinor(amount)}',
        key: valueKey,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.controller});
  final ProjectSummary project;
  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isIncome = project.type == 'income_log';
    final isExpense = project.type == 'expense_log';
    final color = isIncome
        ? const Color(0xFF008C64)
        : isExpense || project.type == 'liability'
        ? const Color(0xFFE34C55)
        : theme.colorScheme.onSurface;
    final typeLabel = switch (project.type) {
      'asset' =>
        project.included
            ? strings.includedInAssets
            : strings.excludedFromAssets,
      'liability' => strings.liabilityBalance,
      'income_log' => strings.independentIncome,
      _ => strings.independentExpense,
    };
    return Card(
      child: InkWell(
        key: Key('project-${project.id}'),
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProjectDetailPage(
              controller: controller,
              projectId: project.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                projectIcons[controller.workspace
                        ?.project(project.id)
                        ?.iconKey] ??
                    Icons.account_balance_wallet_outlined,
                color:
                    projectColors[controller.workspace
                        ?.project(project.id)
                        ?.colorKey] ??
                    color,
                size: 21,
              ),
              const SizedBox(height: 10),
              Text(
                project.customName ??
                    strings.projectName(project.nameKey ?? ''),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _Amount(amount: project.amountMinor, size: 24, color: color),
              const SizedBox(height: 12),
              Text(
                typeLabel,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
