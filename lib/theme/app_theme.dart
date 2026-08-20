import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color ink;
  final Color inkDim;
  final Color muted;
  final Color accent;
  final Color accentInk;
  final Color safe;
  final Color safeInk;
  final Color sos;
  final Color sosInk;
  final Color line;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.inkDim,
    required this.muted,
    required this.accent,
    required this.accentInk,
    required this.safe,
    required this.safeInk,
    required this.sos,
    required this.sosInk,
    required this.line,
  });

  static const dark = AppPalette(
    bg: Color(0xFF241322),
    surface: Color(0xFF32192E),
    surface2: Color(0xFF40213B),
    ink: Color(0xFFFCEEF3),
    inkDim: Color(0xFFE3C6D2),
    muted: Color(0xFFB98CA0),
    accent: Color(0xFFE85D97),
    accentInk: Color(0xFF2B0A18),
    safe: Color(0xFF4FAE7A),
    safeInk: Color(0xFF08150F),
    sos: Color(0xFFE23B3B),
    sosInk: Color(0xFFFFF3F3),
    line: Color(0x24FCEEF3),
  );

  static const light = AppPalette(
    bg: Color(0xFFFFF5F8),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFFCE4EC),
    ink: Color(0xFF3B1E2B),
    inkDim: Color(0xFF6B4257),
    muted: Color(0xFF9C7C89),
    accent: Color(0xFFD6336C),
    accentInk: Color(0xFFFFFDFC),
    safe: Color(0xFF2E8F5C),
    safeInk: Color(0xFFF6FFF9),
    sos: Color(0xFFC22B2B),
    sosInk: Color(0xFFFFF6F6),
    line: Color(0x243B1E2B),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? inkDim,
    Color? muted,
    Color? accent,
    Color? accentInk,
    Color? safe,
    Color? safeInk,
    Color? sos,
    Color? sosInk,
    Color? line,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      inkDim: inkDim ?? this.inkDim,
      muted: muted ?? this.muted,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      safe: safe ?? this.safe,
      safeInk: safeInk ?? this.safeInk,
      sos: sos ?? this.sos,
      sosInk: sosInk ?? this.sosInk,
      line: line ?? this.line,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkDim: Color.lerp(inkDim, other.inkDim, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      safe: Color.lerp(safe, other.safe, t)!,
      safeInk: Color.lerp(safeInk, other.safeInk, t)!,
      sos: Color.lerp(sos, other.sos, t)!,
      sosInk: Color.lerp(sosInk, other.sosInk, t)!,
      line: Color.lerp(line, other.line, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: p.bg,
      dividerColor: p.line,
      extensions: [p],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.accent,
        onPrimary: p.accentInk,
        secondary: p.safe,
        onSecondary: p.safeInk,
        error: p.sos,
        onError: p.sosInk,
        surface: p.surface,
        onSurface: p.ink,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontFamily: 'serif', fontSize: 32, fontWeight: FontWeight.w700, color: p.ink),
        headlineMedium: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700, color: p.ink),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: p.ink),
        bodyMedium: TextStyle(fontSize: 14, color: p.inkDim, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: p.muted),
        labelSmall: TextStyle(fontFamily: 'monospace', fontSize: 11, letterSpacing: 1.2, color: p.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: p.accent,
          foregroundColor: p.accentInk,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: p.ink,
          side: BorderSide(color: p.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStatePropertyAll(p.safe),
      ),
    );
  }
}
