import 'package:flutter/material.dart';

/// One calm design language for tasks and ideas:
/// warm paper surfaces, deep teal for doing, amber for thinking.
@immutable
class Palette extends ThemeExtension<Palette> {
  final Color paper; // page background
  final Color card; // raised surfaces
  final Color line; // hairlines
  final Color ink; // primary text
  final Color muted; // secondary text
  final Color task; // tasks accent (teal)
  final Color taskSoft;
  final Color idea; // ideas accent (amber)
  final Color ideaSoft;
  final Color danger;

  const Palette({
    required this.paper,
    required this.card,
    required this.line,
    required this.ink,
    required this.muted,
    required this.task,
    required this.taskSoft,
    required this.idea,
    required this.ideaSoft,
    required this.danger,
  });

  static const light = Palette(
    paper: Color(0xFFF6F4EF),
    card: Color(0xFFFFFFFF),
    line: Color(0xFFE6E2D9),
    ink: Color(0xFF1F2421),
    muted: Color(0xFF6E7570),
    task: Color(0xFF0F766E),
    taskSoft: Color(0xFFE3F1EE),
    idea: Color(0xFFD97706),
    ideaSoft: Color(0xFFFCF0DC),
    danger: Color(0xFFDC2626),
  );

  static const dark = Palette(
    paper: Color(0xFF141716),
    card: Color(0xFF1E2221),
    line: Color(0xFF2E3432),
    ink: Color(0xFFECEDEA),
    muted: Color(0xFF9AA19D),
    task: Color(0xFF2DD4BF),
    taskSoft: Color(0xFF173430),
    idea: Color(0xFFFBBF24),
    ideaSoft: Color(0xFF3A2E14),
    danger: Color(0xFFF87171),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(ThemeExtension<Palette>? other, double t) {
    if (other is! Palette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: l(paper, other.paper),
      card: l(card, other.card),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      task: l(task, other.task),
      taskSoft: l(taskSoft, other.taskSoft),
      idea: l(idea, other.idea),
      ideaSoft: l(ideaSoft, other.ideaSoft),
      danger: l(danger, other.danger),
    );
  }
}

extension PaletteX on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
}

const priorityColor = {
  'urgent': Color(0xFFE11D48),
  'high': Color(0xFFF97316),
  'medium': Color(0xFF3B82F6),
  'low': Color(0xFF94A3B8),
};

const priorityLabel = {'low': 'Low', 'medium': 'Medium', 'high': 'High', 'urgent': 'Urgent'};

const statusLabel = {'pending': 'To do', 'in_progress': 'Doing', 'completed': 'Done'};

ThemeData buildTheme(Brightness b) {
  final p = b == Brightness.light ? Palette.light : Palette.dark;
  final scheme = ColorScheme.fromSeed(seedColor: p.task, brightness: b).copyWith(
    primary: p.task,
    secondary: p.idea,
    surface: p.paper,
    onSurface: p.ink,
    error: p.danger,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: p.line),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    extensions: [p],
    appBarTheme: AppBarTheme(
      backgroundColor: p.paper,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: p.ink, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    dividerTheme: DividerThemeData(color: p.line, space: 1),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.card, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(backgroundColor: p.card, surfaceTintColor: Colors.transparent),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    chipTheme: ChipThemeData(
      side: BorderSide(color: p.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.card,
      hintStyle: TextStyle(color: p.muted),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: p.task, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/// Section title used across screens.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Row(children: [
          Text(text,
              style: TextStyle(
                  fontSize: 13, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: context.pal.muted)),
          const Spacer(),
          ?trailing,
        ]),
      );
}

/// White rounded surface with a hairline border.
class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? border;
  const Surface({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.border});
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border ?? p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// RTL when the text starts with an Arabic/Hebrew letter.
TextDirection dirOf(String s) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFEFC)) return TextDirection.rtl;
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}
