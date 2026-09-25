// EduBridge light, dark, and accessibility theme builders.
part of 'theme.dart';

ThemeData buildJisrTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(

       seedColor: AppColors.brandBlue,   // ← استخدم الاسم الرسمي
       primary:   AppColors.brandBlue,
       secondary: AppColors.brandTeal,
       tertiary:  AppColors.brandGreen,   // ← جديد: الأخضر كـ tertiary
       surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyMedium: const TextStyle(fontSize: 16, color: AppColors.ink),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.lineCool),
      ),
      shadowColor: const Color(0x332E5AAC),
    ),

    // أزرار أساسية — أزرق ملكي
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size(56, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(56, 56),
        side: const BorderSide(color: AppColors.lineCool, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tealDeep,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lineCool, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lineCool, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.tealDeep,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
    ),

    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.teal),

    // شريط التبويبات السفلي
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.tintTeal,
      elevation: 0,
      height: 72,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.navy
              : AppColors.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lineCool,
      thickness: 1,
    ),
  );
}

/// ثيم الوضع الليلي — أزرق داكن
ThemeData buildJisrDarkTheme() {
  const bg = Color(0xFF0B1E30);
  const card = JisrColors.dark;

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.dark,
      primary: AppColors.teal,
      secondary: AppColors.lightTeal,
      surface: card.card,
    ),
    scaffoldBackgroundColor: bg,
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyMedium: const TextStyle(fontSize: 16, color: JisrColors.darkBody),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: JisrColors.darkHeading,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: card.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF243D5C)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        minimumSize: const Size(56, 56),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: JisrColors.darkHeading,
        minimumSize: const Size(56, 56),
        side: const BorderSide(color: Color(0xFF33556F), width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card.card,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF33556F), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF33556F), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF8FA6B8)),
      prefixIconColor: AppColors.teal,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.teal),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: card.card,
      indicatorColor: AppColors.tintTeal,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    ),
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
    textTheme: base.textTheme.copyWith(
      bodyLarge: const TextStyle(fontSize: 20, color: Colors.white),
      bodyMedium: const TextStyle(fontSize: 18, color: Colors.white),
      bodySmall: const TextStyle(fontSize: 16, color: Colors.white),
      displayLarge: const TextStyle(
          fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
      displayMedium: const TextStyle(
          fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
      displaySmall: const TextStyle(
          fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
      headlineLarge: const TextStyle(
          fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(
          fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      headlineSmall: const TextStyle(
          fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
      titleLarge: const TextStyle(
          fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(
          fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(
          fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
      labelLarge: const TextStyle(fontSize: 18, color: Colors.white),
      labelMedium: const TextStyle(fontSize: 16, color: Colors.white),
      labelSmall: const TextStyle(fontSize: 14, color: Colors.white),
    ),
    cardTheme: base.cardTheme.copyWith(
      color: Colors.black,
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
/// ثيم عالي التباين — للكفيف
ThemeData buildBlindHighContrastTheme() {
  final base = buildJisrTheme();

  return base.copyWith(
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.highContrastDark(
      primary: Color(0xFFFFD400),
      secondary: Color(0xFFFFD400),
      surface: Colors.black,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A1A),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFFD400), width: 2.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD400),
        foregroundColor: Colors.black,
        minimumSize: const Size(80, 80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Color(0xFFFFD400),
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFFD400),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFFFD400),
      thickness: 2,
    ),
  );
}
