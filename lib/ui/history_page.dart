import 'dart:convert';

import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.controller,
    required this.entityType,
    required this.entityId,
  });
  final FinanceController controller;
  final String entityType, entityId;
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final stream = widget.controller.repository.watchHistory(
    widget.entityType,
    widget.entityId,
  );
  String label(AppLocalizations s, String key) => switch (key) {
    'balanceMinor' => s.balanceAmount,
    'amountMinor' => s.entryAmount,
    'businessDate' => s.businessDate,
    'businessTime' => s.businessTime,
    'customName' || 'nameKey' => s.name,
    'type' =>
      widget.entityType == 'bill' || widget.entityType == 'category'
          ? '${s.income} / ${s.expense}'
          : s.projectType,
    'categoryId' => s.category,
    'isActive' => s.categoryActive,
    'title' => s.memoTitle,
    'body' => s.memoBody,
    'tags' => s.tags,
    'categoryKey' => s.category,
    'iconKey' => s.icon,
    'colorKey' => s.color,
    'includeInSummary' =>
      widget.controller.workspace?.project(widget.entityId)?.type == 'liability'
          ? s.includeLiability
          : s.includeAsset,
    'note' => s.note,
    _ => '',
  };
  String value(
    AppLocalizations s,
    String field,
    Object? value,
    Map<String, dynamic> payload,
  ) {
    if (value == null || value == '') return '—';
    if (field == 'balanceMinor' || field == 'amountMinor') {
      return '¥${formatMoneyMinor(value as int)}';
    }
    if (field == 'type') {
      return widget.entityType == 'bill' || widget.entityType == 'category'
          ? directionTitle(s, value as String)
          : typeTitle(s, value as String);
    }
    if (field == 'nameKey') {
      return widget.entityType == 'category'
          ? s.billCategoryName(value as String)
          : s.projectName(value as String);
    }
    if (field == 'categoryId') {
      return payload['categoryCustomName'] as String? ??
          s.billCategoryName(payload['categoryNameKey'] as String? ?? '');
    }
    if (field == 'tags' && value is List) return value.join(', ');
    if (field == 'categoryKey' || field == 'iconKey') {
      return categoryTitle(s, value as String);
    }
    if (field == 'colorKey') return colorTitle(s, value as String);
    if (value is bool) return value ? '✓' : '—';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.history)),
      body: StreamBuilder<List<EditHistoryRow>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(s.dataError));
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(s.historyDeleteWarning),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.historyEmpty),
                ),
              if (rows.isNotEmpty)
                ChangeButton(
                  label: s.clearHistory,
                  danger: true,
                  onPressed: () async {
                    if (await confirmChange(
                          context,
                          s.clearHistory,
                          s.historyDeleteWarning,
                        ) &&
                        context.mounted) {
                      await performChange(
                        context,
                        () => widget.controller.repository.clearHistory(
                          widget.entityType,
                          widget.entityId,
                        ),
                      );
                    }
                  },
                ),
              for (final row in rows) _historyCard(context, row),
            ],
          );
        },
      ),
    );
  }

  Widget _historyCard(BuildContext context, EditHistoryRow row) {
    final s = AppLocalizations.of(context)!;
    final before = jsonDecode(row.beforeJson) as Map<String, dynamic>;
    final after = jsonDecode(row.afterJson) as Map<String, dynamic>;
    final fields = {
      ...before.keys,
      ...after.keys,
    }.where((key) => label(s, key).isNotEmpty && before[key] != after[key]);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.changedAt}\n${DateTime.fromMillisecondsSinceEpoch(row.changedAtMs, isUtc: true).toIso8601String()}',
            ),
            for (final field in fields)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label(s, field),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SelectableText(
                      '${s.before}: ${value(s, field, before[field], before)}',
                    ),
                    SelectableText(
                      '${s.after}: ${value(s, field, after[field], after)}',
                    ),
                  ],
                ),
              ),
            ChangeButton(
              key: Key('delete-history-${row.id}'),
              label: s.delete,
              danger: true,
              onPressed: () async {
                if (await confirmChange(
                      context,
                      s.delete,
                      s.deleteHistoryWarning,
                    ) &&
                    context.mounted) {
                  await performChange(
                    context,
                    () => widget.controller.repository.deleteHistory(row.id),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
