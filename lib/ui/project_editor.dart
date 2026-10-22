import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../core/business_date.dart';
import '../core/money.dart';
import '../data/app_database.dart';
import '../data/workspace.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';

class ProjectEditor extends StatefulWidget {
  const ProjectEditor({super.key, required this.controller, this.project});
  final FinanceController controller;
  final ProjectRow? project;
  @override
  State<ProjectEditor> createState() => _ProjectEditorState();
}

class _ProjectEditorState extends State<ProjectEditor> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      note = TextEditingController(),
      customCategory = TextEditingController();
  final amount = TextEditingController(text: '0'),
      date = TextEditingController(),
      time = TextEditingController();
  late String type, category, icon, color;
  String originalName = '';
  late bool included;
  bool dirty = false, saving = false, initializedName = false;
  @override
  void initState() {
    super.initState();
    final p = widget.project;
    type = p?.type ?? 'asset';
    category = p?.categoryKey ?? 'bank';
    icon = p?.iconKey ?? 'bank';
    color = p?.colorKey ?? 'neutral';
    included = p?.includeInSummary ?? true;
    note.text = p?.note ?? '';
    if (![
      'bank',
      'wallet',
      'cash',
      'fund',
      'investment',
      'liability',
      'income',
      'expense',
      'other',
    ].contains(category)) {
      customCategory.text = category.startsWith('custom:')
          ? category.substring(7)
          : category;
      category = 'other';
    }
    final now = bookNow(widget.controller);
    date.text = now.date.toString();
    time.text = now.time;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initializedName) {
      initializedName = true;
      originalName = widget.project == null
          ? ''
          : projectTitle(AppLocalizations.of(context)!, widget.project!);
      name.text = originalName;
    }
  }

  void changed() => setState(() => dirty = true);
  @override
  void dispose() {
    for (final c in [name, note, customCategory, amount, date, time]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    String? createdId;
    final success = await performChange(context, () async {
      final draft = ProjectDraft(
        name: name.text,
        type: type,
        categoryKey: customCategory.text.trim().isEmpty
            ? category
            : 'custom:${customCategory.text.trim()}',
        iconKey: icon,
        colorKey: color,
        included: included,
        note: note.text,
        initialMinor: widget.project == null && isBalanceType(type)
            ? parseMoneyMinor(amount.text)
            : 0,
        initialMoment: BusinessMoment(BusinessDate.parse(date.text), time.text),
        keepBuiltInName: name.text.trim() == originalName,
      );
      if (widget.project == null) {
        createdId = await widget.controller.repository.createProject(draft);
      } else {
        await widget.controller.repository.editProject(
          widget.project!.id,
          draft,
        );
      }
    });
    if (!mounted) return;
    setState(() {
      saving = false;
      if (success) dirty = false;
    });
    if (success) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context, createdId ?? widget.project!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    final locked =
        widget.project != null &&
        widget.controller.workspace!.hasRecords(widget.project!.id);
    return UnsavedChangesGuard(
      dirty: dirty,
      saving: saving,
      onSave: save,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.project == null ? s.newProject : s.editProject),
        ),
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                key: const Key('project-name'),
                controller: name,
                maxLength: 80,
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText: s.name,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? s.invalidName : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('project-type'),
                initialValue: type,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: s.projectType,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final t in [
                    'asset',
                    'liability',
                    'income_log',
                    'expense_log',
                  ])
                    DropdownMenuItem(value: t, child: Text(typeTitle(s, t))),
                ],
                onChanged: locked || saving
                    ? null
                    : (v) {
                        if (v != null) {
                          setState(() {
                            type = v;
                            dirty = true;
                          });
                        }
                      },
              ),
              if (locked)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(s.typeLocked),
                ),
              const SizedBox(height: 20),
              Text(s.category, style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (final key in [
                    'bank',
                    'wallet',
                    'cash',
                    'fund',
                    'investment',
                    'other',
                  ])
                    ChoiceChip(
                      label: Text(categoryTitle(s, key)),
                      selected: category == key && customCategory.text.isEmpty,
                      onSelected: (_) => setState(() {
                        category = key;
                        customCategory.clear();
                        dirty = true;
                      }),
                    ),
                ],
              ),
              TextFormField(
                key: const Key('custom-category'),
                controller: customCategory,
                maxLength: 80,
                onChanged: (_) => changed(),
                decoration: InputDecoration(labelText: s.customCategory),
              ),
              const SizedBox(height: 16),
              Text(s.icon, style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 4,
                children: [
                  for (final key in projectIcons.keys)
                    IconButton.filledTonal(
                      isSelected: icon == key,
                      tooltip: categoryTitle(s, key),
                      onPressed: () => setState(() {
                        icon = key;
                        dirty = true;
                      }),
                      icon: Icon(projectIcons[key]),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s.color, style: Theme.of(context).textTheme.titleMedium),
              Wrap(
                spacing: 6,
                children: [
                  for (final key in projectColors.keys)
                    ChoiceChip(
                      label: Text(colorTitle(s, key)),
                      avatar: CircleAvatar(
                        backgroundColor: projectColors[key],
                        radius: 6,
                      ),
                      selected: color == key,
                      onSelected: (_) => setState(() {
                        color = key;
                        dirty = true;
                      }),
                    ),
                ],
              ),
              if (isBalanceType(type))
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    type == 'asset' ? s.includeAsset : s.includeLiability,
                  ),
                  value: included,
                  onChanged: (v) => setState(() {
                    included = v;
                    dirty = true;
                  }),
                ),
              if (widget.project == null && isBalanceType(type)) ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('initial-amount'),
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => changed(),
                  decoration: InputDecoration(
                    labelText: '${s.initialBalance} · CNY',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    try {
                      parseMoneyMinor(v ?? '');
                      return null;
                    } catch (_) {
                      return s.invalidAmount;
                    }
                  },
                ),
                const SizedBox(height: 16),
                MomentFields(
                  date: date,
                  time: time,
                  controller: widget.controller,
                  changed: changed,
                ),
              ],
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('project-note'),
                controller: note,
                maxLines: 3,
                maxLength: 2000,
                onChanged: (_) => changed(),
                decoration: InputDecoration(
                  labelText: s.note,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('save-project'),
                onPressed: saving ? null : save,
                child: Text(s.save),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
