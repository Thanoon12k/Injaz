import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../screens/idea_detail.dart';
import '../theme.dart';
import 'media.dart';

class IdeaTile extends StatelessWidget {
  final Idea idea;
  const IdeaTile({super.key, required this.idea});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final i = idea;
    return Surface(
      border: i.pinned ? p.idea.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(12),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IdeaDetail(id: i.id))),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: p.ideaSoft, borderRadius: BorderRadius.circular(12)),
          child: Icon(i.pinned ? Icons.push_pin : Icons.lightbulb_outline, color: p.idea, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i.title,
                textDirection: dirOf(i.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink)),
            const SizedBox(height: 2),
            Row(children: [
              if (i.voice.isNotEmpty) ...[Icon(Icons.mic_none, size: 14, color: p.muted), const SizedBox(width: 6)],
              if (i.images.isNotEmpty) ...[
                Icon(Icons.image_outlined, size: 14, color: p.muted),
                const SizedBox(width: 6)
              ],
              Expanded(
                child: Text(
                  i.description.isNotEmpty ? i.description.replaceAll('\n', ' ') : ago(i.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: i.description.isNotEmpty ? dirOf(i.description) : null,
                  style: TextStyle(fontSize: 13.5, color: p.muted),
                ),
              ),
            ]),
          ]),
        ),
        if (i.images.isNotEmpty) ...[
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(width: 48, height: 48, child: MediaImage(i.images.first)),
          ),
        ],
      ]),
    );
  }
}

String ago(DateTime t) {
  final d = DateTime.now().difference(t.toLocal());
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
  return DateFormat('d MMM yyyy').format(t.toLocal());
}
