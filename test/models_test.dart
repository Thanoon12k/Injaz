import 'package:flutter_test/flutter_test.dart';
import 'package:injaz/models.dart';

void main() {
  test('task survives local and remote round trips', () {
    final t = Task(title: 'Write report', priority: 'high', tag: 'work', dueTime: '09:30',
        subtasks: [Subtask(title: 'Outline', done: true), Subtask(title: 'Draft')]);
    final local = Task.fromJson(t.toJson());
    expect(local.title, 'Write report');
    expect(local.subDone, 1);
    expect(local.dirty, isTrue);
    final remote = Task.fromJson({...t.toRemote(), 'dirty': false});
    expect(remote.dirty, isFalse);
    expect(remote.updatedAt, t.updatedAt);
    expect(remote.subtasks.length, 2);
  });

  test('idea media names map to user folders and back', () {
    final i = Idea(title: 'فكرة', images: ['img_1.jpg'], voice: 'voice_1.m4a');
    final r = i.toRemote('uid-123');
    expect(r['images'], ['uid-123/img_1.jpg']);
    expect(r['voice_path'], 'uid-123/voice_1.m4a');
    final back = Idea.fromRemote(r);
    expect(back.images, ['img_1.jpg']);
    expect(back.voice, 'voice_1.m4a');
    expect(back.title, 'فكرة');
  });
}
