import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'models.dart';

enum SyncState { localOnly, syncing, synced, offline }

/// Offline-first store: everything lives in a local JSON file and is
/// pushed to / pulled from Supabase in the background when signed in.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore I = AppStore._();

  late Directory _dir;
  late Directory mediaDir;
  File get _file => File('${_dir.path}/injaz_data.json');

  final List<Task> _tasks = [];
  final List<Idea> _ideas = [];
  bool offlineChosen = false; // user chose to use the app without an account
  String name = '';
  String bio = '';
  String? _taskCursor;
  String? _ideaCursor;
  final Set<String> _uploaded = {};
  String? _ownerId; // user whose data is in the local cache

  SyncState syncState = SyncState.localOnly;
  DateTime? lastSync;
  Timer? _debounce;
  Timer? _ticker;
  bool _syncing = false;
  bool _again = false;

  bool supabaseReady = false;
  SupabaseClient? get _db => supabaseReady ? Supabase.instance.client : null;
  User? get user => _db?.auth.currentUser;
  bool get signedIn => user != null;

  // ── Load / save ───────────────────────────────────────────────
  Future<void> load() async {
    _dir = await getApplicationDocumentsDirectory();
    mediaDir = Directory('${_dir.path}/media');
    if (!mediaDir.existsSync()) mediaDir.createSync(recursive: true);
    try {
      if (_file.existsSync()) {
        final j = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
        _tasks.addAll(((j['tasks'] ?? []) as List)
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))));
        _ideas.addAll(((j['ideas'] ?? []) as List)
            .map((e) => Idea.fromJson(Map<String, dynamic>.from(e as Map))));
        offlineChosen = j['offline_chosen'] == true;
        name = (j['name'] ?? '') as String;
        bio = (j['bio'] ?? '') as String;
        _taskCursor = j['task_cursor'] as String?;
        _ideaCursor = j['idea_cursor'] as String?;
        _ownerId = j['owner'] as String?;
        _uploaded.addAll(((j['uploaded'] ?? []) as List).map((e) => e as String));
        final ls = j['last_sync'] as String?;
        lastSync = ls == null ? null : DateTime.tryParse(ls);
      }
    } catch (e) {
      debugPrint('load failed: $e');
    }
  }

  Future<void>? _saving;
  bool _saveAgain = false;

  /// Saves are serialised (and coalesced) so two writes never race on the temp file.
  Future<void> _save() async {
    if (_saving != null) {
      _saveAgain = true;
      return _saving;
    }
    _saving = () async {
      do {
        _saveAgain = false;
        try {
          await _write();
        } catch (e) {
          debugPrint('save failed: $e');
        }
      } while (_saveAgain);
    }();
    await _saving;
    _saving = null;
  }

  Future<void> _write() async {
    final data = jsonEncode({
      'tasks': _tasks.map((t) => t.toJson()).toList(),
      'ideas': _ideas.map((i) => i.toJson()).toList(),
      'offline_chosen': offlineChosen,
      'name': name,
      'bio': bio,
      'task_cursor': _taskCursor,
      'idea_cursor': _ideaCursor,
      'owner': _ownerId,
      'uploaded': _uploaded.toList(),
      'last_sync': lastSync?.toIso8601String(),
    });
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(_file.path);
  }

  void _changed({bool sync = true}) {
    notifyListeners();
    _save();
    if (sync) scheduleSync();
  }

  void useOffline() {
    offlineChosen = true;
    _changed(sync: false);
  }

  String get displayName {
    if (name.isNotEmpty) return name;
    final meta = user?.userMetadata;
    final n = (meta?['full_name'] ?? meta?['name'] ?? '') as String;
    return n.isNotEmpty ? n.split(' ').first : '';
  }

  String? get avatarUrl => user?.userMetadata?['avatar_url'] as String?;

  void setProfile(String n, String b) {
    name = n;
    bio = b;
    _changed(sync: false);
  }

  // ── Tasks ─────────────────────────────────────────────────────
  List<Task> get tasks => _tasks.where((t) => !t.deleted).toList();

  static int _prio(String p) => const {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3}[p] ?? 2;

  static int _taskOrder(Task a, Task b) {
    final p = _prio(a.priority).compareTo(_prio(b.priority));
    if (p != 0) return p;
    final ta = a.dueTime.isEmpty ? '99' : a.dueTime;
    final tb = b.dueTime.isEmpty ? '99' : b.dueTime;
    final t = ta.compareTo(tb);
    return t != 0 ? t : b.createdAt.compareTo(a.createdAt);
  }

  List<Task> get todayTasks {
    final k = todayKey();
    return tasks.where((t) => t.dateAssigned == k).toList()..sort(_taskOrder);
  }

  List<Task> get pastUnfinished {
    final k = todayKey();
    return tasks.where((t) => t.dateAssigned.compareTo(k) < 0 && !t.isDone).toList()
      ..sort((a, b) => b.dateAssigned.compareTo(a.dateAssigned));
  }

  List<Task> get allTasks => tasks
    ..sort((a, b) {
      final d = b.dateAssigned.compareTo(a.dateAssigned);
      return d != 0 ? d : _taskOrder(a, b);
    });

  void _touch(Task t) {
    t.updatedAt = DateTime.now().toUtc();
    t.dirty = true;
  }

  void addTask(Task t) {
    _tasks.add(t);
    _changed();
  }

  void updateTask(Task t) {
    _touch(t);
    _changed();
  }

  void setStatus(Task t, String status) {
    t.status = status;
    t.completedAt = status == 'completed' ? DateTime.now().toUtc() : null;
    updateTask(t);
  }

  void cycleStatus(Task t) {
    const next = {'pending': 'in_progress', 'in_progress': 'completed', 'completed': 'pending'};
    setStatus(t, next[t.status] ?? 'pending');
  }

  void moveToToday(Task t) {
    t.dateAssigned = todayKey();
    updateTask(t);
  }

  void deleteTask(Task t) {
    t.deleted = true;
    updateTask(t);
  }

  void restoreTask(Task t) {
    t.deleted = false;
    updateTask(t);
  }

  // ── Ideas ─────────────────────────────────────────────────────
  List<Idea> get ideas => _ideas.where((i) => !i.deleted).toList()
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });

  Idea? ideaById(String id) {
    for (final i in _ideas) {
      if (i.id == id && !i.deleted) return i;
    }
    return null;
  }

  void addIdea(Idea i) {
    _ideas.add(i);
    _changed();
  }

  void updateIdea(Idea i) {
    i.updatedAt = DateTime.now().toUtc();
    i.dirty = true;
    _changed();
  }

  void deleteIdea(Idea i) {
    i.deleted = true;
    updateIdea(i);
  }

  void restoreIdea(Idea i) {
    i.deleted = false;
    updateIdea(i);
  }

  File mediaFile(String name) => File('${mediaDir.path}/$name');

  /// Returns the local file for a media name, downloading it if needed.
  Future<File?> ensureMedia(String name) async {
    final f = mediaFile(name);
    if (f.existsSync()) return f;
    final db = _db;
    final u = user;
    if (db == null || u == null) return null;
    try {
      final bytes = await db.storage.from(mediaBucket).download('${u.id}/$name');
      await f.writeAsBytes(bytes, flush: true);
      _uploaded.add(name);
      return f;
    } catch (_) {
      return null;
    }
  }

  // ── Auth ──────────────────────────────────────────────────────
  static const authRedirect = 'com.thanoon.injaz://login-callback';

  /// Opens Google sign-in in the browser; the app returns via [authRedirect]
  /// and the auth listener below picks up the session.
  Future<void> signInWithGoogle() async {
    await _db!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirect,
      authScreenLaunchMode: LaunchMode.externalApplication,
      queryParams: const {'prompt': 'select_account'},
    );
  }

  Future<void> signOut() async {
    await _db?.auth.signOut();
    syncState = SyncState.localOnly;
    notifyListeners();
  }

  /// A different account than the cached one: restart the sync cursors and
  /// re-push everything local (the data stays on the phone either way).
  void _adoptUser() {
    final id = user?.id;
    if (id == null || id == _ownerId) return;
    _ownerId = id;
    _taskCursor = null;
    _ideaCursor = null;
    _uploaded.clear();
    for (final t in _tasks) {
      t.dirty = true;
    }
    for (final i in _ideas) {
      i.dirty = true;
    }
    _save();
  }

  // ── Sync ──────────────────────────────────────────────────────
  void startAutoSync() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 45), (_) => syncNow());
    _db?.auth.onAuthStateChange.listen((s) {
      if (s.event == AuthChangeEvent.signedIn) {
        _adoptUser();
        syncNow();
      }
      notifyListeners();
    });
    syncNow();
  }

  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), syncNow);
  }

  Future<void> syncNow() async {
    if (!signedIn) {
      if (syncState != SyncState.localOnly) {
        syncState = SyncState.localOnly;
        notifyListeners();
      }
      return;
    }
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    syncState = SyncState.syncing;
    notifyListeners();
    try {
      _adoptUser();
      await _pushTasks();
      await _pushIdeas();
      await _pullTasks();
      await _pullIdeas();
      lastSync = DateTime.now();
      syncState = SyncState.synced;
    } catch (e) {
      debugPrint('sync failed: $e');
      syncState = SyncState.offline;
    } finally {
      _syncing = false;
      notifyListeners();
      await _save();
    }
    if (_again) {
      _again = false;
      scheduleSync();
    }
  }

  Future<void> _pushTasks() async {
    final dirty = _tasks.where((t) => t.dirty).toList();
    if (dirty.isEmpty) return;
    final stamps = {for (final t in dirty) t.id: t.updatedAt};
    final uid = user!.id;
    await _db!
        .from('injaz_tasks')
        .upsert(dirty.map((t) => {...t.toRemote(), 'user_id': uid}).toList());
    for (final t in dirty) {
      if (t.updatedAt == stamps[t.id]) t.dirty = false;
    }
    _tasks.removeWhere((t) => t.deleted && !t.dirty);
  }

  Future<void> _pushIdeas() async {
    final dirty = _ideas.where((i) => i.dirty).toList();
    if (dirty.isEmpty) return;
    final uid = user!.id;
    final bucket = _db!.storage.from(mediaBucket);
    for (final i in dirty.where((i) => !i.deleted)) {
      for (final n in [...i.images, if (i.voice.isNotEmpty) i.voice]) {
        if (_uploaded.contains(n)) continue;
        final f = mediaFile(n);
        if (!f.existsSync()) continue;
        await bucket.upload('$uid/$n', f, fileOptions: const FileOptions(upsert: true));
        _uploaded.add(n);
      }
    }
    final stamps = {for (final i in dirty) i.id: i.updatedAt};
    await _db!.from('fikra_ideas').upsert(dirty.map((i) => {...i.toRemote(uid), 'user_id': uid}).toList());
    for (final i in dirty) {
      if (i.updatedAt == stamps[i.id]) i.dirty = false;
    }
    _ideas.removeWhere((i) => i.deleted && !i.dirty);
  }

  Future<List<Map<String, dynamic>>> _pull(String table, String? cursor) async {
    var q = _db!.from(table).select();
    if (cursor != null) q = q.gt('synced_at', cursor);
    final rows = await q.order('synced_at').limit(1000);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _pullTasks() async {
    List<Map<String, dynamic>> rows;
    do {
    rows = await _pull('injaz_tasks', _taskCursor);
    for (final r in rows) {
      final remote = Task.fromJson({...r, 'dirty': false});
      final idx = _tasks.indexWhere((t) => t.id == remote.id);
      if (idx < 0) {
        if (!remote.deleted) _tasks.add(remote);
      } else {
        final local = _tasks[idx];
        if (local.dirty && local.updatedAt.isAfter(remote.updatedAt)) continue;
        if (remote.deleted) {
          _tasks.removeAt(idx);
        } else {
          _tasks[idx] = remote;
        }
      }
      _taskCursor = r['synced_at'] as String;
    }
    } while (rows.length == 1000);
  }

  Future<void> _pullIdeas() async {
    List<Map<String, dynamic>> rows;
    do {
    rows = await _pull('fikra_ideas', _ideaCursor);
    for (final r in rows) {
      final remote = Idea.fromRemote(r);
      final idx = _ideas.indexWhere((i) => i.id == remote.id);
      if (idx < 0) {
        if (!remote.deleted) _ideas.add(remote);
      } else {
        final local = _ideas[idx];
        if (local.dirty && local.updatedAt.isAfter(remote.updatedAt)) continue;
        if (remote.deleted) {
          _ideas.removeAt(idx);
        } else {
          _ideas[idx] = remote;
        }
      }
      for (final n in [...remote.images, if (remote.voice.isNotEmpty) remote.voice]) {
        _uploaded.add(n);
      }
      _ideaCursor = r['synced_at'] as String;
    }
    } while (rows.length == 1000);
  }

  int get pendingChanges =>
      _tasks.where((t) => t.dirty).length + _ideas.where((i) => i.dirty).length;
}
