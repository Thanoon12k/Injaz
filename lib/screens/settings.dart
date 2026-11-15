import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../store.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final s = AppStore.I;
  late final _name = TextEditingController(text: s.name);
  late final _bio = TextEditingController(text: s.bio);
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    if (!s.supabaseReady) {
      _toast('No connection right now. Try again when online.');
      return;
    }
    setState(() => _busy = true);
    try {
      await s.signInWithGoogle();
    } catch (_) {
      _toast('Could not open Google sign-in.');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _syncLine() {
    final when = s.lastSync == null ? 'never' : DateFormat('d MMM, HH:mm').format(s.lastSync!);
    final state = switch (s.syncState) {
      SyncState.syncing => 'Syncing…',
      SyncState.offline => 'Offline — will sync when connected',
      SyncState.localOnly => 'Not syncing',
      SyncState.synced => 'Up to date',
    };
    final n = s.pendingChanges;
    return '$state · last sync $when${n > 0 ? ' · $n waiting' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final tasks = s.tasks;
        final done = tasks.where((t) => t.isDone).length;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            const SectionTitle('ACCOUNT'),
            Surface(
              child: s.signedIn
                  ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: p.taskSoft,
                          foregroundImage: s.avatarUrl == null ? null : NetworkImage(s.avatarUrl!),
                          child: Icon(Icons.person_outline, color: p.task),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s.displayName.isEmpty ? 'Signed in' : s.displayName,
                                style: TextStyle(fontWeight: FontWeight.w700, color: p.ink, fontSize: 16)),
                            Text(s.user!.email ?? '', style: TextStyle(color: p.muted)),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(_syncLine(), style: TextStyle(color: p.muted, fontSize: 13.5)),
                      const SizedBox(height: 10),
                      Row(children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.sync, size: 18),
                          label: const Text('Sync now'),
                          onPressed: s.syncState == SyncState.syncing ? null : s.syncNow,
                        ),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: p.danger),
                          onPressed: s.signOut,
                          child: const Text('Sign out'),
                        ),
                      ]),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('You are using Injaz without an account. Everything is saved on this phone.',
                          style: TextStyle(color: p.muted, height: 1.4)),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: p.task),
                        icon: _busy
                            ? const SizedBox(
                                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login),
                        label: const Text('Sign in with Google to sync'),
                        onPressed: _busy ? null : _google,
                      ),
                    ]),
            ),
            const SectionTitle('PROFILE'),
            Surface(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(hintText: s.displayName.isEmpty ? 'Your name' : s.displayName),
                ),
                const SizedBox(height: 10),
                TextField(controller: _bio, decoration: const InputDecoration(hintText: 'A line about you (optional)')),
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: p.task, minimumSize: const Size(96, 44)),
                    onPressed: () {
                      s.setProfile(_name.text.trim(), _bio.text.trim());
                      FocusScope.of(context).unfocus();
                      _toast('Saved');
                    },
                    child: const Text('Save'),
                  ),
                ),
              ]),
            ),
            const SectionTitle('YOUR NUMBERS'),
            Surface(
              child: Row(children: [
                _Num('${tasks.length}', 'tasks', p.task),
                _Num('$done', 'done', p.task),
                _Num(tasks.isEmpty ? '—' : '${(done * 100 / tasks.length).round()}%', 'rate', p.task),
                _Num('${s.ideas.length}', 'ideas', p.idea),
              ]),
            ),
            const SizedBox(height: 24),
            Center(child: Text('Injaz · إنجاز', style: TextStyle(color: p.muted, fontSize: 13))),
          ]),
        );
      },
    );
  }
}

class _Num extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Num(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: context.pal.muted, fontSize: 12.5)),
        ]),
      );
}
