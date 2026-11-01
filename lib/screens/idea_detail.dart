import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final i = AppStore.I.ideaById(id);
        if (i == null) {
          return const Scaffold(backgroundColor: FikraColors.sand50, body: Center(child: Text('Idea not found')));
        }
        return Scaffold(
          backgroundColor: FikraColors.sand50,
          appBar: AppBar(
            backgroundColor: FikraColors.sand50,
            foregroundColor: FikraColors.stone700,
            actions: [
              IconButton(
                tooltip: i.pinned ? 'Unpin' : 'Pin to top',
                icon: Icon(i.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: i.pinned ? FikraColors.warm500 : null),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: FikraColors.stone700)),
            const SizedBox(height: 6),
            Text(DateFormat('d MMMM yyyy · HH:mm').format(i.createdAt.toLocal()),
                style: const TextStyle(color: FikraColors.stone400, fontSize: 13)),
            const SizedBox(height: 18),
            if (i.description.isNotEmpty)
              LinkText(i.description,
                  style: const TextStyle(fontSize: 16.5, height: 1.6, color: FikraColors.stone700),
                  linkColor: FikraColors.warm600),
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
