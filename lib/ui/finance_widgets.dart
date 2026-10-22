import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/business_date.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/workspace.dart';
import '../l10n/app_localizations.dart';

String projectTitle(AppLocalizations s, ProjectRow p) =>
    p.customName ?? s.projectName(p.nameKey ?? '');
String typeTitle(AppLocalizations s, String type) => switch (type) {
  'asset' => s.typeAsset,
  'liability' => s.typeLiability,
  'income_log' => s.typeIncome,
  _ => s.typeExpense,
};
const projectIcons = <String, IconData>{
  'bank': Icons.account_balance_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'cash': Icons.payments_outlined,
  'fund': Icons.pie_chart_outline,
  'investment': Icons.trending_up,
  'liability': Icons.credit_card,
  'income': Icons.south_west,
  'expense': Icons.north_east,
};
const projectColors = <String, Color>{
  'neutral': Color(0xFF747480),
  'blue': Color(0xFF3976C4),
  'green': Color(0xFF008C64),
  'purple': Color(0xFF9166C3),
  'orange': Color(0xFFE48932),
  'red': Color(0xFFE34C55),
};
String categoryTitle(AppLocalizations s, String key) {
  if (key.startsWith('custom:')) return key.substring(7);
  return switch (key) {
    'bank' => s.bankCategory,
    'wallet' => s.walletCategory,
    'cash' => s.projectName('cash'),
    'fund' => s.projectName('fund'),
    'investment' => s.projectName('investment'),
    'liability' => s.typeLiability,
    'income' => s.typeIncome,
    'expense' => s.typeExpense,
    'other' => s.otherCategory,
    _ => key,
  };
}

String colorTitle(AppLocalizations s, String key) => switch (key) {
  'blue' => s.colorBlue,
  'green' => s.colorGreen,
  'purple' => s.colorPurple,
  'orange' => s.colorOrange,
  'red' => s.colorRed,
  _ => s.colorNeutral,
};
BusinessMoment bookNow(FinanceController controller) => BusinessMoment.inZone(
  controller.repository.clock(),
  controller.settings!.timeZone,
);

String validationMessage(AppLocalizations s, Object error) =>
    error is FinanceValidation
    ? switch (error.code) {
        'name' => s.invalidName,
        'amount' => s.invalidAmount,
        'future' => s.futureDate,
        'lockedType' => s.typeLocked,
        'text' => s.invalidText,
        'staleOrder' => s.staleOrder,
        'missing' => s.missingProject,
        _ => s.operationFailed,
      }
    : s.operationFailed;

Future<bool> performChange(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            validationMessage(AppLocalizations.of(context)!, error),
          ),
        ),
      );
    }
    return false;
  }
}

Future<bool> confirmChange(
  BuildContext context,
  String title,
  String body,
) async {
  final s = AppLocalizations.of(context)!;
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              key: const Key('confirm-delete'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.delete),
            ),
          ],
        ),
      ) ??
      false;
}

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.size = 28,
    this.color,
    this.signed = false,
  });
  final int amount;
  final double size;
  final Color? color;
  final bool signed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'CNY ${formatMoneyMinor(amount)}',
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '${signed && amount > 0 ? '+' : ''}¥${formatMoneyMinor(amount)}',
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

class ChangeButton extends StatefulWidget {
  const ChangeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });
  final String label;
  final Future<void> Function() onPressed;
  final bool danger;
  @override
  State<ChangeButton> createState() => _ChangeButtonState();
}

class _ChangeButtonState extends State<ChangeButton> {
  bool running = false;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: widget.danger
        ? OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          )
        : null,
    onPressed: running
        ? null
        : () async {
            setState(() => running = true);
            try {
              await widget.onPressed();
            } finally {
              if (mounted) setState(() => running = false);
            }
          },
    child: Text(widget.label),
  );
}

class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
    required this.child,
  });
  final bool dirty, saving;
  final Future<void> Function() onSave;
  final Widget child;
  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  bool allowed = false, asking = false;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowed || (!widget.dirty && !widget.saving),
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || asking || widget.saving) return;
      asking = true;
      final s = AppLocalizations.of(context)!;
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.unsavedTitle),
          content: Text(s.unsavedBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.continueEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: Text(s.discard),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, 'save'),
              child: Text(s.save),
            ),
          ],
        ),
      );
      asking = false;
      if (!mounted) return;
      if (action == 'save') await widget.onSave();
      if (action == 'discard' && mounted) {
        setState(() => allowed = true);
        await WidgetsBinding.instance.endOfFrame;
        if (context.mounted) Navigator.pop(context);
      }
    },
    child: widget.child,
  );
}

class MomentFields extends StatelessWidget {
  const MomentFields({
    super.key,
    required this.date,
    required this.time,
    required this.controller,
    required this.changed,
  });
  final TextEditingController date, time;
  final FinanceController controller;
  final VoidCallback changed;
  BusinessMoment get moment =>
      BusinessMoment(BusinessDate.parse(date.text.trim()), time.text.trim());
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    String? validate(String? _) {
      try {
        if (moment.compareTo(bookNow(controller)) > 0) return s.futureDate;
        return null;
      } catch (_) {
        return s.invalidDate;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.timeZone}: ${controller.settings!.timeZone}'),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('business-date'),
          controller: date,
          onChanged: (_) => changed(),
          keyboardType: TextInputType.datetime,
          validator: validate,
          decoration: InputDecoration(
            labelText: s.businessDate,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: s.businessDate,
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final now = bookNow(controller).date;
                var initial = DateTime(now.year, now.month, now.day);
                try {
                  final d = BusinessDate.parse(date.text);
                  initial = DateTime(d.year, d.month, d.day);
                } catch (_) {}
                final last = DateTime(now.year, now.month, now.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial.isAfter(last) ? last : initial,
                  firstDate: DateTime(1900),
                  lastDate: last,
                );
                if (picked != null) {
                  date.text = BusinessDate(
                    picked.year,
                    picked.month,
                    picked.day,
                  ).toString();
                  changed();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          key: const Key('business-time'),
          controller: time,
          onChanged: (_) => changed(),
          keyboardType: TextInputType.datetime,
          validator: validate,
          decoration: InputDecoration(
            labelText: s.businessTime,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: s.businessTime,
              icon: const Icon(Icons.schedule),
              onPressed: () async {
                final now = bookNow(controller).time.split(':');
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: int.parse(now[0]),
                    minute: int.parse(now[1]),
                  ),
                );
                if (picked != null) {
                  time.text =
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                  changed();
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
