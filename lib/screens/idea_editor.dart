import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/media.dart';

/// New / edit idea: title, description (links become clickable), photos, voice note.
class IdeaEditor extends StatefulWidget {
  final Idea? idea;
  final String titleHint;
  const IdeaEditor({super.key, this.idea, this.titleHint = ''});
  @override
  State<IdeaEditor> createState() => _IdeaEditorState();
}

class _IdeaEditorState extends State<IdeaEditor> {
  late final _title = TextEditingController(text: widget.idea?.title ?? widget.titleHint);
  late final _desc = TextEditingController(text: widget.idea?.description ?? '');
  late final List<String> _images = [...?widget.idea?.images];
  late String _voice = widget.idea?.voice ?? '';
  final _picker = ImagePicker();

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _addImages(ImageSource src) async {
    try {
      final picked = src == ImageSource.camera
          ? [?await _picker.pickImage(source: src, imageQuality: 80, maxWidth: 1600)]
          : await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
      for (final x in picked) {
        final ext = x.path.contains('.') ? x.path.substring(x.path.lastIndexOf('.')) : '.jpg';
        final name = 'img_${newId()}$ext';
        await File(x.path).copy(AppStore.I.mediaFile(name).path);
        setState(() => _images.add(name));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add photo: $e')));
    }
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final i = widget.idea;
    if (i == null) {
      AppStore.I.addIdea(Idea(title: title, description: _desc.text.trim(), images: _images, voice: _voice));
    } else {
      i
        ..title = title
        ..description = _desc.text.trim()
        ..images = _images
        ..voice = _voice;
      AppStore.I.updateIdea(i);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final editing = widget.idea != null;
    return Scaffold(
      backgroundColor: p.paper,
      appBar: AppBar(
        backgroundColor: p.paper,
        foregroundColor: p.ink,
        title: Text(editing ? 'Refine your idea' : 'New idea', style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          ValueListenableBuilder(
            valueListenable: _title,
            builder: (_, v, _) => TextButton(
              onPressed: v.text.trim().isEmpty ? null : _save,
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
        ValueListenableBuilder(
          valueListenable: _title,
          builder: (_, v, _) => TextField(
            controller: _title,
            autofocus: !editing && widget.titleHint.isEmpty,
            textDirection: v.text.isEmpty ? null : dirOf(v.text),
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: p.ink),
            decoration: const InputDecoration(hintText: 'Title', fillColor: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder(
          valueListenable: _desc,
          builder: (_, v, _) => TextField(
            controller: _desc,
            minLines: 5,
            maxLines: 14,
            textDirection: v.text.isEmpty ? null : dirOf(v.text),
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontSize: 16, height: 1.45, color: p.ink),
            decoration: const InputDecoration(
              hintText: 'Describe it… links become clickable',
              fillColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Voice note', style: TextStyle(fontWeight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 8),
        if (_voice.isEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: VoiceRecorderButton(onDone: (n) => setState(() => _voice = n)),
          )
        else
          VoicePlayer(_voice, key: ValueKey(_voice), onRemove: () => setState(() => _voice = '')),
        const SizedBox(height: 18),
        Text('Photos', style: TextStyle(fontWeight: FontWeight.w600, color: p.muted)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final n in _images)
            Stack(children: [
              GestureDetector(
                onTap: () => openImage(context, n),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(width: 92, height: 92, child: MediaImage(n)),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => setState(() => _images.remove(n)),
                  child: const CircleAvatar(
                      radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
            ]),
          _AddTile(icon: Icons.photo_library_outlined, label: 'Gallery', onTap: () => _addImages(ImageSource.gallery)),
          _AddTile(icon: Icons.photo_camera_outlined, label: 'Camera', onTap: () => _addImages(ImageSource.camera)),
        ]),
      ]),
    );
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: p.ideaSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: p.idea),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: p.idea)),
          ]),
        ),
      );
  }
}
