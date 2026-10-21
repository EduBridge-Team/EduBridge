import '../l10n/generated/app_localizations.dart';

/// Canonical word IDs remain unchanged for answers and game history.
abstract final class VisualWordDisplay {
  static String word(String canonical, AppLocalizations strings) => switch (canonical) {
    'تفاحة' => strings.visualWordApple,
    'كلب' => strings.visualWordDog,
    'بيت' => strings.visualWordHouse,
    'شمس' => strings.visualWordSun,
    'قمر' => strings.visualWordMoon,
    'سيارة' => strings.visualWordCar,
    'شجرة' => strings.visualWordTree,
    'سمكة' => strings.visualWordFish,
    'كتاب' => strings.visualWordBook,
    'قلم' => strings.visualWordPen,
    'دبدوب' => strings.visualWordTeddy,
    'دراجة' => strings.visualWordBicycle,
    'موز' => strings.visualWordBanana,
    'عنب' => strings.visualWordGrapes,
    'زهرة' => strings.visualWordFlower,
    'فيل' => strings.visualWordElephant,
    'سلحفاة' => strings.visualWordTurtle,
    'فراشة' => strings.visualWordButterfly,
    'طائرة' => strings.visualWordPlane,
    'قطار' => strings.visualWordTrain,
    'كرة' => strings.visualWordBall,
    'مفتاح' => strings.visualWordKey,
    'ساعة' => strings.visualWordClock,
    'جزر' => strings.visualWordCarrot,
    _ => canonical,
  };
}
