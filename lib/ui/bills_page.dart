import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../data/app_database.dart';
import '../l10n/app_localizations.dart';
import 'balance_charts.dart';
import 'bill_editor.dart';
import 'categories_page.dart';
import 'finance_widgets.dart';

String monthKey(int year, int month) =>
    '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  late String month = bookNow(widget.controller).date.yearMonth;
  String direction = 'expense';
  String? filter;
  int visibleRecords = 50;
  Future<void> edit([BillRow? bill]) async {
    final target = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => BillEditor(
          controller: widget.controller,
          selectedMonth: month,
          bill: bill,
        ),
      ),
    );
    if (!mounted || target == null || target == month) return;
    final s = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${s.savedMonth} $target'),
        action: SnackBarAction(
          label: s.viewMonth,
          onPressed: () => setState(() => month = target),
        ),
      ),
    );
  }

  void move(int delta) {
    final parts = month.split('-').map(int.parse).toList();
    final d = DateTime.utc(parts[0], parts[1] + delta, 1);
    setState(() {
      month = monthKey(d.year, d.month);
      visibleRecords = 50;
    });
  }

  Future<void> chooseMonth() async {
    final s = AppLocalizations.of(context)!,
        now = bookNow(widget.controller).date;
    final parts = month.split('-').map(int.parse).toList();
    var y = parts[0], m = parts[1];
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          scrollable: true,
          title: Text(s.chooseMonth),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                key: const Key('choose-year'),
                initialValue: y,
                decoration: InputDecoration(labelText: s.year),
                items: [
                  for (var year = now.year; year >= 1900; year--)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (v) => update(() {
                  y = v!;
                  if (y == now.year && m > now.month) m = now.month;
                }),
              ),
              DropdownButtonFormField<int>(
                key: ValueKey('choose-month-$y'),
                initialValue: m,
                decoration: InputDecoration(labelText: s.month),
                items: [
                  for (var n = 1; n <= (y == now.year ? now.month : 12); n++)
                    DropdownMenuItem(value: n, child: Text('$n')),
                ],
                onChanged: (v) => update(() => m = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel),
            ),
            FilledButton(
              key: const Key('confirm-month'),
              onPressed: () => Navigator.pop(context, monthKey(y, m)),
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() {
        month = chosen;
        visibleRecords = 50;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ledger = widget.controller.ledger!, rows = ledger.month(month);
        final income = ledger.total(rows, 'income'),
            expense = ledger.total(rows, 'expense');
        final groups = ledger.distribution(month, direction);
        final detail = ledger.month(month, filter);
        const palette = [
          Color(0xFF3976C4),
          Color(0xFF008C64),
          Color(0xFFE48932),
          Color(0xFF9166C3),
          Color(0xFFE34C55),
        ];
        var color = 0;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.monthlyBills),
            actions: [
              IconButton(
                key: const Key('open-categories'),
                tooltip: s.categories,
                icon: const Icon(Icons.category_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CategoriesPage(controller: widget.controller),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton.icon(
              key: const Key('add-bill'),
              onPressed: edit,
              icon: const Icon(Icons.add),
              label: Text(s.addBill),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('previous-month'),
                    tooltip: s.previousMonth,
                    onPressed: month == '1900-01' ? null : () => move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: TextButton(
                      key: const Key('choose-month'),
                      onPressed: chooseMonth,
                      child: Text(
                        month,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('next-month'),
                    tooltip: s.nextMonth,
                    onPressed:
                        month == bookNow(widget.controller).date.yearMonth
                        ? null
                        : () => move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Text(s.billBasis),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.income),
                      MoneyText(
                        income,
                        key: const Key('month-income'),
                        color: const Color(0xFF008C64),
                      ),
                      const SizedBox(height: 12),
                      Text(s.expense),
                      MoneyText(
                        expense,
                        key: const Key('month-expense'),
                        color: const Color(0xFFE34C55),
                      ),
                      const Divider(),
                      Text(s.surplus),
                      MoneyText(
                        income - expense,
                        key: const Key('month-surplus'),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('open-annual'),
                icon: const Icon(Icons.bar_chart),
                label: Text(s.annualSummary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnnualBillsPage(
                      controller: widget.controller,
                      initialYear: int.parse(month.substring(0, 4)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in ['expense', 'income'])
                    ChoiceChip(
                      key: Key('chart-$type'),
                      label: Text(directionTitle(s, type)),
                      selected: direction == type,
                      onSelected: (_) => setState(() {
                        direction = type;
                        filter = type;
                        visibleRecords = 50;
                      }),
                    ),
                ],
              ),
              CompositionChart(
                title:
                    '${s.billDistribution} · ${directionTitle(s, direction)}',
                items: [
                  for (final g in groups.entries)
                    CompositionItem(
                      g.key,
                      billCategoryTitle(s, ledger.category(g.key)!),
                      g.value,
                      palette[(color++) % palette.length],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                s.billDetails,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in <String?>[null, 'expense', 'income'])
                    ChoiceChip(
                      key: Key('filter-${type ?? 'all'}'),
                      label: Text(
                        type == null ? s.all : directionTitle(s, type),
                      ),
                      selected: filter == type,
                      onSelected: (_) => setState(() {
                        filter = type;
                        if (type != null) direction = type;
                        visibleRecords = 50;
                      }),
                    ),
                ],
              ),
              if (detail.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.noBills),
                ),
              for (final b in detail.take(visibleRecords))
                Card(
                  child: ListTile(
                    key: Key('bill-${b.id}'),
                    title: Text(
                      billCategoryTitle(s, ledger.category(b.categoryId)!),
                    ),
                    subtitle: Text(
                      '${directionTitle(s, b.type)} · ${b.businessDate} ${b.businessTime}\n${b.note}',
                    ),
                    trailing: SizedBox(
                      width: 120,
                      child: MoneyText(
                        b.type == 'income' ? b.amountMinor : -b.amountMinor,
                        signed: true,
                        size: 18,
                        color: b.type == 'income'
                            ? const Color(0xFF008C64)
                            : const Color(0xFFE34C55),
                      ),
                    ),
                    onTap: () => edit(b),
                  ),
                ),
              if (detail.length > visibleRecords)
                TextButton(
                  key: const Key('more-bills'),
                  onPressed: () => setState(() => visibleRecords += 50),
                  child: Text(s.loadMore),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AnnualBillsPage extends StatefulWidget {
  const AnnualBillsPage({
    super.key,
    required this.controller,
    required this.initialYear,
  });
  final FinanceController controller;
  final int initialYear;
  @override
  State<AnnualBillsPage> createState() => _AnnualBillsPageState();
}

class _AnnualBillsPageState extends State<AnnualBillsPage> {
  late int year = widget.initialYear;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final l = widget.controller.ledger!;
        final incomes = [
          for (var m = 1; m <= 12; m++)
            l.total(l.month(monthKey(year, m)), 'income'),
        ];
        final expenses = [
          for (var m = 1; m <= 12; m++)
            l.total(l.month(monthKey(year, m)), 'expense'),
        ];
        final rows = l.bills.where((b) => b.businessDate.startsWith('$year-'));
        final income = l.total(rows, 'income'),
            expense = l.total(rows, 'expense');
        final max = [...incomes, ...expenses].fold<int>(0, math.max);
        return Scaffold(
          appBar: AppBar(title: Text(s.annualSummary)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField<int>(
                key: const Key('annual-year'),
                initialValue: year,
                decoration: InputDecoration(labelText: s.year),
                items: [
                  for (
                    var y = bookNow(widget.controller).date.year;
                    y >= 1900;
                    y--
                  )
                    DropdownMenuItem(value: y, child: Text('$y')),
                ],
                onChanged: (v) => setState(() => year = v!),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.surplus),
                      MoneyText(
                        income - expense,
                        key: const Key('annual-surplus'),
                        size: 32,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 32,
                        runSpacing: 12,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.income),
                              MoneyText(
                                income,
                                key: const Key('annual-income'),
                                color: const Color(0xFF008C64),
                                size: 20,
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.expense),
                              MoneyText(
                                expense,
                                key: const Key('annual-expense'),
                                color: const Color(0xFFE34C55),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                children: [
                  Text(
                    '● ${s.income}',
                    style: const TextStyle(color: Color(0xFF008C64)),
                  ),
                  Text(
                    '● ${s.expense}',
                    style: const TextStyle(color: Color(0xFFE34C55)),
                  ),
                ],
              ),
              if (max == 0)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.noBills),
                )
              else ...[
                Text(s.amountAxis),
                MoneyText(max, size: 14),
                SizedBox(
                  height: 240,
                  child: CustomPaint(
                    key: const Key('annual-plot'),
                    painter: _AnnualPainter(
                      incomes,
                      expenses,
                      max,
                      Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const MoneyText(0, size: 14),
                Row(
                  children: [
                    for (var m = 1; m <= 12; m++)
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$m',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                  ],
                ),
                Center(child: Text(s.annualAxis)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AnnualPainter extends CustomPainter {
  const _AnnualPainter(this.incomes, this.expenses, this.max, this.grid);
  final List<int> incomes, expenses;
  final int max;
  final Color grid;
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()..color = grid;
    for (var n = 0; n < 3; n++) {
      final y = 4 + (size.height - 8) * n / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
    final column = size.width / 12;
    for (var i = 0; i < 12; i++) {
      for (var series = 0; series < 2; series++) {
        final value = series == 0 ? incomes[i] : expenses[i];
        final height = value / max * (size.height - 8);
        canvas.drawRect(
          Rect.fromLTWH(
            i * column + column * (series == 0 ? .15 : .52),
            size.height - 4 - height,
            column * .3,
            height,
          ),
          Paint()
            ..color = series == 0
                ? const Color(0xFF008C64)
                : const Color(0xFFE34C55),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AnnualPainter oldDelegate) => true;
}
