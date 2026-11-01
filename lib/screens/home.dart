import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/bubbles.dart';
import '../widgets/sync_badge.dart';
import 'fikra_home.dart';
import 'injaz_today.dart';
import 'settings.dart';
import 'task_lists.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final s = AppStore.I;
        final fikra = s.mode == 'fikra';
        final fg = fikra ? FikraColors.stone700 : Colors.white;
        return Scaffold(
          resizeToAvoidBottomInset: true,
          drawer: _Menu(onOpen: (p) => _open(context, p)),
          body: BubbleBackground(
            colors: fikra
                ? const [FikraColors.sand50, FikraColors.sand100, FikraColors.sand200]
                : const [InjazColors.primaryLight, InjazColors.primary, InjazColors.primaryDarker],
            bubble: fikra ? const Color(0x22C4B49C) : const Color(0x1AFFFFFF),
            child: SafeArea(
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(children: [
                    Builder(
                      builder: (c) => IconButton(
                        tooltip: 'Menu',
                        icon: Icon(Icons.menu_rounded, color: fg),
                        onPressed: () => Scaffold.of(c).openDrawer(),
                      ),
                    ),
                    Expanded(child: Center(child: _ModeSwitch(fikra: fikra))),
                    SyncBadge(color: fg, onOpenSettings: () => _open(context, const SettingsScreen())),
                  ]),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: fikra ? const FikraHome(key: ValueKey('f')) : const InjazToday(key: ValueKey('i')),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool fikra;
  const _ModeSwitch({required this.fikra});

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, String mode, bool active, Color activeBg, Color activeFg, Color idleFg) {
      return GestureDetector(
        onTap: () => AppStore.I.setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                color: active ? activeFg : idleFg,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              )),
        ),
      );
    }

    final bg = fikra ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.2);
    final idle = fikra ? FikraColors.sand600 : Colors.white.withValues(alpha: 0.85);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fikra ? FikraColors.sand200 : Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('✓ Injaz', 'injaz', !fikra, Colors.white, InjazColors.primaryDark, idle),
        seg('💡 Fikra', 'fikra', fikra, FikraColors.warm400, Colors.white, idle),
      ]),
    );
  }
}

class _Menu extends StatelessWidget {
  final void Function(Widget) onOpen;
  const _Menu({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I;
    final past = s.pastUnfinished.length;
    final fikra = s.mode == 'fikra';
    final accent = fikra ? FikraColors.warm500 : InjazColors.primaryDark;
    Widget item(IconData icon, String text, VoidCallback onTap, {String? badge}) => ListTile(
          leading: Icon(icon, color: accent),
          title: Text(text, style: const TextStyle(fontSize: 16)),
          trailing: badge == null
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
          onTap: () {
            Navigator.pop(context);
            onTap();
          },
        );
    final name = s.name.isEmpty ? 'Welcome' : s.name;
    return Drawer(
      child: ListView(padding: EdgeInsets.zero, children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: fikra
                  ? const [FikraColors.warm400, FikraColors.warm600]
                  : const [InjazColors.primary, InjazColors.primaryDarker],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Text(name.characters.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            if (s.bio.isNotEmpty)
              Text(s.bio, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (s.signedIn)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(s.user!.email ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
          ]),
        ),
        const _Section('INJAZ · TASKS'),
        item(Icons.today_rounded, 'Today', () => s.setMode('injaz')),
        item(Icons.history_rounded, 'Unfinished from earlier', () => onOpen(const PastTasksScreen()),
            badge: past > 0 ? '$past' : null),
        item(Icons.calendar_month_rounded, 'All tasks', () => onOpen(const AllTasksScreen())),
        const _Section('FIKRA · IDEAS'),
        item(Icons.lightbulb_outline_rounded, 'My ideas', () => s.setMode('fikra'),
            badge: s.ideas.isNotEmpty ? '${s.ideas.length}' : null),
        const Divider(),
        item(Icons.settings_outlined, 'Settings & sync', () => onOpen(const SettingsScreen())),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
        child: Text(text,
            style: const TextStyle(fontSize: 12, letterSpacing: 1.2, color: Colors.black45, fontWeight: FontWeight.w600)),
      );
}
