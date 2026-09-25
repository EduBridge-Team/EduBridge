// EduBridge palette and semantic colors.
part of 'theme.dart';

class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════════════
  //  🎨 ألوان الهوية البصرية الرسمية — EduBridge
  // ═══════════════════════════════════════════════════════════

  /// اللون الأساسي — أزرق ملكي (Edu)
  static const brandBlue       = Color(0xFF1769C2);
  static const brandBlueDeep   = Color(0xFF0D55AA);
  static const brandBlueLight  = Color(0xFF2A8AD5);

  /// اللون الثانوي — تركوازي (الأيقونة)
  static const brandTeal       = Color(0xFF21BFD0);
  static const brandTealDeep   = Color(0xFF119EAE);
  static const brandTealLight  = Color(0xFF69D4CA);

  /// لون التمييز — أخضر فاتح (Bridge)
  static const brandGreen      = Color(0xFF7BE49A);
  static const brandGreenDeep  = Color(0xFF57B25A);

  // ═══════════════════════════════════════════════════════════
  //  Aliases — للتوافق مع الكود القديم (لا تكسر شيئاً)
  // ═══════════════════════════════════════════════════════════
  static const navy       = brandBlue;
  static const navyDeep   = brandBlueDeep;
  static const blue       = brandBlueLight;
  static const teal       = brandTeal;
  static const tealDeep   = brandTealDeep;
  static const lightTeal  = brandTealLight;

  static const green      = brandGreenDeep;  // للنجاح (مقروء)
  static const greenDeep  = Color(0xFF3F9142);
  static const orange     = Color(0xFFF2842B);
  static const orangeDeep = Color(0xFFD96E17);
  static const yellow     = Color(0xFFFFC23C);
  static const pink       = Color(0xFFF06C8B);
  static const red        = Color(0xFFE53935);
  static const purple     = Color(0xFF8B6DD4);

  static const cream      = Color(0xFFF8FCFF);

  // خلفيات خفيفة من الهوية
  static const tintBlue   = Color(0xFFE9F5FF);
  static const tintTeal   = Color(0xFFE4F9FB);
  static const tintGreen  = Color(0xFFE6F8EC);   // ← فاتح ليتناسب مع brandGreen
  static const tintOrange = Color(0xFFFFF0E0);
  static const tintYellow = Color(0xFFFFF8E1);

  static const ink   = Color(0xFF183F6B);
  static const muted = Color(0xFF6884A4);

  static const lineCool = Color(0xFFD9EBF7);

  /// لوحة الألوان للأطفال — من الهوية
  static const kidPalette = [
    Color(0xFF1769C2), // أزرق ملكي
    Color(0xFF21BFD0), // تركوازي
    Color(0xFF7BE49A), // أخضر الهوية
    Color(0xFF2A8AD5), // أزرق متوسط
    Color(0xFF69D4CA), // تركوازي فاتح
  ];

  /// التدرّج الرئيسي — من أعلى اليمين (أزرق) إلى أسفل اليسار (تركوازي)
  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      brandBlue,       // #1769C2
      brandBlueDeep,   // #0D55AA
      brandTeal,       // #21BFD0
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// تدرّج التمييز — أزرق → تركوازي (بدون الأخضر لتجنّب الإزعاج البصري)
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBlueLight, brandTeal],
  );

  /// تدرّج خاص للأزرار الرئيسية
  static const primaryGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [brandBlue, brandBlueDeep],
  );
}
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
