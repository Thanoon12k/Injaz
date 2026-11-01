import 'package:flutter/material.dart';

import '../store.dart';
import '../theme.dart';

/// First launch: sign in with Google (sync) or just start offline.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _busy = false;

  Future<void> _google() async {
    final s = AppStore.I;
    if (!s.supabaseReady) {
      _toast('No connection right now — you can start offline and sign in later.');
      return;
    }
    setState(() => _busy = true);
    try {
      await s.signInWithGoogle();
    } catch (e) {
      _toast('Could not open Google sign-in. Check your connection.');
    }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(flex: 3),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Image.asset('assets/icon/icon.png', width: 104, height: 104),
              ),
            ),
            const SizedBox(height: 28),
            Text('Injaz',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: p.ink, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Your day and your ideas,\nin one calm place.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.45, color: p.muted)),
            const SizedBox(height: 28),
            _Point(icon: Icons.check_circle_outline, color: p.task, text: 'Plan today — only what matters'),
            _Point(icon: Icons.lightbulb_outline, color: p.idea, text: 'Catch ideas with photos and voice'),
            _Point(icon: Icons.cloud_done_outlined, color: p.muted, text: 'Works offline, syncs when online'),
            const Spacer(flex: 4),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.card,
                foregroundColor: p.ink,
                minimumSize: const Size.fromHeight(54),
                side: BorderSide(color: p.line),
              ),
              onPressed: _busy ? null : _google,
              child: _busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      _GoogleG(),
                      SizedBox(width: 12),
                      Flexible(child: Text('Continue with Google', overflow: TextOverflow.ellipsis)),
                    ]),
            ),
            const SizedBox(height: 6),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: p.muted),
              onPressed: AppStore.I.useOffline,
              child: const Text('Use without an account'),
            ),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Point({required this.icon, required this.color, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(text, style: TextStyle(fontSize: 15.5, color: context.pal.ink))),
        ]),
      );
}

/// Simple four-colour "G" mark drawn in code (no image asset needed).
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GPainter()));
}

class _GPainter extends CustomPainter {
  const _GPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.2;
    final r = Rect.fromLTWH(w / 2, w / 2, size.width - w, size.height - w);
    Paint pc(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    const deg = 3.14159265 / 180;
    canvas.drawArc(r, -40 * deg, -100 * deg, false, pc(const Color(0xFFEA4335)));
    canvas.drawArc(r, -140 * deg, -90 * deg, false, pc(const Color(0xFFFBBC05)));
    canvas.drawArc(r, 130 * deg, -100 * deg, false, pc(const Color(0xFF34A853)));
    canvas.drawArc(r, 30 * deg, -30 * deg, false, pc(const Color(0xFF4285F4)));
    canvas.drawRect(
        Rect.fromLTWH(size.width / 2, size.height / 2 - w / 2, size.width / 2, w), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(_) => false;
}
