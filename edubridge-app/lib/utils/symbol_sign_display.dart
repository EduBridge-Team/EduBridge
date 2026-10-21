import '../l10n/generated/app_localizations.dart';

/// Translates presentation while preserving the original learning content IDs.
abstract final class SymbolSignDisplay {
  static String symbol(String canonical, AppLocalizations strings) => switch (canonical) {
    'مثلث' => strings.choiceShapeTriangle,
    'دائرة' => strings.choiceShapeCircle,
    'مربع' => strings.choiceShapeSquare,
    'نجمة' => strings.choiceShapeStar,
    'معين' => strings.choiceShapeRhombus,
    'قلب' => strings.choiceShapeHeart,
    _ => canonical,
  };
  static String sign(String canonical, AppLocalizations strings) => switch (canonical) {
    'إصبع الإبهام مرفوع' => strings.signDescriptionThumb,
    'كف مفتوح مستقيم' => strings.signDescriptionPalm,
    'إصبعان مفتوحان' => strings.signDescriptionTwo,
    'ثلاثة أصابع' => strings.signDescriptionThree,
    'قبضة مغلقة' => strings.signDescriptionFist,
    'الإبهام والخنصر' => strings.signDescriptionThumbPinky,
    'إصبعان متقاطعان' => strings.signDescriptionCrossed,
    'إصبع واحد مرفوع' => strings.signDescriptionOne,
    _ => canonical,
  };
}
