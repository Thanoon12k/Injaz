import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/task_card.dart';
import 'task_lists.dart';
import 'task_sheet.dart';

/// Main Injaz screen: today's tasks and nothing else.
class InjazToday extends StatefulWidget {
  const InjazToday({super.key});
  @override
  State<InjazToday> createState() => _InjazTodayState();
}

class _InjazTodayState extends State<InjazToday> {
  final _input = TextEditingController();
  bool _showDone = false;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _quickAdd() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    AppStore.I.addTask(Task(title: v));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final s = AppStore.I;
        final all = s.todayTasks;
        final open = all.where((t) => !t.isDone).toList();
        final done = all.where((t) => t.isDone).toList();
        final past = s.pastUnfinished.length;
        final progress = all.isEmpty ? 0.0 : done.length / all.length;

        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList.list(children: [
                Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 2),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Today',
                      style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (all.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${done.length} of ${all.length} done',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                ]),
                if (all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: progress),
                        duration: const Duration(milliseconds: 400),
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 5,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _QuickAdd(controller: _input, onSubmit: _quickAdd, onMore: () {
                  final hint = _input.text.trim();
                  _input.clear();
                  showTaskSheet(context, hint: hint);
                }),
                if (past > 0)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ActionChip(
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                        shape: const StadiumBorder(),
                        avatar: const Icon(Icons.move_to_inbox_outlined, color: Colors.white, size: 18),
                        label: Text('$past unfinished from earlier',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const PastTasksScreen())),
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
              ]),
            ),
            if (all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Text('No tasks yet.\nAdd one above! 🎯',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 19, height: 1.6)),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: open.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => TaskCard(task: open[i]),
                ),
              ),
              if (open.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('All done for today 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (done.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.white, alignment: AlignmentDirectional.centerStart),
                      icon: Icon(_showDone ? Icons.expand_less : Icons.expand_more),
                      label: Text('Completed (${done.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () => setState(() => _showDone = !_showDone),
                    ),
                  ),
                ),
              if (_showDone)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.separated(
                    itemCount: done.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TaskCard(task: done[i]),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        );
      },
    );
  }
}

class _QuickAdd extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onMore;
  const _QuickAdd({required this.controller, required this.onSubmit, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: 0.95),
          shape: const StadiumBorder(),
          elevation: 2,
          shadowColor: Colors.black26,
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: const TextStyle(fontSize: 17, color: InjazColors.textDark),
            decoration: const InputDecoration(
              hintText: 'Enter your today task…',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 22, vertical: 17),
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => controller.text.trim().isEmpty ? onMore() : onSubmit(),
          onLongPress: onMore,
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add_rounded, size: 32, color: InjazColors.primary),
          ),
        ),
      ),
    ]);
  }
}
