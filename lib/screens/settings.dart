import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  bool _create = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _bio, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _auth() async {
    final email = _email.text.trim();
    if (!email.contains('@') || _pass.text.length < 6) {
      setState(() => _error = 'Enter a valid email and a password of 6+ characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await s.signIn(email, _pass.text, create: _create);
      _pass.clear();
    } on AuthException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = 'No connection. Try again when you are online.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = s.mode == 'fikra' ? FikraColors.warm500 : InjazColors.primary;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final tasks = s.tasks;
        final done = tasks.where((t) => t.isDone).length;
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            title: const Text('Settings & sync', style: TextStyle(fontWeight: FontWeight.w700)),
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            _Card(title: 'Profile', children: [
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'Your name')),
              const SizedBox(height: 10),
              TextField(controller: _bio, decoration: const InputDecoration(hintText: 'Short bio (optional)')),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: () {
                    s.setProfile(_name.text.trim(), _bio.text.trim());
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved')));
                  },
                  child: const Text('Save'),
                ),
              ),
            ]),
            _Card(title: 'Account & sync', children: [
              if (!s.supabaseReady)
                const Text('Sync is unavailable right now. Everything is saved on this phone.',
                    style: TextStyle(color: InjazColors.textGrey))
              else if (s.signedIn) ...[
                Row(children: [
                  Icon(Icons.verified_user_outlined, color: accent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.user!.email ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                ]),
                const SizedBox(height: 8),
                Text(_syncLine(), style: const TextStyle(color: InjazColors.textGrey)),
                const SizedBox(height: 8),
                Row(children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Sync now'),
                    onPressed: s.syncState == SyncState.syncing ? null : s.syncNow,
                  ),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: InjazColors.error),
                    onPressed: s.signOut,
                    child: const Text('Sign out'),
                  ),
                ]),
              ] else ...[
                const Text(
                    'Works fully offline. Sign in to back up tasks and ideas and sync them across your devices automatically.',
                    style: TextStyle(color: InjazColors.textGrey, height: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(hintText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  onSubmitted: (_) => _auth(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!, style: const TextStyle(color: InjazColors.error)),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent, minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _auth,
                  child: _busy
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_create ? 'Create account' : 'Sign in'),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _create = !_create;
                    _error = null;
                  }),
                  child: Text(_create ? 'I already have an account' : 'New here? Create an account'),
                ),
              ],
            ]),
            _Card(title: 'Statistics', children: [
              _Stat('Tasks', '${tasks.length}'),
              _Stat('Completed', '$done'),
              _Stat('Completion rate', tasks.isEmpty ? '—' : '${(done * 100 / tasks.length).round()}%'),
              _Stat('Ideas', '${s.ideas.length}'),
            ]),
            const SizedBox(height: 8),
            const Center(
              child: Text('Injaz · إنجاز  +  Fikra · فِكْرة',
                  style: TextStyle(color: InjazColors.textGrey, fontSize: 13)),
            ),
          ]),
        );
      },
    );
  }

  String _syncLine() {
    final when = s.lastSync == null ? 'never' : DateFormat('d MMM, HH:mm').format(s.lastSync!);
    final state = switch (s.syncState) {
      SyncState.syncing => 'Syncing…',
      SyncState.offline => 'Offline — will sync when connected',
      _ => 'Up to date',
    };
    final pending = s.pendingChanges;
    return '$state · last sync $when${pending > 0 ? ' · $pending waiting' : ''}';
  }
}

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Text(label, style: const TextStyle(color: InjazColors.textGrey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );
}
