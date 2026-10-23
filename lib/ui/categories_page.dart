import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../data/app_database.dart';
import '../data/finance_repository.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';
import 'history_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key, required this.controller});
  final FinanceController controller;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(s.categories)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FilledButton.icon(
              key: const Key('new-category'),
              icon: const Icon(Icons.add),
              label: Text(s.newCategory),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryEditor(controller: controller),
                ),
              ),
            ),
            for (final type in ['expense', 'income']) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  directionTitle(s, type),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final c in controller.ledger!.categories.where(
                (c) => c.type == type,
              ))
                Card(
                  child: ListTile(
                    key: Key('category-${c.id}'),
                    title: Text(billCategoryTitle(s, c)),
                    subtitle: Text(
                      c.isActive ? s.categoryActive : s.categoryInactive,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CategoryEditor(controller: controller, category: c),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({super.key, required this.controller, this.category});
  final FinanceController controller;
  final CategoryRow? category;
  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  final form = GlobalKey<FormState>(), name = TextEditingController();
  String type = 'expense', originalName = '';
  bool active = true, dirty = false, saving = false, initialized = false;
  @override
  void initState() {
    super.initState();
    type = widget.category?.type ?? 'expense';
    active = widget.category?.isActive ?? true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      name.text = widget.category == null
          ? ''
          : billCategoryTitle(AppLocalizations.of(context)!, widget.category!);
      originalName = name.text;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() => saving = true);
    final ok = await performChange(context, () async {
      await widget.controller.repository.saveCategory(
        id: widget.category?.id,
        name: name.text,
        type: type,
        active: active,
        keepBuiltInName:
            widget.category?.nameKey != null &&
            name.text.trim() == originalName,
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

  Future<void> delete() async {
    final s = AppLocalizations.of(context)!, c = widget.category!;
    final referenced = widget.controller.ledger!.bills.any(
      (b) => b.categoryId == c.id,
    );
    String? replacement;
    if (referenced) {
      final targets = widget.controller.ledger!.categories
          .where((t) => t.id != c.id && t.type == c.type && t.isActive)
          .toList();
      if (targets.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.categoryReferenced)));
        return;
      }
      replacement = await showDialog<String>(
        context: context,
        builder: (context) {
          String selected = targets.first.id;
          return StatefulBuilder(
            builder: (context, update) => AlertDialog(
              scrollable: true,
              title: Text(s.moveAndDelete),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s.moveCategoryWarning),
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: s.replacementCategory,
                    ),
                    items: [
                      for (final t in targets)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(billCategoryTitle(s, t)),
                        ),
                    ],
                    onChanged: (v) => update(() => selected = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  key: const Key('confirm-move-category'),
                  onPressed: () => Navigator.pop(context, selected),
                  child: Text(s.moveAndDelete),
                ),
              ],
            ),
          );
        },
      );
      if (replacement == null) return;
    } else {
      if (!await confirmChange(context, s.delete, s.categoryDeleteWarning)) {
        return;
      }
    }
    if (!mounted) return;
    final ok = await performChange(
      context,
      () => widget.controller.repository.deleteCategory(
        c.id,
        replacementId: replacement,
      ),
    );
    if (ok && mounted) {
      setState(() => dirty = false);
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
          title: Text(widget.category == null ? s.newCategory : s.category),
        ),
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                key: const Key('category-name'),
                controller: name,
                maxLength: 80,
                decoration: InputDecoration(labelText: s.name),
                onChanged: (_) => setState(() => dirty = true),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? s.invalidName : null,
              ),
              DropdownButtonFormField<String>(
                key: const Key('category-type'),
                initialValue: type,
                items: [
                  for (final t in ['expense', 'income'])
                    DropdownMenuItem(
                      value: t,
                      child: Text(directionTitle(s, t)),
                    ),
                ],
                onChanged: widget.category != null
                    ? null
                    : (v) => setState(() {
                        type = v!;
                        dirty = true;
                      }),
              ),
              if (widget.category != null) Text(s.categoryFixed),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.categoryActive),
                value: active,
                onChanged: (v) => setState(() {
                  active = v;
                  dirty = true;
                }),
              ),
              FilledButton(
                key: const Key('save-category'),
                onPressed: saving ? null : save,
                child: Text(s.save),
              ),
              if (widget.category case final c?) ...[
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryPage(
                        controller: widget.controller,
                        entityType: 'category',
                        entityId: c.id,
                      ),
                    ),
                  ),
                  child: Text(s.history),
                ),
                ChangeButton(label: s.delete, danger: true, onPressed: delete),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
