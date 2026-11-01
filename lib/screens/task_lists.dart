import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/task_tile.dart';

/// Unfinished tasks from previous days — bring them to today.
class PastTasksScreen extends StatelessWidget {
  const PastTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final list = AppStore.I.pastUnfinished;
        return Scaffold(
          appBar: AppBar(title: const Text('Unfinished from earlier'), actions: [
            if (list.isNotEmpty)
              TextButton(
                onPressed: () {
                  for (final t in list) {
                    AppStore.I.moveToToday(t);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Move all to today'),
              ),
          ]),
          body: list.isEmpty
              ? Center(child: Text('Nothing left behind 👏', style: TextStyle(color: p.muted, fontSize: 16)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => TaskTile(task: list[i], showDate: true),
                ),
        );
      },
    );
  }
}

/// Every task, grouped by day, with search and a status filter.
class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});
  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  String _q = '';
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final list = AppStore.I.allTasks.where((t) {
          if (_status != 'all' && t.status != _status) return false;
          if (q.isEmpty) return true;
          return t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q) ||
              t.tag.toLowerCase().contains(q);
        }).toList();
        final rows = <Widget>[];
        String? day;
        for (final t in list) {
          if (t.dateAssigned != day) {
            day = t.dateAssigned;
            rows.add(_DayHeader(day));
          }
          rows.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: TaskTile(task: t)));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('All tasks')),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Search tasks', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                children: [
                  for (final e in {'all': 'All', ...statusLabel}.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _status == e.key,
                        showCheckmark: false,
                        selectedColor: p.taskSoft,
                        onSelected: (_) => setState(() => _status = e.key),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(child: Text('No tasks found', style: TextStyle(color: p.muted)))
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: rows),
            ),
          ]),
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(day);
    final label = day == todayKey()
        ? 'Today'
        : d == null
            ? day
            : DateFormat('EEEE, d MMM yyyy').format(d);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: context.pal.muted, fontSize: 13.5)),
    );
  }
}
