import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// R&M Boutique colours, from the brand palette.
///
/// Deep Olive is used for text, primary buttons and icons. Tatreez Terracotta
/// is the one warm accent (the floating add button, the send button, badges).
/// The page itself is Warm Ivory and Sand marks selected states, so that white
/// cards read as objects lying on a surface.
class AppColors {
  static const ink = Color(0xFF2F3A2C); // Deep Olive: primary
  static const accent = Color(0xFFB4472C); // Tatreez Terracotta, fills only (white text)
  static const accentOnDark = Color(0xFFE08A6A); // terracotta, lightened for dark olive
  static const alert = Color(0xFFB3261E); // errors, urgent, low stock
  static const canvas = Color(0xFFFAF6EF); // Warm Ivory: page background
  static const tint = Color(0xFFE8DDCB); // Sand: selected states, photo placeholders
  static const hairline = Color(0xFFE3D8C4); // card and field outlines
  static const slate = Color(0xFF26292B); // Charcoal: body text
  static const muted = Color(0xFF6F6D5E); // secondary text and icons

  // One colour per order status, shared by every role (see StatusChip).
  static const statusPaid = Color(0xFF9A6B14); // ochre
  static const statusPacked = Color(0xFF6F6D5E); // stone
  static const statusDispatched = Color(0xFF3D6A78); // muted teal
  static const statusDelivered = Color(0xFF3F7A45); // leaf green
}

/// Corner sizes used across the app, so cards, fields and buttons agree.
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
}

/// Soft shadow shared by raised surfaces (cards, tiles, floating bars).
class AppSurface {
  static const shadowColor = Color(0x332F3A2C);

  static ShapeBorder card([double radius = AppRadius.md]) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: AppColors.hairline),
      );
}

class AppTheme {
  /// Serif used for screen titles and the brand name.
  static TextStyle display({double size = 26, Color color = AppColors.ink}) {
    try {
      return GoogleFonts.getFont(
        'Instrument Serif',
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: color,
        height: 1.1,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontStyle: FontStyle.italic,
        color: color,
      );
    }
  }

  static TextTheme _bodyText(TextTheme base) {
    try {
      return GoogleFonts.getTextTheme('Outfit', base);
    } catch (_) {
      return base;
    }
  }

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.ink,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.slate,
      error: AppColors.alert,
      onError: Colors.white,
      outline: AppColors.muted,
      outlineVariant: AppColors.hairline,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = _bodyText(base.textTheme)
        .apply(bodyColor: AppColors.slate, displayColor: AppColors.ink);

    const pill = StadiumBorder();
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.hairline),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: text,
      primaryTextTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(size: 26),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppSurface.shadowColor,
        elevation: 2,
        margin: const EdgeInsets.all(4),
        shape: AppSurface.card(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.tint,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: pill,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.tint,
          disabledForegroundColor: AppColors.muted,
          shape: pill,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.2),
          shape: pill,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.alert),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.alert, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        showCheckmark: false,
        side: const BorderSide(color: AppColors.hairline),
        shape: pill,
        secondaryLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: WidgetStateColor.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : AppColors.slate,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppSurface.shadowColor,
        elevation: 10,
        indicatorColor: AppColors.accent.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.ink
                : AppColors.muted,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.ink,
        unselectedItemColor: AppColors.muted,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(iconColor: AppColors.ink),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.ink),
    );
  }
}
