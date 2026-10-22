import 'package:finance_app/core/business_date.dart';
import 'package:finance_app/domain/asset_trend.dart';
import 'package:finance_app/ui/balance_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same-day observations use equal horizontal spacing with a diagonal connecting segment', () {
    final points = [
      TrendPoint(BusinessMoment(BusinessDate(2026, 10, 8), '12:00'), 0),
      TrendPoint(BusinessMoment(BusinessDate(2026, 10, 22), '12:00'), 10000),
      TrendPoint(BusinessMoment(BusinessDate(2026, 10, 22), '12:01'), 12000),
    ];
    final positions = trendLinePositions(points, const Size(300, 160));
    expect(
      positions[1].dx - positions[0].dx,
      positions[2].dx - positions[1].dx,
    );
    expect(positions[2].dx, greaterThan(positions[1].dx));
    expect(positions[2].dy, lessThan(positions[1].dy));
    expect(positions.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
    expect(
      trendLinePositions([points.last], const Size(300, 160)).single.dx,
      150,
    );
    expect(trendLinePositions([], const Size(300, 160)), isEmpty);
  });
}
