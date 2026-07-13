import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium iOS-inspired design system with light + dark support.
///
/// Screens reference the semantic getters (`AppTheme.bg`, `AppTheme.surface`,
/// `AppTheme.textPrimary`, …). Those resolve against [isDark], which the root
/// app sets to the effective brightness before building. The [light]/[dark]
/// [ThemeData] use fixed per-mode constants so Material widgets are correct
/// regardless of the global flag.
class AppTheme {
  /// Effective brightness — set by the root widget each build.
  static bool isDark = false;

  // ── Brand + semantic colors (identical in both modes) ──
  static const Color accent = Color(0xFF007AFF); // iOS blue
  static const Color accentLight = Color(0xFF5AC8FA);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);

  // ── Per-mode surfaces / text (iOS system colors) ──
  static const Color _bgLight = Color(0xFFF2F2F7);
  static const Color _bgDark = Color(0xFF000000);
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1C1C1E);
  static const Color _elevatedDark = Color(0xFF2C2C2E);
  static const Color _textPrimaryLight = Color(0xFF000000);
  static const Color _textPrimaryDark = Color(0xFFFFFFFF);
  static const Color _textSecondaryLight = Color(0xFF8E8E93);
  static const Color _textSecondaryDark = Color(0xFF98989E);
  static const Color _textTertiaryLight = Color(0xFFAEAEB2);
  static const Color _textTertiaryDark = Color(0xFF636366);
  static const Color _separatorLight = Color(0xFFE5E5EA);
  static const Color _separatorDark = Color(0xFF38383A);
  static const Color _inputFillLight = Color(0xFFF5F5F7);
  static const Color _inputFillDark = Color(0xFF2C2C2E);

  // ── Semantic getters used across screens ──
  static Color get bg => isDark ? _bgDark : _bgLight;
  static Color get surface => isDark ? _surfaceDark : _surfaceLight;
  static Color get cardBg => surface;
  static Color get elevated => isDark ? _elevatedDark : _surfaceLight;
  static Color get textPrimary => isDark ? _textPrimaryDark : _textPrimaryLight;
  static Color get separator => isDark ? _separatorDark : _separatorLight;
  static Color get inputFill => isDark ? _inputFillDark : _inputFillLight;
  // Subtle filled chips / pills / search fields.
  static Color get fill => isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

  // Medium grays: readable on both light and dark, kept const so existing
  // `const TextStyle(color: AppTheme.textSecondary)` call sites still compile.
  static const Color textSecondary = _textSecondaryLight;
  static const Color textTertiary = _textTertiaryLight;

  // ── Spacing ──
  static const double paddingH = 20.0;
  static const double cardRadius = 16.0;

  // ── Shadows: soft in light, negligible in dark (surfaces separate by tone) ──
  static List<BoxShadow> get softShadow => isDark
      ? const []
      : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))];

  static List<BoxShadow> get cardShadow => isDark
      ? const []
      : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))];

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final surface = dark ? _surfaceDark : _surfaceLight;
    final scaffold = dark ? _bgDark : _bgLight;
    final textPrimary = dark ? _textPrimaryDark : _textPrimaryLight;
    final textSecondary = dark ? _textSecondaryDark : _textSecondaryLight;
    final separator = dark ? _separatorDark : _separatorLight;
    final inputFill = dark ? _inputFillDark : _inputFillLight;

    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      brightness: b,
      surface: surface,
    );
    final baseText = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final base = GoogleFonts.interTextTheme(baseText);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      textTheme: base.copyWith(
        headlineLarge: base.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w800, fontSize: 34),
        headlineMedium: base.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 28),
        titleLarge: base.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: base.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 17),
        bodyLarge: base.bodyLarge?.copyWith(color: textPrimary, fontSize: 17),
        bodyMedium: base.bodyMedium?.copyWith(color: textPrimary, fontSize: 15),
        bodySmall: base.bodySmall?.copyWith(color: textSecondary, fontSize: 13),
        labelSmall: base.labelSmall?.copyWith(color: textSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 56,
        indicatorColor: accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? accent : textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 24, color: selected ? accent : textSecondary);
        }),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
        hintStyle: TextStyle(color: dark ? _textTertiaryDark : _textTertiaryLight, fontSize: 15),
        labelStyle: TextStyle(color: textSecondary, fontSize: 15),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: separator),
          textStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          foregroundColor: accent,
        ),
      ),
      dividerTheme: DividerThemeData(color: separator, thickness: 0.5, space: 0.5),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), side: BorderSide.none),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }
}

/// iOS-style grouped section container (theme-aware).
class IosGroupedSection extends StatelessWidget {
  const IosGroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
    this.margin,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 6, top: 4),
              child: Text(
                header!.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: Divider(height: 0.5, thickness: 0.5, color: AppTheme.separator),
                    ),
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 6),
              child: Text(
                footer!,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}
