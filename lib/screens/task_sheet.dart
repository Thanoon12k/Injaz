import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// Add / edit a task in a bottom sheet. Only the title is required.
Future<void> showTaskSheet(BuildContext context, {Task? task, String hint = ''}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _TaskSheet(task: task, hint: hint),
  );
}

class _TaskSheet extends StatefulWidget {
  final Task? task;
  final String hint;
  const _TaskSheet({this.task, this.hint = ''});
  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  late final _title = TextEditingController(text: widget.task?.title ?? widget.hint);
  late final _desc = TextEditingController(text: widget.task?.description ?? '');
  late final _tag = TextEditingController(text: widget.task?.tag ?? '');
  final _item = TextEditingController();
  late String _priority = widget.task?.priority ?? 'medium';
  late String _status = widget.task?.status ?? 'pending';
  late String _date = widget.task?.dateAssigned ?? todayKey();
  late String _time = widget.task?.dueTime ?? '';
  late final List<Subtask> _subs =
      (widget.task?.subtasks ?? []).map((s) => Subtask(id: s.id, title: s.title, done: s.done)).toList();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _more = t != null && (t.tag.isNotEmpty || t.status != 'pending' || t.dateAssigned != todayKey());
  }

  @override
  void dispose() {
    for (final c in [_title, _desc, _tag, _item]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    if (_item.text.trim().isNotEmpty) _subs.add(Subtask(title: _item.text.trim()));
    final t = widget.task;
    if (t == null) {
      AppStore.I.addTask(Task(
        title: title,
        description: _desc.text.trim(),
        priority: _priority,
        status: _status,
        tag: _tag.text.trim(),
        dateAssigned: _date,
        dueTime: _time,
        subtasks: _subs,
        completedAt: _status == 'completed' ? DateTime.now().toUtc() : null,
      ));
    } else {
      final wasDone = t.isDone;
      t
        ..title = title
        ..description = _desc.text.trim()
        ..priority = _priority
        ..status = _status
        ..tag = _tag.text.trim()
        ..dateAssigned = _date
        ..dueTime = _time
        ..subtasks = _subs;
      if (!wasDone && t.isDone) t.completedAt = DateTime.now().toUtc();
      if (!t.isDone) t.completedAt = null;
      AppStore.I.updateTask(t);
    }
    Navigator.pop(context);
  }

  Future<void> _pickTime() async {
    final parts = _time.split(':');
    final init = _time.isEmpty
        ? TimeOfDay.now()
        : TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final v = await showTimePicker(context: context, initialTime: init);
    if (v != null) {
      setState(() => _time = '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _pickDate() async {
    final v = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (v != null) setState(() => _date = DateFormat('yyyy-MM-dd').format(v));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.task != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(editing ? 'Edit task' : 'New task',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: InjazColors.textDark)),
          const SizedBox(height: 14),
          TextField(
            controller: _title,
            autofocus: !editing,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17),
            decoration: const InputDecoration(hintText: 'What needs to be done?'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _desc,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Details (optional)'),
          ),
          const SizedBox(height: 14),
          const _Label('Priority'),
          Wrap(spacing: 8, children: [
            for (final p in ['low', 'medium', 'high', 'urgent'])
              ChoiceChip(
                label: Text(priorityLabel[p]!),
                selected: _priority == p,
                avatar: CircleAvatar(backgroundColor: priorityColor[p], radius: 5),
                showCheckmark: false,
                selectedColor: priorityColor[p]!.withValues(alpha: 0.18),
                onSelected: (_) => setState(() => _priority = p),
              ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(_time.isEmpty ? 'Time' : _time),
                onPressed: _pickTime,
              ),
            ),
            if (_time.isNotEmpty)
              IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _time = '')),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(_more ? Icons.expand_less : Icons.tune, size: 18),
                label: Text(_more ? 'Less' : 'More'),
                onPressed: () => setState(() => _more = !_more),
              ),
            ),
          ]),
          if (_more) ...[
            const SizedBox(height: 12),
            const _Label('Status'),
            Wrap(spacing: 8, children: [
              for (final e in statusLabel.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _status == e.key,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _status = e.key),
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _tag,
                  decoration: const InputDecoration(hintText: 'Tag', prefixIcon: Icon(Icons.sell_outlined, size: 18)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_date == todayKey() ? 'Today' : _date),
                  onPressed: _pickDate,
                ),
              ),
            ]),
          ],
          const SizedBox(height: 14),
          const _Label('Checklist'),
          for (final s in _subs)
            Row(children: [
              const Icon(Icons.check_box_outline_blank, size: 18, color: Colors.black38),
              const SizedBox(width: 8),
              Expanded(child: Text(s.title)),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _subs.remove(s)),
              ),
            ]),
          TextField(
            controller: _item,
            decoration: const InputDecoration(hintText: 'Add item and press enter', prefixIcon: Icon(Icons.add)),
            onSubmitted: (v) {
              if (v.trim().isEmpty) return;
              setState(() {
                _subs.add(Subtask(title: v.trim()));
                _item.clear();
              });
            },
          ),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: InjazColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _title.text.trim().isEmpty ? null : _save,
            child: Text(editing ? 'Save' : 'Add task', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: InjazColors.textGrey)),
      );
}
