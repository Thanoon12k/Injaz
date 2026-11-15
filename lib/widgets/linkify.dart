import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme.dart';

final _url = RegExp(r'((https?://|www\.)[^\s]+)', caseSensitive: false);

/// Text whose URLs are tappable (like the Fikra site's auto-linking).
class LinkText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color linkColor;
  const LinkText(this.text, {super.key, required this.style, required this.linkColor});

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _url.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final link = m.group(0)!;
      final rec = TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.parse(link.startsWith('http') ? link : 'https://$link');
          launchUrl(uri, mode: LaunchMode.externalApplication);
        };
      _recognizers.add(rec);
      spans.add(TextSpan(
        text: link,
        style: TextStyle(color: widget.linkColor, decoration: TextDecoration.underline),
        recognizer: rec,
      ));
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));
    return SelectableText.rich(
      TextSpan(style: widget.style, children: spans),
      textDirection: dirOf(widget.text),
    );
  }
}
