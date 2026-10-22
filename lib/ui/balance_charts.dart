import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/business_date.dart';
import '../core/money.dart';
import '../domain/asset_trend.dart';
import '../domain/balance_snapshot.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';

class BalanceTrend extends StatefulWidget {
  const BalanceTrend({
    super.key,
    required this.projectIds,
    required this.snapshots,
    required this.now,
  });
  final Set<String> projectIds;
  final List<BalanceSnapshot> snapshots;
  final BusinessMoment now;
  @override
  State<BalanceTrend> createState() => _BalanceTrendState();
}

class _BalanceTrendState extends State<BalanceTrend> {
  bool year = false;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final d = widget.now.date;
    final startDate = year
        ? DateTime.utc(d.year, d.month - 11, 1)
        : DateTime.utc(
            d.year,
            d.month,
            d.day,
          ).subtract(const Duration(days: 29));
    final samples = buildBalanceTrend(
      widget.projectIds,
      widget.snapshots,
      start: BusinessMoment(
        BusinessDate(startDate.year, startDate.month, startDate.day),
        '00:00',
      ),
      end: widget.now,
    );
    // Distinguish actual events from the extension that holds the last balance.
    final actual = widget.snapshots
        .where(
          (r) =>
              widget.projectIds.contains(r.projectId) &&
              r.moment.compareTo(widget.now) <= 0,
        )
        .map((r) => '${r.moment.date} ${r.moment.time}')
        .toSet();
    // Keep known window-opening value, but never plot the synthetic end hold.
    final points = samples
        .where(
          (p) =>
              identical(p, samples.first) ||
              actual.contains('${p.moment.date} ${p.moment.time}'),
        )
        .toList();
    final hasPositive = points.any((p) => p.amountMinor > 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.assetTrend, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(s.days30),
                  selected: !year,
                  onSelected: (_) => setState(() => year = false),
                ),
                ChoiceChip(
                  label: Text(s.months12),
                  selected: year,
                  onSelected: (_) => setState(() => year = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(s.manualBasis, style: Theme.of(context).textTheme.bodyMedium),
            Text(s.trendLineHint, style: Theme.of(context).textTheme.bodySmall),
            if (points.isEmpty)
              Padding(padding: const EdgeInsets.all(24), child: Text(s.noTrend))
            else if (!hasPositive)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(s.emptyChart),
              )
            else ...[
              Text(s.amountAxis, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final max = points.fold<int>(
                    0,
                    (v, p) => math.max(v, p.amountMinor),
                  );
                  final labelWidth = math.min(
                    constraints.maxWidth * .48,
                    math.max(72.0, formatMoneyMinor(max).length * 7.0),
                  );
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: labelWidth,
                        height: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MoneyText(max, size: 12),
                            MoneyText(max ~/ 2, size: 12),
                            const MoneyText(0, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: CustomPaint(
                            key: const Key('balance-trend-plot'),
                            painter: _LinePainter(
                              points,
                              actual,
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      points.first.moment.date.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      points.last.moment.date.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              Center(
                child: Text(
                  s.recordAxis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(s.pointValues),
                children: [
                  for (final p in points)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${p.moment.date} ${p.moment.time}'),
                          ),
                          Expanded(child: MoneyText(p.amountMinor, size: 15)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Ordinal spacing makes close observations readable without claiming a
/// proportional time scale. Amounts and their chronological order stay exact.
List<Offset> trendLinePositions(List<TrendPoint> points, Size size) {
  final max = points.fold<int>(1, (v, p) => math.max(v, p.amountMinor));
  return [
    for (var i = 0; i < points.length; i++)
      Offset(
        points.length == 1
            ? size.width / 2
            : 4 + i / (points.length - 1) * (size.width - 8),
        size.height - 6 - points[i].amountMinor / max * (size.height - 12),
      ),
  ];
}

class _LinePainter extends CustomPainter {
  const _LinePainter(this.points, this.actual, this.color, this.grid);
  final List<TrendPoint> points;
  final Set<String> actual;
  final Color color, grid;
  double stamp(BusinessMoment moment) =>
      DateTime.parse('${moment.date}T${moment.time}:00Z').millisecondsSinceEpoch
          .toDouble();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = 6 + (size.height - 12) * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
    final positions = trendLinePositions(points, size);
    final path = Path();
    final previous = positions.first;
    path.moveTo(previous.dx, previous.dy);
    for (final next in positions.skip(1)) {
      path.lineTo(next.dx, next.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      if (actual.contains('${point.moment.date} ${point.moment.time}') ||
          points.length == 1) {
        canvas.drawCircle(positions[i], 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) => true;
}

class CompositionItem {
  const CompositionItem(this.id, this.name, this.amount, this.color);
  final String id, name;
  final int amount;
  final Color color;
}

class CompositionChart extends StatelessWidget {
  const CompositionChart({super.key, required this.title, required this.items});
  final String title;
  final List<CompositionItem> items;
  @override
  Widget build(BuildContext context) {
    final positive = items.where((p) => p.amount > 0).toList();
    final total = checkedSumMinor(positive.map((p) => p.amount));
    final s = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            if (total == 0)
              Text(s.emptyChart)
            else ...[
              Center(
                child: SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _DonutPainter(positive, total),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: MoneyText(total, size: 21),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              for (final item in positive)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Icon(Icons.circle, size: 12, color: item.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name),
                            MoneyText(item.amount, size: 17),
                            Text(
                              '${(item.amount / total * 100).toStringAsFixed(2)}%',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.items, this.total);
  final List<CompositionItem> items;
  final int total;
  @override
  void paint(Canvas canvas, Size size) {
    var angle = -math.pi / 2;
    for (final item in items) {
      final sweep = item.amount / total * math.pi * 2;
      canvas.drawArc(
        Rect.fromLTWH(12, 12, size.width - 24, size.height - 24),
        angle,
        sweep,
        false,
        Paint()
          ..color = item.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22,
      );
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}
