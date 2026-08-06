// هوية «جسر التعليمي» — نظام التصميم المشترك للتطبيق
// لوحة ألوان مستوحاة من الشعار: كحلي، تركوازي، أخضر، برتقالي
// مع خلفية دافئة وحوافّ دائرية
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

  // الألوان الأساسية
  static const navy = Color(0xFF153A5B);
  static const navyDeep = Color(0xFF0D2740);
  static const teal = Color(0xFF1AA9B2);
  static const tealDeep = Color(0xFF0F7D84);
  static const green = Color(0xFF57B25A);
  static const greenDeep = Color(0xFF3F9142);
  static const orange = Color(0xFFF2842B);
  static const orangeDeep = Color(0xFFD96E17);
  static const yellow = Color(0xFFFFC23C);
  static const pink = Color(0xFFF06C8B);

  // خلفيات وأسطح
  static const cream = Color(0xFFFDF6EC);
  static const tintTeal = Color(0xFFD7F1F2);
  static const tintGreen = Color(0xFFDDF1DD);
  static const tintOrange = Color(0xFFFDE3CD);
  static const tintYellow = Color(0xFFFFEEC1);

  // نصوص وحدود
  static const ink = Color(0xFF12283A);
  static const muted = Color(0xFF5C7183);
  static const lineCool = Color(0xFFDFEEF2);

  /// ألوان متناوبة لبطاقات/صور الأطفال
  static const kidPalette = [teal, green, orange, pink, navy];

  /// تدرّج الهوية للرؤوس (كحلي ← تركوازي)
  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [navy, Color(0xFF185A78), tealDeep],
  );
}

/// ألوان متكيّفة مع الوضع (فاتح/ليلي) — للنصوص والخلفيات الملوّنة
/// الاستخدام داخل build: final c = JisrColors.of(context);
class JisrColors {
  final Color heading; // العناوين (بدل navy)
  final Color body; // النصوص (بدل ink)
  final Color muted; // النصوص الثانوية
  final Color line; // الحدود
  final Color card; // خلفية البطاقات
  final Color tintTeal;
  final Color tintGreen;
  final Color tintOrange;
  final Color tintYellow;
  final Color onTint; // نص فوق الخلفيات الملوّنة
  final Color success; // نصوص النجاح/الشارات المحقّقة

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

  // ألوان الوضع الليلي — ثوابت مستقلة لاستخدامها داخل const
  static const darkHeading = Color(0xFFDCEBF7);
  static const darkBody = Color(0xFFC6D8E6);

  static const dark = JisrColors(
    heading: darkHeading,
    body: darkBody,
    muted: Color(0xFF8FA6B8),
    line: Color(0xFF24425C),
    card: Color(0xFF14324B),
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

/// ثيم التطبيق الموحّد
ThemeData buildJisrTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.tealDeep,
      secondary: AppColors.orange,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  return base.copyWith(
    // نصوص أكبر قليلاً لسهولة القراءة (accessibility)
    textTheme: base.textTheme.copyWith(
      bodyMedium: const TextStyle(fontSize: 16, color: AppColors.ink),
      titleLarge: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    ),

    // شريط علوي كحلي — يُستبدل بتدرّج في الشاشات عبر flexibleSpace
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

    // بطاقات بيضاء بحوافّ دائرية وظل ناعم
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.lineCool),
      ),
      shadowColor: const Color(0x33153A5B), // كحلي بشفافية 20٪
    ),

    // أزرار برتقالية كبيرة (≥ 56) بحوافّ دائرية
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
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
  );
}

/// ثيم الوضع الليلي — نفس الهوية على خلفية كحلية داكنة هادئة
ThemeData buildJisrDarkTheme() {
  const bg = Color(0xFF0B1E30);
  const card = JisrColors.dark;

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.dark,
      primary: AppColors.teal,
      secondary: AppColors.orange,
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
        side: const BorderSide(color: Color(0xFF24425C)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
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
