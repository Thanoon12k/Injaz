import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/idea_tile.dart';
import '../widgets/task_tile.dart';
import 'idea_editor.dart';
import 'ideas_screen.dart';
import 'settings.dart';
import 'task_lists.dart';
import 'task_sheet.dart';

/// The one screen: capture anything, see today's tasks and your latest ideas.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  bool _idea = false; // what the capture bar adds
  bool _showDone = false;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final v = _input.text.trim();
    if (v.isEmpty) {
      _more();
      return;
    }
    if (_idea) {
      AppStore.I.addIdea(Idea(title: v));
    } else {
      AppStore.I.addTask(Task(title: v));
    }
    _input.clear();
  }

  void _more() {
    final hint = _input.text.trim();
    _input.clear();
    _focus.unfocus();
    if (_idea) {
      _push(IdeaEditor(titleHint: hint));
    } else {
      showTaskSheet(context, hint: hint);
    }
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

  String _greeting() {
    final h = DateTime.now().hour;
    final g = h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
    final n = AppStore.I.displayName;
    return n.isEmpty ? g : '$g, $n';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppStore.I,
          builder: (context, _) {
            final s = AppStore.I;
            final today = s.todayTasks;
            final open = today.where((t) => !t.isDone).toList();
            final done = today.where((t) => t.isDone).toList();
            final earlier = s.pastUnfinished.length;
            final ideas = s.ideas;

            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList.list(children: [
                    // ── header ──
                    Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_greeting(), style: TextStyle(color: p.muted, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                              style: TextStyle(
                                  color: p.ink, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                        ]),
                      ),
                      _Avatar(onTap: () => _moreSheet(context)),
                    ]),
                    const SizedBox(height: 18),
                    // ── capture ──
                    _CaptureBar(
                      controller: _input,
                      focus: _focus,
                      idea: _idea,
                      onKind: (v) => setState(() => _idea = v),
                      onAdd: _add,
                      onMore: _more,
                    ),
                    if (earlier > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Surface(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          onTap: () => _push(const PastTasksScreen()),
                          child: Row(children: [
                            Icon(Icons.history, size: 19, color: p.task),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('$earlier unfinished from earlier days',
                                  style: TextStyle(color: p.ink, fontWeight: FontWeight.w500)),
                            ),
                            Icon(Icons.chevron_right, color: p.muted),
                          ]),
                        ),
                      ),
                    // ── today ──
                    SectionTitle('TODAY',
                        trailing: today.isEmpty
                            ? null
                            : _Progress(done: done.length, total: today.length)),
                  ]),
                ),
                if (today.isEmpty)
                  SliverToBoxAdapter(
                    child: _Empty(
                      icon: Icons.wb_sunny_outlined,
                      text: 'A clear day. Add the few things that matter.',
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.separated(
                      itemCount: open.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => TaskTile(task: open[i]),
                    ),
                  ),
                  if (open.isEmpty)
                    SliverToBoxAdapter(
                      child: _Empty(icon: Icons.celebration_outlined, text: 'Everything done for today. Nice work.'),
                    ),
                  if (done.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: p.muted),
                            icon: Icon(_showDone ? Icons.expand_less : Icons.expand_more, size: 20),
                            label: Text('Done (${done.length})'),
                            onPressed: () => setState(() => _showDone = !_showDone),
                          ),
                        ),
                      ),
                    ),
                  if (_showDone)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: done.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => TaskTile(task: done[i]),
                      ),
                    ),
                ],
                // ── ideas ──
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: SectionTitle('IDEAS',
                        trailing: ideas.length > 3
                            ? GestureDetector(
                                onTap: () => _push(const IdeasScreen()),
                                child: Text('See all ${ideas.length}',
                                    style: TextStyle(color: p.idea, fontWeight: FontWeight.w600, fontSize: 13.5)),
                              )
                            : null),
                  ),
                ),
                if (ideas.isEmpty)
                  SliverToBoxAdapter(
                    child: _Empty(
                      icon: Icons.lightbulb_outline,
                      text: 'Switch the bar above to Idea to catch a thought.',
                      color: p.idea,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.separated(
                      itemCount: ideas.length.clamp(0, 3),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => IdeaTile(idea: ideas[i]),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 48)),
              ],
            );
          },
        ),
      ),
    );
  }

  void _moreSheet(BuildContext context) {
    final p = context.pal;
    final s = AppStore.I;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) {
        Widget item(IconData i, Color col, String t, Widget page, {String? badge}) => ListTile(
              leading: Icon(i, color: col),
              title: Text(t),
              trailing: badge == null ? Icon(Icons.chevron_right, color: p.muted) : Text(badge, style: TextStyle(color: p.muted)),
              onTap: () {
                Navigator.pop(c);
                _push(page);
              },
            );
        final syncText = switch (s.syncState) {
          SyncState.localOnly => 'Not signed in · saved on this phone',
          SyncState.syncing => 'Syncing…',
          SyncState.synced => 'Synced',
          SyncState.offline => 'Offline · will sync when connected',
        };
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const _Avatar(),
              title: Text(s.displayName.isEmpty ? 'You' : s.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(s.signedIn ? '${s.user!.email ?? ''}\n$syncText' : syncText),
              isThreeLine: s.signedIn,
            ),
            const Divider(),
            item(Icons.checklist, p.task, 'All tasks', const AllTasksScreen(), badge: '${s.tasks.length}'),
            item(Icons.history, p.task, 'Unfinished from earlier', const PastTasksScreen(),
                badge: '${s.pastUnfinished.length}'),
            item(Icons.lightbulb_outline, p.idea, 'All ideas', const IdeasScreen(), badge: '${s.ideas.length}'),
            item(Icons.settings_outlined, p.muted, 'Settings', const SettingsScreen()),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }
}

class _CaptureBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool idea;
  final ValueChanged<bool> onKind;
  final VoidCallback onAdd;
  final VoidCallback onMore;
  const _CaptureBar({
    required this.controller,
    required this.focus,
    required this.idea,
    required this.onKind,
    required this.onAdd,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final accent = idea ? p.idea : p.task;
    Widget kind(bool isIdea, IconData icon, String label) {
      final on = idea == isIdea;
      final c = isIdea ? p.idea : p.task;
      return GestureDetector(
        onTap: () => onKind(isIdea),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: on ? (isIdea ? p.ideaSoft : p.taskSoft) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 17, color: on ? c : p.muted),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(color: on ? c : p.muted, fontWeight: on ? FontWeight.w700 : FontWeight.w500)),
          ]),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
      child: Column(children: [
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, _) => TextField(
            controller: controller,
            focusNode: focus,
            minLines: 1,
            maxLines: 3,
            textDirection: v.text.isEmpty ? null : dirOf(v.text),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            style: TextStyle(fontSize: 17, color: p.ink),
            decoration: InputDecoration(
              hintText: idea ? 'What are you thinking?' : 'What will you do today?',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        Row(children: [
          kind(false, Icons.check_circle_outline, 'Task'),
          const SizedBox(width: 4),
          kind(true, Icons.lightbulb_outline, 'Idea'),
          const Spacer(),
          IconButton(
            tooltip: idea ? 'Photos, voice, details' : 'Time, priority, checklist',
            color: p.muted,
            icon: Icon(idea ? Icons.add_photo_alternate_outlined : Icons.tune),
            onPressed: onMore,
          ),
          const SizedBox(width: 2),
          Material(
            color: accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onAdd,
              child: const SizedBox(width: 42, height: 42, child: Icon(Icons.arrow_upward, color: Colors.white)),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Progress extends StatelessWidget {
  final int done, total;
  const _Progress({required this.done, required this.total});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$done of $total', style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      SizedBox(
        width: 18,
        height: 18,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: total == 0 ? 0 : done / total),
          duration: const Duration(milliseconds: 400),
          builder: (_, v, _) => CircularProgressIndicator(
            value: v,
            strokeWidth: 3,
            backgroundColor: p.line,
            valueColor: AlwaysStoppedAnimation(p.task),
          ),
        ),
      ),
    ]);
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Empty({required this.icon, required this.text, this.color});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(children: [
        Icon(icon, color: (color ?? p.task).withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: p.muted, fontSize: 14.5, height: 1.4))),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  final VoidCallback? onTap;
  const _Avatar({this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final s = AppStore.I;
    final url = s.avatarUrl;
    final n = s.displayName;
    final dot = switch (s.syncState) {
      SyncState.synced => p.task,
      SyncState.syncing => p.idea,
      SyncState.offline => p.danger,
      SyncState.localOnly => p.muted,
    };
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: p.taskSoft,
          foregroundImage: url == null ? null : NetworkImage(url),
          child: n.isEmpty
              ? Icon(Icons.person_outline, color: p.task)
              : Text(n.characters.first.toUpperCase(),
                  style: TextStyle(color: p.task, fontWeight: FontWeight.w700, fontSize: 18)),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: p.paper, width: 2)),
          ),
        ),
      ]),
    );
  }
}
