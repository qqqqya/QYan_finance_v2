import 'package:flutter/material.dart';

import '../app/finance_controller.dart';
import '../l10n/app_localizations.dart';
import 'finance_widgets.dart';

class SortProjectsPage extends StatefulWidget {
  const SortProjectsPage({super.key, required this.controller});
  final FinanceController controller;
  @override
  State<SortProjectsPage> createState() => _SortProjectsPageState();
}

class _SortProjectsPageState extends State<SortProjectsPage> {
  late List<String> ids = widget.controller.projects.map((p) => p.id).toList();
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(s.sortProjects)),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(20),
        buildDefaultDragHandles: false,
        itemCount: ids.length,
        onReorderItem: (oldIndex, newIndex) async {
          if (busy) return;
          final next = [...ids];
          final id = next.removeAt(oldIndex);
          next.insert(newIndex, id);
          setState(() {
            ids = next;
            busy = true;
          });
          final success = await performChange(
            context,
            () => widget.controller.repository.reorderProjects(next),
          );
          if (mounted) {
            setState(() {
              busy = false;
              if (!success) {
                ids = widget.controller.projects.map((p) => p.id).toList();
              }
            });
          }
        },
        itemBuilder: (context, index) {
          final p = widget.controller.workspace!.project(ids[index]);
          return Card(
            key: ValueKey(ids[index]),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(p == null ? s.missingProject : projectTitle(s, p)),
              subtitle: p == null ? null : Text(typeTitle(s, p.type)),
              trailing: ReorderableDragStartListener(
                index: index,
                enabled: !busy,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.drag_handle, semanticLabel: s.sortHint),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
