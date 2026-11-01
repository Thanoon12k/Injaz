import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/linkify.dart';
import '../widgets/media.dart';
import 'idea_editor.dart';

class IdeaDetail extends StatelessWidget {
  final String id;
  const IdeaDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final i = AppStore.I.ideaById(id);
        if (i == null) {
          return Scaffold(backgroundColor: p.paper, body: Center(child: Text('Idea not found')));
        }
        return Scaffold(
          backgroundColor: p.paper,
          appBar: AppBar(
            backgroundColor: p.paper,
            foregroundColor: p.ink,
            actions: [
              IconButton(
                tooltip: i.pinned ? 'Unpin' : 'Pin to top',
                icon: Icon(i.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: i.pinned ? p.idea : null),
                onPressed: () {
                  i.pinned = !i.pinned;
                  AppStore.I.updateIdea(i);
                },
              ),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdeaEditor(idea: i))),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete idea?'),
                      content: Text('"${i.title}" will be deleted.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    AppStore.I.deleteIdea(i);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(22, 4, 22, 40), children: [
            Text(i.title,
                textDirection: dirOf(i.title),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: p.ink)),
            const SizedBox(height: 6),
            Text(DateFormat('d MMMM yyyy · HH:mm').format(i.createdAt.toLocal()),
                style: TextStyle(color: p.muted, fontSize: 13)),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: p.task, side: BorderSide(color: p.task.withValues(alpha: 0.4))),
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Do it today'),
                onPressed: () {
                  AppStore.I.addTask(Task(title: i.title, description: i.description));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Added to today\'s tasks')));
                },
              ),
            ),
            const SizedBox(height: 18),
            if (i.description.isNotEmpty)
              LinkText(i.description,
                  style: TextStyle(fontSize: 16.5, height: 1.6, color: p.ink),
                  linkColor: p.idea),
            if (i.voice.isNotEmpty) ...[
              const SizedBox(height: 20),
              VoicePlayer(i.voice, key: ValueKey(i.voice)),
            ],
            if (i.images.isNotEmpty) ...[
              const SizedBox(height: 20),
              for (final n in i.images)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => openImage(context, n),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 120, maxHeight: 420),
                        child: MediaImage(n, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
            ],
          ]),
        );
      },
    );
  }
}
