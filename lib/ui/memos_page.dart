import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/business_date.dart';
import '../data/app_database.dart';
import '../data/finance_repository.dart';
import '../data/ledger_workspace.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';
import 'history_page.dart';

class MemosPage extends StatefulWidget {
  const MemosPage({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<MemosPage> createState() => _MemosPageState();
}

class _MemosPageState extends State<MemosPage> {
  String keyword = '';
  String? tag;
  int visibleRecords = 50;
  void edit([MemoRow? memo]) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MemoEditor(controller: widget.controller, memo: memo),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final ledger = widget.controller.ledger!;
        final tags = ledger.memos.expand(memoTags).toSet().toList()..sort();
        final selectedTag = tags.contains(tag) ? tag : null;
        final memos = ledger.searchMemos(keyword, selectedTag);
        return Scaffold(
          appBar: AppBar(title: Text(s.memos)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FilledButton.icon(
                key: const Key('new-memo'),
                onPressed: edit,
                icon: const Icon(Icons.add),
                label: Text(s.newMemo),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('memo-search'),
                decoration: InputDecoration(
                  labelText: s.searchMemos,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() {
                  keyword = v;
                  visibleRecords = 50;
                }),
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(s.all),
                    selected: selectedTag == null,
                    onSelected: (_) => setState(() {
                      tag = null;
                      visibleRecords = 50;
                    }),
                  ),
                  for (final t in tags)
                    ChoiceChip(
                      key: Key('memo-tag-$t'),
                      label: Text(t),
                      selected: selectedTag == t,
                      onSelected: (_) => setState(() {
                        tag = t;
                        visibleRecords = 50;
                      }),
                    ),
                ],
              ),
              if (memos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.noMemos),
                ),
              for (final m in memos.take(visibleRecords))
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: ListTile(
                    key: Key('memo-${m.id}'),
                    title: Text(m.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.businessDate),
                        Text(
                          m.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final t in memoTags(m)) Chip(label: Text(t)),
                          ],
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => edit(m),
                  ),
                ),
              if (memos.length > visibleRecords)
                TextButton(
                  key: const Key('more-memos'),
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

class MemoEditor extends StatefulWidget {
  const MemoEditor({super.key, required this.controller, this.memo});
  final FinanceController controller;
  final MemoRow? memo;
  @override
  State<MemoEditor> createState() => _MemoEditorState();
}

class _MemoEditorState extends State<MemoEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      body = TextEditingController(),
      tags = TextEditingController(),
      date = TextEditingController(),
      time = TextEditingController(text: '00:00');
  bool dirty = false, saving = false;
  @override
  void initState() {
    super.initState();
    final m = widget.memo;
    title.text = m?.title ?? '';
    body.text = m?.body ?? '';
    tags.text = m == null ? '' : memoTags(m).join(', ');
    date.text = m?.businessDate ?? bookNow(widget.controller).date.toString();
  }

  void changed() => setState(() => dirty = true);
  List<String> get tagValues => tags.text
      .split(RegExp('[,，\\n]'))
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toSet()
      .toList();
  @override
  void dispose() {
    for (final c in [title, body, tags, date, time]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await performChange(context, () async {
      await widget.controller.repository.saveMemo(
        id: widget.memo?.id,
        title: title.text,
        body: body.text,
        date: BusinessDate.parse(date.text.trim()),
        tags: tagValues,
      );
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (ok) dirty = false;
    });
    if (ok) {
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
        appBar: AppBar(title: Text(widget.memo == null ? s.newMemo : s.memos)),
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                key: const Key('memo-title'),
                controller: title,
                maxLength: 200,
                onChanged: (_) => changed(),
                decoration: InputDecoration(labelText: s.memoTitle),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? s.memoTextError : null,
              ),
              TextFormField(
                key: const Key('memo-body'),
                controller: body,
                maxLines: 8,
                minLines: 4,
                maxLength: 20000,
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText: s.memoBody,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              MomentFields(
                date: date,
                time: time,
                controller: widget.controller,
                changed: changed,
                includeTime: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('memo-tags'),
                controller: tags,
                maxLines: 2,
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText: s.tags,
                  helperText: s.tagsHint,
                  helperMaxLines: 3,
                ),
                validator: (_) =>
                    tagValues.length > 10 || tagValues.any((t) => t.length > 30)
                    ? s.tagError
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('save-memo'),
                onPressed: saving ? null : save,
                child: Text(s.save),
              ),
              if (widget.memo case final m?) ...[
                Text(
                  '${s.createdAt}: ${DateTime.fromMillisecondsSinceEpoch(m.createdAtMs, isUtc: true).toIso8601String()}',
                ),
                Text(
                  '${s.updatedAt}: ${DateTime.fromMillisecondsSinceEpoch(m.updatedAtMs, isUtc: true).toIso8601String()}',
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        controller: widget.controller,
                        entityType: 'memo',
                        entityId: m.id,
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
                          s.deleteMemoWarning,
                        ) &&
                        context.mounted) {
                      final ok = await performChange(
                        context,
                        () => widget.controller.repository.deleteMemo(m.id),
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
  }
}
