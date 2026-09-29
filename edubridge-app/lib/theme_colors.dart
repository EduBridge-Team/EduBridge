// EduBridge palette and semantic colors.
part of 'theme.dart';

class AppColors {
  AppColors._();

  // Brand identity — kept unchanged.
  static const brandBlue = Color(0xFF1769C2);
  static const brandBlueDeep = Color(0xFF0D55AA);
  static const brandBlueLight = Color(0xFF2A8AD5);
  static const brandTeal = Color(0xFF21BFD0);
  static const brandTealDeep = Color(0xFF119EAE);
  static const brandTealLight = Color(0xFF69D4CA);
  static const brandGreen = Color(0xFF7BE49A);
  static const brandGreenDeep = Color(0xFF57B25A);

  // Compatibility aliases.
  static const navy = brandBlue;
  static const navyDeep = brandBlueDeep;
  static const blue = brandBlueLight;
  static const teal = brandTeal;
  static const tealDeep = brandTealDeep;
  static const lightTeal = brandTealLight;

  static const green = brandGreenDeep;
  static const greenDeep = Color(0xFF3F9142);
  static const orange = Color(0xFFF2842B);
  static const orangeDeep = Color(0xFFD96E17);
  static const yellow = Color(0xFFFFC23C);
  static const pink = Color(0xFFF06C8B);
  static const red = Color(0xFFE53935);
  static const purple = Color(0xFF8B6DD4);

  // New neutral system: the brand has more room to breathe.
  static const cream = Color(0xFFF6F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF0F6FB);
  static const surfaceStrong = Color(0xFFEAF2F8);
  static const ink = Color(0xFF102A43);
  static const muted = Color(0xFF637B92);
  static const lineCool = Color(0xFFDCE8F1);

  static const tintBlue = Color(0xFFEAF4FF);
  static const tintTeal = Color(0xFFE7F9FB);
  static const tintGreen = Color(0xFFEAF9EE);
  static const tintOrange = Color(0xFFFFF1E5);
  static const tintYellow = Color(0xFFFFF8E4);

  static const kidPalette = [
    brandBlue,
    brandTeal,
    brandGreen,
    brandBlueLight,
    brandTealLight,
  ];

  static const headerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [brandBlue, brandBlueDeep, brandTeal],
    stops: [0.0, 0.55, 1.0],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [brandBlueLight, brandTeal],
  );

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
    heading: AppColors.ink,
    body: Color(0xFF294861),
    muted: AppColors.muted,
    line: AppColors.lineCool,
    card: AppColors.surface,
    tintTeal: AppColors.tintTeal,
    tintGreen: AppColors.tintGreen,
    tintOrange: AppColors.tintOrange,
    tintYellow: AppColors.tintYellow,
    onTint: AppColors.ink,
    success: AppColors.greenDeep,
  );

  static const darkHeading = Color(0xFFF1F7FC);
  static const darkBody = Color(0xFFD2DFEA);

  static const dark = JisrColors(
    heading: darkHeading,
    body: darkBody,
    muted: Color(0xFF91A8BA),
    line: Color(0xFF263E54),
    card: Color(0xFF142A3C),
    tintTeal: Color(0xFF103A40),
    tintGreen: Color(0xFF183B26),
    tintOrange: Color(0xFF45311E),
    tintYellow: Color(0xFF42371D),
    onTint: Color(0xFFF0F6FA),
    success: Color(0xFF81D38A),
  );

  static JisrColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
