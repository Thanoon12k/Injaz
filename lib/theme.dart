import 'package:flutter/material.dart';

/// Injaz — teal palette (same as the desktop app).
class InjazColors {
  static const primary = Color(0xFF00BCD4);
  static const primaryLight = Color(0xFF4DD0E1);
  static const primaryDark = Color(0xFF0097A7);
  static const primaryDarker = Color(0xFF006064);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFF9800);
  static const error = Color(0xFFF44336);
  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
}

/// Fikra — warm sand palette (same as the ideas site).
class FikraColors {
  static const sand50 = Color(0xFFFAF8F4);
  static const sand100 = Color(0xFFF5F0E8);
  static const sand200 = Color(0xFFE8DFD3);
  static const sand300 = Color(0xFFD9CCBA);
  static const sand400 = Color(0xFFC4B49C);
  static const sand600 = Color(0xFF978367);
  static const sand800 = Color(0xFF655748);
  static const warm400 = Color(0xFFEDA24F);
  static const warm500 = Color(0xFFE8882B);
  static const warm600 = Color(0xFFD97021);
  static const stone700 = Color(0xFF44403C);
  static const stone400 = Color(0xFFA8A29E);
}

const priorityColor = {
  'urgent': Color(0xFFF44336),
  'high': Color(0xFFFF9800),
  'medium': Color(0xFF2196F3),
  'low': Color(0xFF9E9E9E),
};

const priorityLabel = {
  'urgent': 'Urgent',
  'high': 'High',
  'medium': 'Medium',
  'low': 'Low',
};

const statusColor = {
  'completed': Color(0xFF4CAF50),
  'in_progress': Color(0xFFFF9800),
  'pending': Color(0xFFBDBDBD),
};

const statusLabel = {
  'completed': 'Completed',
  'in_progress': 'In progress',
  'pending': 'Pending',
};

ThemeData buildTheme(Color seed) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );

/// True when the text starts with an Arabic/RTL letter.
TextDirection dirOf(String s) {
  for (final r in s.runes) {
    if ((r >= 0x0590 && r <= 0x08FF) || (r >= 0xFB1D && r <= 0xFEFC)) {
      return TextDirection.rtl;
    }
    if ((r >= 0x41 && r <= 0x5A) || (r >= 0x61 && r <= 0x7A)) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.ltr;
}
