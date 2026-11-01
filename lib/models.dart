import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();
String todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

DateTime _ts(dynamic v) =>
    v == null ? DateTime.now().toUtc() : DateTime.parse(v as String).toUtc();

class Subtask {
  String id;
  String title;
  bool done;
  Subtask({String? id, required this.title, this.done = false}) : id = id ?? newId();
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'done': done};
  factory Subtask.fromJson(Map<String, dynamic> j) =>
      Subtask(id: j['id'] as String?, title: (j['title'] ?? '') as String, done: j['done'] == true);
}

class Task {
  String id;
  String title;
  String description;
  String status; // pending | in_progress | completed
  String priority; // low | medium | high | urgent
  String tag;
  String dateAssigned; // yyyy-MM-dd
  String dueTime; // HH:mm or ''
  List<Subtask> subtasks;
  DateTime? completedAt;
  DateTime createdAt;
  DateTime updatedAt;
  bool deleted;
  bool dirty;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.status = 'pending',
    this.priority = 'medium',
    this.tag = '',
    String? dateAssigned,
    this.dueTime = '',
    List<Subtask>? subtasks,
    this.completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deleted = false,
    this.dirty = true,
  })  : id = id ?? newId(),
        dateAssigned = dateAssigned ?? todayKey(),
        subtasks = subtasks ?? [],
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  bool get isDone => status == 'completed';
  int get subDone => subtasks.where((s) => s.done).length;

  Map<String, dynamic> toRemote() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'tag': tag,
        'date_assigned': dateAssigned,
        'due_time': dueTime,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'completed_at': completedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  Map<String, dynamic> toJson() => {...toRemote(), 'dirty': dirty};

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        priority: (j['priority'] ?? 'medium') as String,
        tag: (j['tag'] ?? '') as String,
        dateAssigned: (j['date_assigned'] ?? todayKey()) as String,
        dueTime: (j['due_time'] ?? '') as String,
        subtasks: ((j['subtasks'] ?? []) as List)
            .map((e) => Subtask.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        completedAt: j['completed_at'] == null ? null : _ts(j['completed_at']),
        createdAt: _ts(j['created_at']),
        updatedAt: _ts(j['updated_at']),
        deleted: j['deleted'] == true,
        dirty: j['dirty'] == true,
      );
}

class Idea {
  String id;
  String title;
  String description;
  List<String> images; // media file names
  String voice; // media file name or ''
  bool pinned;
  DateTime createdAt;
  DateTime updatedAt;
  bool deleted;
  bool dirty;

  Idea({
    String? id,
    required this.title,
    this.description = '',
    List<String>? images,
    this.voice = '',
    this.pinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deleted = false,
    this.dirty = true,
  })  : id = id ?? newId(),
        images = images ?? [],
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  /// Media names as stored remotely: `user_id/name`.
  Map<String, dynamic> toRemote(String uid) => {
        'id': id,
        'title': title,
        'description': description,
        'images': images.map((n) => '$uid/$n').toList(),
        'voice_path': voice.isEmpty ? '' : '$uid/$voice',
        'pinned': pinned,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'images': images,
        'voice': voice,
        'pinned': pinned,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'deleted': deleted,
        'dirty': dirty,
      };

  factory Idea.fromJson(Map<String, dynamic> j) => Idea(
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        images: ((j['images'] ?? []) as List).map((e) => e as String).toList(),
        voice: (j['voice'] ?? '') as String,
        pinned: j['pinned'] == true,
        createdAt: _ts(j['created_at']),
        updatedAt: _ts(j['updated_at']),
        deleted: j['deleted'] == true,
        dirty: j['dirty'] == true,
      );

  factory Idea.fromRemote(Map<String, dynamic> j) {
    String base(String p) => p.contains('/') ? p.substring(p.lastIndexOf('/') + 1) : p;
    return Idea(
      id: j['id'] as String,
      title: (j['title'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      images: ((j['images'] ?? []) as List).map((e) => base(e as String)).toList(),
      voice: base((j['voice_path'] ?? '') as String),
      pinned: j['pinned'] == true,
      createdAt: _ts(j['created_at']),
      updatedAt: _ts(j['updated_at']),
      deleted: j['deleted'] == true,
      dirty: false,
    );
  }
}
