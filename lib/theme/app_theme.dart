import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color scheme from the design
  static const Color primary = Color(0xFF81C784);        // Light Green near yellow
  static const Color primaryText = Color(0xFF2E7D32);    // Dark Green for text
  static const Color mintTeal = Color(0xFFFFB74D);       // Light Orange
  static const Color lavender = Color(0xFFAC92EC);       // Lavender
  static const Color offWhite = Color(0xFFF5F7FA);       // Off-White
  static const Color slateGray = Color(0xFF434A54);      // Slate Gray

  // Additional colors for consistency
  static const Color secondary = Color(0xFF6c757d);
  static const Color success = Color(0xFF28a745);
  static const Color danger = Color(0xFFdc3545);
  static const Color warning = Color(0xFFffc107);
  static const Color info = Color(0xFF17a2b8);
  static const Color light = Color(0xFFf8f9fa);
  static const Color dark = Color(0xFF343a40);
  static const Color white = Color(0xFFFFFFFF);

  // Gray scale
  static const Color gray100 = Color(0xFFf8f9fa);
  static const Color gray200 = Color(0xFFe9ecef);
  static const Color gray300 = Color(0xFFdee2e6);
  static const Color gray400 = Color(0xFFced4da);
  static const Color gray500 = Color(0xFFadb5bd);
  static const Color gray600 = Color(0xFF6c757d);
  static const Color gray700 = Color(0xFF495057);
  static const Color gray800 = Color(0xFF343a40);
  static const Color gray900 = Color(0xFF212529);

  // Dark theme bluish colors
  static const Color darkBackground = Color(0xFF0D1117); // Bluish black background
  static const Color darkSurface = Color(0xFF161B22); // Bluish surface
  static const Color darkSurfaceVariant = Color(0xFF21262D); // Bluish variant surface
  static const Color darkOnSurface = Color(0xFFE6EDF3); // Light bluish text on surfaces
  static const Color darkOnSurfaceVariant = Color(0xFF9198A1); // Medium bluish text on variant
  static const Color darkOnSurfaceSecondary = Color(0xFF7D8590); // Darker bluish text
  static const Color darkOutline = Color(0xFF30363D); // Bluish outline
  static const Color darkInputFill = Color(0xFF21262D); // Bluish input fill
  static const Color darkDivider = Color(0xFF30363D); // Bluish divider
  static const Color darkCardShadow = Color(0x1A000000); // Shadow for cards

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: gray100,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: mintTeal,
        tertiary: lavender,
        surface: white,
        background: gray100,
        error: danger,
        onPrimary: white,
        onSecondary: white,
        onSurface: gray800,
        onBackground: gray800,
        onError: white,
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
        ),
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: gray800,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: gray800,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: gray700,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: gray600,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gray800,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: gray600,
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: gray300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: gray700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        hintStyle: GoogleFonts.poppins(
          color: gray400,
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        errorStyle: GoogleFonts.poppins(
          color: danger,
          fontSize: 10,
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gray700,
          side: const BorderSide(color: gray300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 4,
        shadowColor: const Color(0x1A000000),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: gray300,
        thickness: 1,
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return gray300;
        }),
        checkColor: MaterialStateProperty.all(white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: GoogleFonts.poppins().fontFamily,

      // Enhanced color scheme for dark theme
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: mintTeal,
        tertiary: lavender,
        surface: darkSurface,
        background: darkBackground,
        error: danger,
        onPrimary: white,
        onSecondary: white,
        onSurface: darkOnSurface,
        onBackground: darkOnSurface,
        onError: white,
        surfaceVariant: darkSurfaceVariant,
        onSurfaceVariant: darkOnSurfaceVariant,
      ),

      // Enhanced app bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        iconTheme: IconThemeData(
          color: darkOnSurface,
        ),
      ),

      // Enhanced text theme for dark mode
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: darkOnSurface,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceVariant,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceVariant,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: darkOnSurface,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: darkOnSurfaceVariant,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: darkOnSurfaceSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkOnSurface,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceVariant,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: darkOnSurfaceSecondary,
        ),
      ),

      // Enhanced input decoration theme for dark mode
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          color: darkOnSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.poppins(
          color: darkOnSurfaceSecondary,
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        errorStyle: GoogleFonts.poppins(
          color: danger,
          fontSize: 12,
        ),
      ),

      // Enhanced elevated button theme for dark mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 2,
          shadowColor: primary.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Enhanced outlined button theme for dark mode
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkOnSurface,
          side: BorderSide(color: darkOutline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Enhanced text button theme for dark mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Enhanced card theme for dark mode
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 4,
        shadowColor: darkCardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // Enhanced divider theme for dark mode
      dividerTheme: DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),

      // Enhanced checkbox theme for dark mode
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primary;
          }
          return darkOutline;
        }),
        checkColor: MaterialStateProperty.all(white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Enhanced floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Enhanced tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: darkOnSurfaceVariant,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Enhanced bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primary,
        unselectedItemColor: darkOnSurfaceSecondary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Enhanced dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
