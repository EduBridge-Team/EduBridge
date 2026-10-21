import '../l10n/generated/app_localizations.dart';

/// Display-only translations keep content-history IDs stable.
abstract final class ChoiceGameDisplay {
  static String color(int index, AppLocalizations strings) => switch (index) {
    0 => strings.choiceColorRed,
    1 => strings.choiceColorBlue,
    2 => strings.choiceColorGreen,
    3 => strings.choiceColorYellow,
    4 => strings.choiceColorPurple,
    5 => strings.choiceColorOrange,
    6 => strings.choiceColorPink,
    7 => strings.choiceColorBrown,
    8 => strings.choiceColorGrey,
    9 => strings.choiceColorBlack,
    _ => throw RangeError.index(index, const [], 'index'),
  };
  static String shape(int index, AppLocalizations strings) => switch (index) {
    0 => strings.choiceShapeTriangle,
    1 => strings.choiceShapeSquare,
    2 => strings.choiceShapeCircle,
    3 => strings.choiceShapeStar,
    4 => strings.choiceShapeHeart,
    5 => strings.choiceShapeHexagon,
    6 => strings.choiceShapeRhombus,
    7 => strings.choiceShapeRectangle,
    8 => strings.choiceShapeOval,
    _ => throw RangeError.index(index, const [], 'index'),
  };
  static String shapeHint(int index, AppLocalizations strings) => switch (index) {
    0 => strings.choiceShapeHintTriangle,
    1 => strings.choiceShapeHintSquare,
    2 => strings.choiceShapeHintCircle,
    3 => strings.choiceShapeHintStar,
    4 => strings.choiceShapeHintHeart,
    5 => strings.choiceShapeHintHexagon,
    6 => strings.choiceShapeHintRhombus,
    7 => strings.choiceShapeHintRectangle,
    8 => strings.choiceShapeHintOval,
    _ => throw RangeError.index(index, const [], 'index'),
  };
  static String number(int index, AppLocalizations strings) => switch (index) {
    0 => strings.choiceNumber1,
    1 => strings.choiceNumber2,
    2 => strings.choiceNumber3,
    3 => strings.choiceNumber4,
    4 => strings.choiceNumber5,
    5 => strings.choiceNumber6,
    6 => strings.choiceNumber7,
    7 => strings.choiceNumber8,
    8 => strings.choiceNumber9,
    9 => strings.choiceNumber10,
    _ => throw RangeError.index(index, const [], 'index'),
  };
  static String question(String emoji, AppLocalizations strings) => switch (emoji) {
    '🍎' => strings.choiceQuestionApple,
    '⭐' => strings.choiceQuestionStar,
    '⚽' => strings.choiceQuestionBall,
    '🌸' => strings.choiceQuestionFlower,
    '🐟' => strings.choiceQuestionFish,
    '🦋' => strings.choiceQuestionButterfly,
    _ => throw ArgumentError.value(emoji, 'emoji'),
  };
  static String count(String emoji, AppLocalizations strings, int count) => switch (emoji) {
    '🍎' => strings.choiceCountApple(count),
    '⭐' => strings.choiceCountStar(count),
    '⚽' => strings.choiceCountBall(count),
    '🌸' => strings.choiceCountFlower(count),
    '🐟' => strings.choiceCountFish(count),
    '🦋' => strings.choiceCountButterfly(count),
    _ => throw ArgumentError.value(emoji, 'emoji'),
  };
  static String hint(String emoji, AppLocalizations strings, String numbers) => switch (emoji) {
    '🍎' => strings.choiceHintApple(numbers),
    '⭐' => strings.choiceHintStar(numbers),
    '⚽' => strings.choiceHintBall(numbers),
    '🌸' => strings.choiceHintFlower(numbers),
    '🐟' => strings.choiceHintFish(numbers),
    '🦋' => strings.choiceHintButterfly(numbers),
    _ => throw ArgumentError.value(emoji, 'emoji'),
  };
}
