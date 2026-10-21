import '../l10n/generated/app_localizations.dart';

abstract final class RhythmWordDisplay {
  static String word(String canonical, AppLocalizations strings) => switch (canonical) {
    'بيت' => strings.rhythmWordHouse,
    'شمس' => strings.rhythmWordSun,
    'قمر' => strings.rhythmWordMoon,
    'نجم' => strings.rhythmWordStar,
    'ماء' => strings.rhythmWordWater,
    'خبز' => strings.rhythmWordBread,
    'كتاب' => strings.rhythmWordBook,
    'قلم' => strings.rhythmWordPen,
    'باب' => strings.rhythmWordDoor,
    'نور' => strings.rhythmWordLight,
    'زهر' => strings.rhythmWordBlossom,
    'ورد' => strings.rhythmWordRose,
    _ => canonical,
  };
}
