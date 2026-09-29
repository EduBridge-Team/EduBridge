// EduBridge light, dark, and accessibility theme builders.
part of 'theme.dart';

TextTheme _brandTextTheme(TextTheme base, {required bool dark}) {
  final heading = dark ? JisrColors.darkHeading : AppColors.ink;
  final body = dark ? JisrColors.darkBody : const Color(0xFF294861);
  final muted = dark ? const Color(0xFF91A8BA) : AppColors.muted;
  final cairo = GoogleFonts.cairoTextTheme(base);

  return cairo.copyWith(
    displaySmall: cairo.displaySmall?.copyWith(
      fontSize: 32,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: heading,
    ),
    headlineMedium: cairo.headlineMedium?.copyWith(
      fontSize: 26,
      height: 1.25,
      fontWeight: FontWeight.w800,
      color: heading,
    ),
    headlineSmall: cairo.headlineSmall?.copyWith(
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: heading,
    ),
    titleLarge: cairo.titleLarge?.copyWith(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: heading,
    ),
    titleMedium: cairo.titleMedium?.copyWith(
      fontSize: 17,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: heading,
    ),
    bodyLarge: cairo.bodyLarge?.copyWith(
      fontSize: 17,
      height: 1.55,
      color: body,
    ),
    bodyMedium: cairo.bodyMedium?.copyWith(
      fontSize: 15.5,
      height: 1.5,
      color: body,
    ),
    bodySmall: cairo.bodySmall?.copyWith(
      fontSize: 13.5,
      height: 1.45,
      color: muted,
    ),
    labelLarge: cairo.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: heading,
    ),
  );
}

ThemeData buildJisrTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandBlue,
    brightness: Brightness.light,
    primary: AppColors.brandBlue,
    secondary: AppColors.brandTeal,
    tertiary: AppColors.brandGreen,
    surface: AppColors.surface,
  );
  final cairoFamily = GoogleFonts.cairo().fontFamily;
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    fontFamily: cairoFamily,
  );

  return base.copyWith(
    textTheme: _brandTextTheme(base.textTheme, dark: false),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.lineCool),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(56, 56),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandBlueDeep,
        minimumSize: const Size(56, 56),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        side: const BorderSide(color: AppColors.lineCool, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandBlue,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lineCool),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.lineCool),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.red, width: 1.8),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.brandBlue,
      suffixIconColor: AppColors.muted,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.tintBlue,
      elevation: 0,
      height: 74,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.brandBlue
              : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.brandBlue
              : AppColors.muted,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandBlue,
      foregroundColor: Colors.white,
      elevation: 3,
      focusElevation: 3,
      hoverElevation: 3,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.brandBlue,
      textColor: AppColors.ink,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lineCool,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.brandTeal),
  );
}

ThemeData buildJisrDarkTheme() {
  const bg = Color(0xFF091A28);
  const surface = Color(0xFF142A3C);
  const border = Color(0xFF263E54);

  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brandTeal,
    brightness: Brightness.dark,
    primary: AppColors.brandTeal,
    secondary: AppColors.brandTealLight,
    tertiary: AppColors.brandGreen,
    surface: surface,
  );
  final cairoFamily = GoogleFonts.cairo().fontFamily;
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: cairoFamily,
  );

  return base.copyWith(
    textTheme: _brandTextTheme(base.textTheme, dark: true),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: const Color(0xFF05242A),
        minimumSize: const Size(56, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandTeal,
        foregroundColor: const Color(0xFF05242A),
        minimumSize: const Size(56, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: JisrColors.darkHeading,
        minimumSize: const Size(56, 56),
        side: const BorderSide(color: border, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brandTealLight,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.brandTeal, width: 1.8),
      ),
      labelStyle: const TextStyle(color: Color(0xFF91A8BA)),
      hintStyle: const TextStyle(color: Color(0xFF91A8BA)),
      prefixIconColor: AppColors.brandTeal,
      suffixIconColor: Color(0xFF91A8BA),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0xFF123F4B),
      elevation: 0,
      height: 74,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.brandTeal
              : const Color(0xFF91A8BA),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandTeal,
      foregroundColor: Color(0xFF05242A),
      elevation: 3,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.brandTeal,
      textColor: JisrColors.darkHeading,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF20384B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      contentTextStyle: const TextStyle(fontSize: 15, color: Colors.white),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.brandTeal),
  );
}

ThemeData buildHighContrastTheme() {
  final base = buildJisrTheme();
  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.highContrastDark(
      primary: Color(0xFFFFD400),
      secondary: Color(0xFFFFD400),
      surface: Colors.black,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFFFD400), width: 2),
      ),
    ),
    inputDecorationTheme:
        base.inputDecorationTheme.copyWith(fillColor: Colors.black),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFFFD400),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD400),
      ),
    ),
  );
}

ThemeData buildBlindHighContrastTheme() {
  final base = buildHighContrastTheme();
  return base.copyWith(
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        minimumSize: const Size(80, 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFFFD400),
      thickness: 2,
    ),
  );
}
