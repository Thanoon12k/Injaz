import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../screens/task_sheet.dart';
import '../store.dart';
import '../theme.dart';

/// One task: priority bar, status button, title, small meta line.
/// Tap to expand details + checklist; swipe to delete.
class TaskCard extends StatefulWidget {
  final Task task;
  final bool showDate;
  const TaskCard({super.key, required this.task, this.showDate = false});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _open = false;
  final _sub = TextEditingController();

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  Task get t => widget.task;

  void _addSub() {
    final v = _sub.text.trim();
    if (v.isEmpty) return;
    t.subtasks.add(Subtask(title: v));
    _sub.clear();
    AppStore.I.updateTask(t);
  }

  void _delete(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    AppStore.I.deleteTask(t);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Deleted "${t.title}"'),
        action: SnackBarAction(label: 'UNDO', onPressed: () => AppStore.I.restoreTask(t)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final pc = priorityColor[t.priority] ?? Colors.grey;
    final sc = statusColor[t.status] ?? Colors.grey;
    final done = t.isDone;
    final meta = <Widget>[
      if (widget.showDate) _chip(Icons.event, _niceDate(t.dateAssigned)),
      if (t.dueTime.isNotEmpty) _chip(Icons.schedule, t.dueTime),
      if (t.tag.isNotEmpty) _chip(Icons.sell_outlined, t.tag),
      if (t.subtasks.isNotEmpty) _chip(Icons.checklist_rounded, '${t.subDone}/${t.subtasks.length}'),
      if (t.status == 'in_progress') _chip(Icons.autorenew, 'In progress', color: InjazColors.warning),
    ];

    return Dismissible(
      key: ValueKey('task-${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: InjazColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(context),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: done ? 0.7 : 1,
        child: Material(
          color: Colors.white,
          elevation: 1.5,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(width: 5, color: pc),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        GestureDetector(
                          onLongPress: () => _statusMenu(context),
                          child: IconButton(
                            tooltip: 'Tap: next status · Hold: choose',
                            onPressed: () => AppStore.I.cycleStatus(t),
                            icon: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? sc : Colors.transparent,
                                border: Border.all(color: sc, width: 2.5),
                              ),
                              child: done
                                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                                  : t.status == 'in_progress'
                                      ? Center(
                                          child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(color: sc, shape: BoxShape.circle)))
                                      : null,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(
                              t.title,
                              textDirection: dirOf(t.title),
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w600,
                                color: done ? InjazColors.textGrey : InjazColors.textDark,
                                decoration: done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (meta.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(spacing: 10, runSpacing: 2, children: meta),
                              ),
                          ]),
                        ),
                        Icon(_open ? Icons.expand_less : Icons.expand_more, color: Colors.black26),
                      ]),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: _open ? _details(context) : const SizedBox(width: double.infinity),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 0, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (t.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(t.description,
                textDirection: dirOf(t.description),
                style: const TextStyle(color: InjazColors.textGrey, fontSize: 14.5, height: 1.4)),
          ),
        for (final s in t.subtasks)
          Row(children: [
            Checkbox(
              value: s.done,
              activeColor: InjazColors.primary,
              visualDensity: VisualDensity.compact,
              onChanged: (v) {
                s.done = v ?? false;
                AppStore.I.updateTask(t);
              },
            ),
            Expanded(
              child: Text(s.title,
                  textDirection: dirOf(s.title),
                  style: TextStyle(
                    decoration: s.done ? TextDecoration.lineThrough : null,
                    color: s.done ? Colors.black38 : InjazColors.textDark,
                  )),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18, color: Colors.black26),
              onPressed: () {
                t.subtasks.remove(s);
                AppStore.I.updateTask(t);
              },
            ),
          ]),
        Row(children: [
          const SizedBox(width: 12),
          const Icon(Icons.add, size: 18, color: InjazColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _sub,
              decoration: const InputDecoration(
                hintText: 'Add checklist item',
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _addSub(),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Wrap(spacing: 4, children: [
          TextButton.icon(
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            onPressed: () => showTaskSheet(context, task: t),
          ),
          if (t.dateAssigned != todayKey())
            TextButton.icon(
              icon: const Icon(Icons.today_outlined, size: 18),
              label: const Text('Move to today'),
              onPressed: () => AppStore.I.moveToToday(t),
            ),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: InjazColors.error),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            onPressed: () => _delete(context),
          ),
        ]),
      ]),
    );
  }

  Future<void> _statusMenu(BuildContext context) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in statusLabel.entries)
            ListTile(
              leading: Icon(Icons.circle, color: statusColor[e.key]),
              title: Text(e.value),
              trailing: t.status == e.key ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(c, e.key),
            ),
        ]),
      ),
    );
    if (v != null) AppStore.I.setStatus(t, v);
  }
}

Widget _chip(IconData icon, String text, {Color color = InjazColors.textGrey}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12.5, color: color)),
      ],
    );

String _niceDate(String key) {
  final d = DateTime.tryParse(key);
  if (d == null) return key;
  final today = DateTime.now();
  final diff = DateTime(today.year, today.month, today.day).difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  return DateFormat('d MMM').format(d);
}
