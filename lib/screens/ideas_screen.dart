import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets/idea_tile.dart';
import 'idea_editor.dart';

class IdeasScreen extends StatefulWidget {
  const IdeasScreen({super.key});
  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final list = AppStore.I.ideas
            .where((i) => q.isEmpty || i.title.toLowerCase().contains(q) || i.description.toLowerCase().contains(q))
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Ideas')),
          floatingActionButton: FloatingActionButton(
            backgroundColor: p.idea,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const IdeaEditor())),
            child: const Icon(Icons.add),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Search ideas', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('No ideas yet', style: TextStyle(color: p.muted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => IdeaTile(idea: list[i]),
                    ),
            ),
          ]),
        );
      },
    );
  }
}
