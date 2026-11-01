import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/media.dart';
import 'idea_detail.dart';
import 'idea_editor.dart';

/// Main Fikra screen: capture an idea fast, then see your ideas.
class FikraHome extends StatefulWidget {
  const FikraHome({super.key});
  @override
  State<FikraHome> createState() => _FikraHomeState();
}

class _FikraHomeState extends State<FikraHome> {
  final _input = TextEditingController();
  bool _search = false;
  String _q = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _save() {
    final v = _input.text.trim();
    if (v.isEmpty) return;
    AppStore.I.addIdea(Idea(title: v));
    _input.clear();
    FocusScope.of(context).unfocus();
  }

  void _openEditor() {
    final hint = _input.text.trim();
    _input.clear();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdeaEditor(titleHint: hint)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStore.I,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final all = AppStore.I.ideas;
        final list = q.isEmpty
            ? all
            : all.where((i) => i.title.toLowerCase().contains(q) || i.description.toLowerCase().contains(q)).toList();
        return CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverList.list(children: [
                const Center(child: _FloatingBulb()),
                const SizedBox(height: 8),
                const Text('What are you thinking?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: FikraColors.stone700)),
                const SizedBox(height: 4),
                const Text('Capture it before it fades away',
                    textAlign: TextAlign.center, style: TextStyle(color: FikraColors.stone400, fontSize: 14)),
                const SizedBox(height: 18),
                _CaptureCard(controller: _input, onSave: _save, onMore: _openEditor),
                const SizedBox(height: 22),
                if (all.isNotEmpty)
                  Row(children: [
                    Text('My ideas · ${all.length}',
                        style: const TextStyle(
                            color: FikraColors.sand800, fontWeight: FontWeight.w700, fontSize: 15)),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      color: FikraColors.sand600,
                      icon: Icon(_search ? Icons.close : Icons.search),
                      onPressed: () => setState(() {
                        _search = !_search;
                        if (!_search) _q = '';
                      }),
                    ),
                  ]),
                if (_search)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                          hintText: 'Search ideas', prefixIcon: Icon(Icons.search), fillColor: Colors.white),
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
              ]),
            ),
            if (all.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Text('Your ideas will live here ✨',
                        style: TextStyle(color: FikraColors.sand600, fontSize: 16)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                sliver: SliverList.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => IdeaCard(idea: list[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FloatingBulb extends StatefulWidget {
  const _FloatingBulb();
  @override
  State<_FloatingBulb> createState() => _FloatingBulbState();
}

class _FloatingBulbState extends State<_FloatingBulb> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, child) =>
            Transform.translate(offset: Offset(0, -6 * Curves.easeInOut.transform(_c.value)), child: child),
        child: const Text('💡', style: TextStyle(fontSize: 42)),
      );
}

class _CaptureCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSave;
  final VoidCallback onMore;
  const _CaptureCard({required this.controller, required this.onSave, required this.onMore});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FikraColors.sand200),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(children: [
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, v, _) => TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textDirection: v.text.isEmpty ? null : dirOf(v.text),
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17, color: FikraColors.stone700),
            decoration: const InputDecoration(
              hintText: 'An idea… / فكرة…',
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        Row(children: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: FikraColors.sand600),
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
            label: const Text('Details · photo · voice'),
            onPressed: onMore,
          ),
          const Spacer(),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: FikraColors.warm500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ]),
      ]),
    );
  }
}

class IdeaCard extends StatelessWidget {
  final Idea idea;
  const IdeaCard({super.key, required this.idea});

  @override
  Widget build(BuildContext context) {
    final i = idea;
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdeaDetail(id: i.id))),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: i.pinned ? FikraColors.warm400 : FikraColors.sand200),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(i.title,
                    textDirection: dirOf(i.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600, color: FikraColors.stone700)),
                if (i.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(i.description,
                        textDirection: dirOf(i.description),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: FikraColors.sand800, fontSize: 14, height: 1.35)),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  if (i.pinned) ...[
                    const Icon(Icons.push_pin, size: 14, color: FikraColors.warm500),
                    const SizedBox(width: 8),
                  ],
                  if (i.voice.isNotEmpty) ...[
                    const Icon(Icons.mic, size: 15, color: FikraColors.sand600),
                    const SizedBox(width: 8),
                  ],
                  if (i.images.isNotEmpty) ...[
                    const Icon(Icons.image_outlined, size: 15, color: FikraColors.sand600),
                    Text(' ${i.images.length}', style: const TextStyle(fontSize: 12, color: FikraColors.sand600)),
                    const SizedBox(width: 8),
                  ],
                  Text(_ago(i.createdAt), style: const TextStyle(fontSize: 12, color: FikraColors.stone400)),
                ]),
              ]),
            ),
            if (i.images.isNotEmpty) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(width: 64, height: 64, child: MediaImage(i.images.first)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
  return DateFormat('d MMM yyyy').format(t.toLocal());
}
