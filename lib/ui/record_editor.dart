import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/business_date.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/workspace.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';
import 'history_page.dart';

class RecordEditor extends StatefulWidget {
  const RecordEditor({
    super.key,
    required this.controller,
    required this.project,
    this.balance,
    this.entry,
  });
  final FinanceController controller;
  final ProjectRow project;
  final BalanceRecordRow? balance;
  final ProjectEntryRow? entry;
  @override
  State<RecordEditor> createState() => _RecordEditorState();
}

class _RecordEditorState extends State<RecordEditor> {
  final form = GlobalKey<FormState>();
  final amount = TextEditingController(),
      note = TextEditingController(),
      date = TextEditingController(),
      time = TextEditingController();
  bool dirty = false, saving = false;
  String? get recordId => widget.balance?.id ?? widget.entry?.id;
  bool get balanceType => isBalanceType(widget.project.type);
  @override
  void initState() {
    super.initState();
    final now = bookNow(widget.controller);
    amount.text = recordId == null
        ? ''
        : formatMoneyMinor(
            widget.balance?.balanceMinor ?? widget.entry!.amountMinor,
            grouped: false,
          );
    note.text = widget.balance?.note ?? widget.entry?.note ?? '';
    date.text =
        widget.balance?.businessDate ??
        widget.entry?.businessDate ??
        now.date.toString();
    time.text =
        widget.balance?.businessTime ?? widget.entry?.businessTime ?? now.time;
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
    final success = await performChange(context, () async {
      await widget.controller.repository.saveRecord(
        widget.project.id,
        recordId: recordId,
        amount: parseMoneyMinor(amount.text, allowZero: balanceType),
        moment: BusinessMoment(BusinessDate.parse(date.text), time.text),
        note: note.text,
      );
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (success) dirty = false;
    });
    if (success) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return UnsavedChangesGuard(
      dirty: dirty,
      saving: saving,
      onSave: save,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            recordId != null
                ? s.edit
                : balanceType
                ? s.updateBalance
                : s.addEntry,
          ),
        ),
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                projectTitle(s, widget.project),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('record-amount'),
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText:
                      '${balanceType ? s.balanceAmount : s.entryAmount} · CNY',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  try {
                    parseMoneyMinor(v ?? '', allowZero: balanceType);
                    return null;
                  } catch (_) {
                    return s.invalidAmount;
                  }
                },
              ),
              const SizedBox(height: 20),
              MomentFields(
                date: date,
                time: time,
                controller: widget.controller,
                changed: changed,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('record-note'),
                controller: note,
                maxLines: 4,
                maxLength: 2000,
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText: s.note,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('save-record'),
                onPressed: saving ? null : save,
                child: Text(s.save),
              ),
              if (recordId != null) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        controller: widget.controller,
                        entityType: balanceType
                            ? 'balanceRecord'
                            : 'projectEntry',
                        entityId: recordId!,
                      ),
                    ),
                  ),
                  child: Text(s.history),
                ),
                ChangeButton(
                  label: s.delete,
                  danger: true,
                  onPressed: () async {
                    if (!await confirmChange(
                          context,
                          s.delete,
                          s.deleteRecordWarning,
                        ) ||
                        !context.mounted) {
                      return;
                    }
                    if (await performChange(
                          context,
                          () => widget.controller.repository.deleteRecord(
                            widget.project.id,
                            recordId!,
                          ),
                        ) &&
                        mounted) {
                      setState(() => dirty = false);
                      await WidgetsBinding.instance.endOfFrame;
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                Text(
                  '${s.createdAt}: ${DateTime.fromMillisecondsSinceEpoch(widget.balance?.createdAtMs ?? widget.entry!.createdAtMs, isUtc: true).toIso8601String()}',
                ),
                Text(
                  '${s.updatedAt}: ${DateTime.fromMillisecondsSinceEpoch(widget.balance?.updatedAtMs ?? widget.entry!.updatedAtMs, isUtc: true).toIso8601String()}',
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
