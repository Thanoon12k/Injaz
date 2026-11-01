import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:record/record.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';

/// Shows a media image from the phone, downloading it first if it was
/// added on another device.
class MediaImage extends StatelessWidget {
  final String name;
  final BoxFit fit;
  const MediaImage(this.name, {super.key, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final local = AppStore.I.mediaFile(name);
    if (local.existsSync()) return Image.file(local, fit: fit, errorBuilder: (_, _, _) => _broken(p));
    return FutureBuilder<File?>(
      future: AppStore.I.ensureMedia(name),
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: p.ideaSoft,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final f = snap.data;
        return f == null ? _broken(p) : Image.file(f, fit: fit, errorBuilder: (_, _, _) => _broken(p));
      },
    );
  }

  Widget _broken(Palette p) => ColoredBox(
        color: p.ideaSoft,
        child: Center(child: Icon(Icons.image_not_supported_outlined, color: p.muted)),
      );
}

void openImage(BuildContext context, String name) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(child: InteractiveViewer(child: MediaImage(name, fit: BoxFit.contain))),
    ),
  ));
}

String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Play / pause a voice note.
class VoicePlayer extends StatefulWidget {
  final String name;
  final VoidCallback? onRemove;
  const VoicePlayer(this.name, {super.key, this.onRemove});
  @override
  State<VoicePlayer> createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final _p = AudioPlayer();
  final _subs = <StreamSubscription>[];
  Duration _pos = Duration.zero, _dur = Duration.zero;
  bool _playing = false, _loading = false, _missing = false;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_p.onPositionChanged.listen((d) => setState(() => _pos = d)))
      ..add(_p.onDurationChanged.listen((d) => setState(() => _dur = d)))
      ..add(_p.onPlayerStateChanged.listen((s) => setState(() => _playing = s == PlayerState.playing)))
      ..add(_p.onPlayerComplete.listen((_) => setState(() => _pos = Duration.zero)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _p.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _p.pause();
      return;
    }
    if (_p.source == null) {
      setState(() => _loading = true);
      final f = await AppStore.I.ensureMedia(widget.name);
      setState(() => _loading = false);
      if (f == null) {
        setState(() => _missing = true);
        return;
      }
      await _p.setSource(DeviceFileSource(f.path));
    }
    await _p.resume();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final max = _dur.inMilliseconds.toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: p.ideaSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Row(children: [
        IconButton(
          color: p.idea,
          icon: _loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_missing
                  ? Icons.cloud_off
                  : _playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill),
          iconSize: 34,
          onPressed: _missing ? null : _toggle,
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              activeColor: p.idea,
              inactiveColor: p.line,
              value: max <= 0 ? 0 : _pos.inMilliseconds.clamp(0, max.toInt()).toDouble(),
              max: max <= 0 ? 1 : max,
              onChanged: max <= 0 ? null : (v) => _p.seek(Duration(milliseconds: v.toInt())),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(_missing ? 'offline' : _fmt(_dur > Duration.zero ? (_playing ? _pos : _dur) : _pos),
            style: TextStyle(color: p.muted, fontSize: 13)),
        if (widget.onRemove != null)
          IconButton(
            icon: Icon(Icons.close, size: 18, color: p.muted),
            onPressed: widget.onRemove,
          )
        else
          const SizedBox(width: 10),
      ]),
    );
  }
}

/// Record button with a live timer. Calls [onDone] with the saved media name.
class VoiceRecorderButton extends StatefulWidget {
  final void Function(String name) onDone;
  const VoiceRecorderButton({super.key, required this.onDone});
  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  final _rec = AudioRecorder();
  Timer? _timer;
  int _secs = 0;
  String? _name;

  bool get _recording => _name != null;

  @override
  void dispose() {
    _timer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) {
      _timer?.cancel();
      await _rec.stop();
      final n = _name!;
      setState(() => _name = null);
      if (AppStore.I.mediaFile(n).existsSync()) widget.onDone(n);
      return;
    }
    if (!await _rec.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Microphone permission is needed to record')));
      }
      return;
    }
    final n = 'voice_${newId()}.m4a';
    await _rec.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: AppStore.I.mediaFile(n).path);
    setState(() {
      _name = n;
      _secs = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _secs++));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: _recording ? Colors.red : p.ink,
        backgroundColor: _recording ? Colors.red.withValues(alpha: 0.06) : p.ideaSoft,
        side: BorderSide(color: _recording ? Colors.red : p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(0, 46),
      ),
      icon: Icon(_recording ? Icons.stop_circle : Icons.mic_none_rounded),
      label: Text(_recording ? 'Stop  ${_fmt(Duration(seconds: _secs))}' : 'Record'),
      onPressed: _toggle,
    );
  }
}
