import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium iOS-inspired design system.
/// Large titles, generous spacing, soft shadows, vibrant colors.
class AppTheme {
  // ── Brand colors ──
  static const Color accent = Color(0xFF007AFF); // iOS blue
  static const Color accentLight = Color(0xFF5AC8FA);
  static const Color bg = Color(0xFFF2F2F7); // iOS grouped background
  static const Color surface = Colors.white;
  static const Color cardBg = Colors.white;

  // ── Text colors ──
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);

  // ── Semantic colors ──
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);

  // ── Spacing ──
  static const double paddingH = 20.0;
  static const double cardRadius = 16.0;

  // ── iOS-style soft shadow ──
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      primary: accent,
      brightness: Brightness.light,
    );
    final base = GoogleFonts.interTextTheme(ThemeData.light().textTheme);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: base.copyWith(
        headlineLarge: base.headlineLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w800, fontSize: 34,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w700, fontSize: 28,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w700, fontSize: 20,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 17,
        ),
        bodyLarge: base.bodyLarge?.copyWith(color: textPrimary, fontSize: 17),
        bodyMedium: base.bodyMedium?.copyWith(color: textPrimary, fontSize: 15),
        bodySmall: base.bodySmall?.copyWith(color: textSecondary, fontSize: 13),
        labelSmall: base.labelSmall?.copyWith(color: textSecondary, fontSize: 12),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
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
          return IconThemeData(
            size: 24,
            color: selected ? accent : textSecondary,
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textTertiary, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 15),
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
          side: const BorderSide(color: Color(0xFFD1D1D6)),
          textStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          foregroundColor: accent,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE5E5EA),
        thickness: 0.5,
        space: 0.5,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// iOS-style frosted glass decoration.
  static BoxDecoration get frostedGlass => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(cardRadius),
      );
}

/// iOS-style grouped section container.
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    const Padding(
                      padding: EdgeInsets.only(left: 52),
                      child: Divider(height: 0.5, thickness: 0.5),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
