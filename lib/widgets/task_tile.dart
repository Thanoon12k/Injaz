import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../screens/task_sheet.dart';
import '../store.dart';
import '../theme.dart';

/// A task row: ring checkbox (colored by priority), title, small meta line.
/// Tap to open details + checklist. Swipe left to delete.
class TaskTile extends StatefulWidget {
  final Task task;
  final bool showDate;
  const TaskTile({super.key, required this.task, this.showDate = false});
  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  bool _open = false;
  final _sub = TextEditingController();

  Task get t => widget.task;

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  void _addSub() {
    final v = _sub.text.trim();
    if (v.isEmpty) return;
    t.subtasks.add(Subtask(title: v));
    _sub.clear();
    AppStore.I.updateTask(t);
  }

  void _delete() {
    final m = ScaffoldMessenger.of(context);
    AppStore.I.deleteTask(t);
    m
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Task deleted'),
        action: SnackBarAction(label: 'Undo', onPressed: () => AppStore.I.restoreTask(t)),
      ));
  }

  Future<void> _statusSheet() async {
    final p = context.pal;
    final v = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final e in statusLabel.entries)
            ListTile(
              leading: Icon(
                  e.key == 'completed'
                      ? Icons.check_circle
                      : e.key == 'in_progress'
                          ? Icons.timelapse
                          : Icons.radio_button_unchecked,
                  color: p.task),
              title: Text(e.value),
              trailing: t.status == e.key ? Icon(Icons.check, color: p.task) : null,
              onTap: () => Navigator.pop(c, e.key),
            ),
        ]),
      ),
    );
    if (v != null) AppStore.I.setStatus(t, v);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final done = t.isDone;
    final ring = priorityColor[t.priority] ?? p.muted;
    final meta = <Widget>[
      if (t.status == 'in_progress') _meta(Icons.timelapse, 'Doing', p.task),
      if (widget.showDate) _meta(Icons.event_outlined, _niceDate(t.dateAssigned), p.muted),
      if (t.dueTime.isNotEmpty) _meta(Icons.schedule, t.dueTime, p.muted),
      if (t.tag.isNotEmpty) _meta(Icons.tag, t.tag, p.muted),
      if (t.subtasks.isNotEmpty) _meta(Icons.checklist, '${t.subDone}/${t.subtasks.length}', p.muted),
      if (t.description.isNotEmpty && !_open) _meta(Icons.notes, '', p.muted),
    ];

    return Dismissible(
      key: ValueKey('task-${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(color: p.danger, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(),
      child: Surface(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        onTap: () => setState(() => _open = !_open),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            InkResponse(
              radius: 24,
              onTap: () => AppStore.I.setStatus(t, done ? 'pending' : 'completed'),
              onLongPress: _statusSheet,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? p.task : Colors.transparent,
                    border: Border.all(color: done ? p.task : ring, width: 2),
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : t.status == 'in_progress'
                          ? Center(
                              child: Container(
                                  width: 10, height: 10, decoration: BoxDecoration(color: ring, shape: BoxShape.circle)))
                          : null,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.title,
                      textDirection: dirOf(t.title),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: done ? p.muted : p.ink,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: p.muted,
                      )),
                  if (meta.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(spacing: 10, runSpacing: 2, children: meta),
                    ),
                ]),
              ),
            ),
          ]),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topCenter,
            child: _open ? _details(p) : const SizedBox(width: double.infinity),
          ),
        ]),
      ),
    );
  }

  Widget _details(Palette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 0, 0, 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (t.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(t.description,
                textDirection: dirOf(t.description), style: TextStyle(color: p.muted, height: 1.45)),
          ),
        for (final s in t.subtasks)
          Row(children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: s.done,
                activeColor: p.task,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                onChanged: (v) {
                  s.done = v ?? false;
                  AppStore.I.updateTask(t);
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(s.title,
                  textDirection: dirOf(s.title),
                  style: TextStyle(
                    color: s.done ? p.muted : p.ink,
                    decoration: s.done ? TextDecoration.lineThrough : null,
                  )),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: p.muted),
              onPressed: () {
                t.subtasks.remove(s);
                AppStore.I.updateTask(t);
              },
            ),
          ]),
        Row(children: [
          Icon(Icons.add, size: 18, color: p.task),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _sub,
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Add a step',
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _addSub(),
            ),
          ),
        ]),
        Wrap(spacing: 2, children: [
          _action(Icons.edit_outlined, 'Edit', p.ink, () => showTaskSheet(context, task: t)),
          if (t.dateAssigned != todayKey())
            _action(Icons.today_outlined, 'Do today', p.task, () => AppStore.I.moveToToday(t)),
          _action(Icons.timelapse, t.status == 'in_progress' ? 'Not doing' : 'Doing', p.ink,
              () => AppStore.I.setStatus(t, t.status == 'in_progress' ? 'pending' : 'in_progress')),
          _action(Icons.delete_outline, 'Delete', p.danger, _delete),
        ]),
      ]),
    );
  }

  Widget _action(IconData i, String label, Color c, VoidCallback f) => TextButton.icon(
        style: TextButton.styleFrom(foregroundColor: c, visualDensity: VisualDensity.compact),
        icon: Icon(i, size: 17),
        label: Text(label),
        onPressed: f,
      );
}

Widget _meta(IconData icon, String text, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      if (text.isNotEmpty) ...[
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12.5, color: color)),
      ],
    ]);

String _niceDate(String key) {
  final d = DateTime.tryParse(key);
  if (d == null) return key;
  final n = DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(d).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff == -1) return 'Tomorrow';
  return DateFormat('d MMM').format(d);
}
