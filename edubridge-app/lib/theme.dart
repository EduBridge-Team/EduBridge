// هوية «جسر التعليمي» — نظام التصميم المشترك للتطبيق
// لوحة ألوان مستوحاة من شعار Edu Bridge:
// أزرق ملكي عميق + تركوازي مشرق + خلفيات بيضاء مزرقة
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// وضع الثيم الحالي (فاتح/ليلي) — تستمع له MaterialApp وتتبدل فوراً
final ValueNotifier<ThemeMode> jisrThemeMode = ValueNotifier(ThemeMode.light);

/// تحميل الوضع المحفوظ عند تشغيل التطبيق
Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  jisrThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

/// تبديل الوضع وحفظ الاختيار محلياً
Future<void> toggleThemeMode() async {
  final isDark = jisrThemeMode.value != ThemeMode.dark;
  jisrThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark_mode', isDark);
}

/// ألوان الهوية — مصدر واحد لكل الشاشات
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════
  //  الألوان الأساسية (من الشعار الجديد)
  // ═══════════════════════════════════════════════════════

  /// اللون الأساسي — أزرق ملكي عميق
  static const navy = Color(0xFF2E5AAC);
  static const navyDeep = Color(0xFF1E3F7A);

  /// اللون الثانوي — تركوازي الشعار
  static const teal = Color(0xFF3BBFBF);
  static const tealDeep = Color(0xFF2A9A9A);

  /// أزرق متوسط (وسط التدرّج في الشعار)
  static const blue = Color(0xFF3E7DBE);

  /// تركوازي فاتح (لمسات)
  static const lightTeal = Color(0xFF5DD0C8);

  // ═══════════════════════════════════════════════════════
  //  الألوان الدلالية (وظيفية — تبقى كما هي)
  // ═══════════════════════════════════════════════════════

  static const green = Color(0xFF57B25A);       // نجاح
  static const greenDeep = Color(0xFF3F9142);
  static const orange = Color(0xFFF2842B);      // تنبيه
  static const orangeDeep = Color(0xFFD96E17);
  static const yellow = Color(0xFFFFC23C);      // تحذير خفيف
  static const pink = Color(0xFFF06C8B);        // لمسة مميزة
  static const red = Color(0xFFE53935);         // خطأ

  // ═══════════════════════════════════════════════════════
  //  الخلفيات (بيضاء مزرقة بدل الكريمي)
  // ═══════════════════════════════════════════════════════

  /// الخلفية العامة — أبيض مزرَق
  static const cream = Color(0xFFF7F9FC);

  /// خلفيات خفيفة جداً — للتلوين الداخلي
  static const tintBlue = Color(0xFFE5EDF7);    // أزرق فاتح جداً
  static const tintTeal = Color(0xFFE0F5F5);    // تركوازي فاتح جداً
  static const tintGreen = Color(0xFFE5F4E5);
  static const tintOrange = Color(0xFFFFF0E0);
  static const tintYellow = Color(0xFFFFF8E1);

  // ═══════════════════════════════════════════════════════
  //  النصوص والحدود (زرقاء بدل الرمادي الدافئ)
  // ═══════════════════════════════════════════════════════

  /// نص داكن — أزرق مزرق
  static const ink = Color(0xFF1A2942);
  static const muted = Color(0xFF6B7A99);

  /// حدود — أزرق فاتح جداً
  static const lineCool = Color(0xFFD6E2F0);

  // ═══════════════════════════════════════════════════════
  //  لوحة ألوان متناوبة للأطفال (زرقاء/تركوازية)
  // ═══════════════════════════════════════════════════════

  static const kidPalette = [
    Color(0xFF2E5AAC), // أزرق ملكي
    Color(0xFF3BBFBF), // تركوازي
    Color(0xFF3E7DBE), // أزرق متوسط
    Color(0xFF5DD0C8), // تركوازي فاتح
    Color(0xFF2A9A9A), // تركوازي عميق
  ];

  // ═══════════════════════════════════════════════════════
  //  تدرّج الهوية للرؤوس — من الشعار (أزرق → تركوازي)
  // ═══════════════════════════════════════════════════════

  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1E3F7A), // أزرق داكن
      Color(0xFF2A5A94), // أزرق غامق
      Color(0xFF2A8F8F),        // تركوازي
    ],
  );

  /// تدرّج ثانوي للأزرار الكبيرة (اختياري)
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, teal],
  );
}

/// ألوان متكيّفة مع الوضع (فاتح/ليلي) — للنصوص والخلفيات الملوّنة
class JisrColors {
  final Color heading;
  final Color body;
  final Color muted;
  final Color line;
  final Color card;
  final Color tintTeal;
  final Color tintGreen;
  final Color tintOrange;
  final Color tintYellow;
  final Color onTint;
  final Color success;

  const JisrColors({
    required this.heading,
    required this.body,
    required this.muted,
    required this.line,
    required this.card,
    required this.tintTeal,
    required this.tintGreen,
    required this.tintOrange,
    required this.tintYellow,
    required this.onTint,
    required this.success,
  });

  static const light = JisrColors(
    heading: AppColors.navy,
    body: AppColors.ink,
    muted: AppColors.muted,
    line: AppColors.lineCool,
    card: Colors.white,
    tintTeal: AppColors.tintTeal,
    tintGreen: AppColors.tintGreen,
    tintOrange: AppColors.tintOrange,
    tintYellow: AppColors.tintYellow,
    onTint: AppColors.ink,
    success: AppColors.greenDeep,
  );

  static const darkHeading = Color(0xFFDCE8F7);
  static const darkBody = Color(0xFFC6D6E8);

  static const dark = JisrColors(
    heading: darkHeading,
    body: darkBody,
    muted: Color(0xFF8FA6B8),
    line: Color(0xFF243D5C),
    card: Color(0xFF152B45),
    tintTeal: Color(0xFF0E3A3E),
    tintGreen: Color(0xFF173A22),
    tintOrange: Color(0xFF43301A),
    tintYellow: Color(0xFF3F3418),
    onTint: Color(0xFFE8F1F8),
    success: Color(0xFF7BCF7E),
  );

  static JisrColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// ثيم التطبيق الموحّد (فاتح)
ThemeData buildJisrTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      primary: AppColors.navy,
      secondary: AppColors.teal,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  return base.copyWith(
    // نصوص أكبر قليلاً لسهولة القراءة
    textTheme: base.textTheme.copyWith(
      bodyMedium: const TextStyle(fontSize: 16, color: AppColors.ink),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    ),

    // شريط علوي شفاف — يُستبدل بتدرّج في الشاشات عبر flexibleSpace
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

    // بطاقات بيضاء بحوافّ دائرية وظل ناعم أزرق
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(56, 56),
        side: const BorderSide(color: AppColors.lineCool, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.tealDeep,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // حقول إدخال بيضاء دائرية الحواف
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lineCool, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.lineCool, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
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
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
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

/// ثيم عالي التباين للعمى / ضعف البصر الشديد
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

/// شريط علوي بتدرّج الهوية — بديل موحّد عن AppBar الافتراضي
class JisrAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const JisrAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
    );
  }
}