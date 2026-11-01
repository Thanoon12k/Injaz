import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/task_card.dart';

PreferredSizeWidget _bar(String title, {List<Widget>? actions}) => AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      backgroundColor: InjazColors.primary,
      foregroundColor: Colors.white,
      actions: actions,
    );

/// Unfinished tasks from previous days — bring them to today.
class PastTasksScreen extends StatelessWidget {
  const PastTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final list = AppStore.I.pastUnfinished;
        return Scaffold(
          backgroundColor: const Color(0xFFF1FAFB),
          appBar: _bar('Unfinished from earlier', actions: [
            if (list.isNotEmpty)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
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
              ? const _Empty('Nothing left behind 👏')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => Row(children: [
                    Expanded(child: TaskCard(task: list[i], showDate: true)),
                    IconButton(
                      tooltip: 'Move to today',
                      color: InjazColors.primary,
                      icon: const Icon(Icons.today_rounded),
                      onPressed: () => AppStore.I.moveToToday(list[i]),
                    ),
                  ]),
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
          rows.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: TaskCard(task: t)));
        }
        final total = AppStore.I.tasks.length;
        final done = AppStore.I.tasks.where((t) => t.isDone).length;
        return Scaffold(
          backgroundColor: const Color(0xFFF1FAFB),
          appBar: _bar('All tasks'),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                    hintText: 'Search tasks', prefixIcon: Icon(Icons.search), fillColor: Colors.white),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (final e in {'all': 'All ($total)', ...statusLabel}.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(e.key == 'completed' ? 'Completed ($done)' : e.value),
                        selected: _status == e.key,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _status = e.key),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? const _Empty('No tasks found')
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
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700, color: InjazColors.primaryDarker, fontSize: 14)),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(text, style: const TextStyle(color: InjazColors.textGrey, fontSize: 17)));
}
