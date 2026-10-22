import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../l10n/app_localizations.dart';
import 'balance_charts.dart';
import 'finance_widgets.dart';

class AssetOverviewPage extends StatelessWidget {
  const AssetOverviewPage({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context)!;
      final workspace = controller.workspace!;
      List<CompositionItem> composition(String type) {
        final projects = workspace.projects
            .where((p) => p.type == type && p.includeInSummary)
            .toList();
        final palette = projectColors.values.toList();
        return [
          for (var i = 0; i < projects.length; i++)
            CompositionItem(
              projects[i].id,
              projectTitle(s, projects[i]),
              workspace.amount(projects[i]),
              projects[i].colorKey == 'neutral'
                  ? palette[i % palette.length]
                  : projectColors[projects[i].colorKey] ??
                        palette[i % palette.length],
            ),
        ];
      }

      return Scaffold(
        appBar: AppBar(title: Text(s.totalAssets)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(s.totalAssets),
            MoneyText(controller.totalAssets, size: 36),
            const SizedBox(height: 16),
            Text(s.totalLiabilities),
            MoneyText(controller.totalLiabilities, size: 24),
            const SizedBox(height: 16),
            Text(s.netAssets),
            MoneyText(controller.netAssets, size: 24),
            const SizedBox(height: 24),
            CompositionChart(
              title: s.assetComposition,
              items: composition('asset'),
            ),
            const SizedBox(height: 16),
            CompositionChart(
              title: s.liabilityComposition,
              items: composition('liability'),
            ),
            const SizedBox(height: 16),
            BalanceTrend(
              projectIds: workspace.projects
                  .where((p) => p.type == 'asset' && p.includeInSummary)
                  .map((p) => p.id)
                  .toSet(),
              snapshots: workspace.snapshots,
              now: bookNow(controller),
            ),
          ],
        ),
      );
    },
  );
}
