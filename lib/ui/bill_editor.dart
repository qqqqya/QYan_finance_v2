import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/business_date.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/finance_repository.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';
import 'history_page.dart';

class BillEditor extends StatefulWidget {
  const BillEditor({
    super.key,
    required this.controller,
    required this.selectedMonth,
    this.bill,
  });
  final FinanceController controller;
  final String selectedMonth;
  final BillRow? bill;
  @override
  State<BillEditor> createState() => _BillEditorState();
}

class _BillEditorState extends State<BillEditor> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(),
      note = TextEditingController(),
      date = TextEditingController(),
      time = TextEditingController();
  late String type;
  String? category;
  bool dirty = false, saving = false;
  @override
  void initState() {
    super.initState();
    final b = widget.bill, now = bookNow(widget.controller);
    type = b?.type ?? 'expense';
    category = b?.categoryId;
    amount.text = b == null
        ? ''
        : formatMoneyMinor(b.amountMinor, grouped: false);
    note.text = b?.note ?? '';
    final parts = widget.selectedMonth.split('-').map(int.parse).toList();
    date.text =
        b?.businessDate ??
        defaultEntryDate(parts[0], parts[1], now.date).toString();
    time.text = b?.businessTime ?? now.time;
  }

  void changed() => setState(() => dirty = true);
  @override
  void dispose() {
    for (final c in [amount, note, date, time]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await performChange(context, () async {
      await widget.controller.repository.saveBill(
        id: widget.bill?.id,
        type: type,
        amount: parseMoneyMinor(amount.text, allowZero: false),
        categoryId: category!,
        moment: BusinessMoment(
          BusinessDate.parse(date.text.trim()),
          time.text.trim(),
        ),
        note: note.text,
      );
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) dirty = false;
    });
    if (ok) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, date.text.trim().substring(0, 7));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final categories = widget.controller.ledger!.categories
            .where(
              (c) =>
                  c.type == type &&
                  (c.isActive ||
                      (widget.bill?.categoryId == c.id &&
                          widget.bill?.type == type)),
            )
            .toList();
        return UnsavedChangesGuard(
          dirty: dirty,
          saving: saving,
          onSave: save,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.bill == null ? s.addBill : s.billDetails),
            ),
            body: Form(
              key: form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(s.billBasis),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('bill-type'),
                    initialValue: type,
                    decoration: InputDecoration(
                      labelText: '${s.income} / ${s.expense}',
                    ),
                    items: [
                      for (final t in ['expense', 'income'])
                        DropdownMenuItem(
                          value: t,
                          child: Text(directionTitle(s, t)),
                        ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null && v != type) {
                              setState(() {
                                type = v;
                                category = null;
                                dirty = true;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('bill-amount'),
                    controller: amount,
                    onChanged: (_) => changed(),
                    decoration: InputDecoration(
                      labelText: s.entryAmount,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      try {
                        parseMoneyMinor(v ?? '', allowZero: false);
                        return null;
                      } catch (_) {
                        return s.invalidAmount;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: ValueKey('bill-category-$type-${category ?? ''}'),
                    initialValue: categories.any((c) => c.id == category)
                        ? category
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: s.category),
                    hint: Text(s.chooseCategory),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            '${billCategoryTitle(s, c)}${c.isActive ? '' : ' (${s.categoryInactive})'}',
                          ),
                        ),
                    ],
                    validator: (v) => v == null ? s.categoryUnavailable : null,
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                            category = v;
                            dirty = true;
                          }),
                  ),
                  const SizedBox(height: 16),
                  MomentFields(
                    date: date,
                    time: time,
                    controller: widget.controller,
                    changed: changed,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('bill-note'),
                    controller: note,
                    maxLines: 3,
                    maxLength: 2000,
                    onChanged: (_) => changed(),
                    decoration: InputDecoration(labelText: s.note),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const Key('save-bill'),
                    onPressed: saving ? null : save,
                    child: Text(s.save),
                  ),
                  if (widget.bill case final b?) ...[
                    Text(
                      '${s.createdAt}: ${DateTime.fromMillisecondsSinceEpoch(b.createdAtMs, isUtc: true).toIso8601String()}',
                    ),
                    Text(
                      '${s.updatedAt}: ${DateTime.fromMillisecondsSinceEpoch(b.updatedAtMs, isUtc: true).toIso8601String()}',
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HistoryPage(
                            controller: widget.controller,
                            entityType: 'bill',
                            entityId: b.id,
                          ),
                        ),
                      ),
                      child: Text(s.history),
                    ),
                    ChangeButton(
                      label: s.delete,
                      danger: true,
                      onPressed: () async {
                        if (await confirmChange(
                              context,
                              s.delete,
                              s.deleteBillWarning,
                            ) &&
                            context.mounted) {
                          final ok = await performChange(
                            context,
                            () => widget.controller.repository.deleteBill(b.id),
                          );
                          if (ok && mounted) {
                            setState(() => dirty = false);
                            await WidgetsBinding.instance.endOfFrame;
                            if (context.mounted) Navigator.pop(context);
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
