import '../../l10n/generated/app_localizations.dart';

/// Translate known catalog identifiers for display; preserve custom values.
class DisabilityDisplay {
  static String label(String value, AppLocalizations strings) => switch (value) {
    'الإعاقات البصرية' => strings.disabilityVisual,
    'الإعاقات السمعية' => strings.disabilityHearing,
    'اضطرابات النطق واللغة' => strings.disabilitySpeechLanguage,
    'الإعاقات الحركية والشلل' => strings.disabilityMotor,
    'إصابات وأمراض الدماغ' => strings.disabilityBrain,
    'الاضطرابات النمائية والسلوكية' => strings.disabilityDevelopmentBehavior,
    'الإعاقات الذهنية وصعوبات التعلم' => strings.disabilityIntellectualLearning,
    'شبه كفيف' => strings.disabilityPartialBlindness,
    'كفيف كلي' => strings.disabilityTotalBlindness,
    'فقد عين واحدة' => strings.disabilityLossOneEye,
    'عمى الألوان' => strings.disabilityColorBlindness,
    'ضعف سمع خفيف (25 - 40 ديسبل)' => strings.disabilityMildHearing,
    'ضعف سمع متوسط (41 - 60 ديسبل)' => strings.disabilityModerateHearing,
    'ضعف سمع شديد (61 - 85 ديسبل)' => strings.disabilitySevereHearing,
    'ضعف سمع شديد جداً (من 90 ديسبل فما فوق)' => strings.disabilityProfoundHearing,
    'أصم' => strings.disabilityDeaf,
    'زارعي القوقعة' => strings.disabilityCochlearImplant,
    'تأتأة' => strings.disabilityStuttering,
    'تأخر اللغة الاستيعابية' => strings.disabilityReceptiveLanguage,
    'تأخر اللغة التعبيرية' => strings.disabilityExpressiveLanguage,
    'الحبسة الكلامية' => strings.disabilityAphasia,
    'تأخر النطق' => strings.disabilitySpeechDelay,
    'تأخر في الكلام والنطق واللغة' => strings.disabilitySpeechLanguageDelay,
    'شلل دماغي' => strings.disabilityCerebralPalsy,
    'شلل رباعي' => strings.disabilityQuadriplegia,
    'شلل نصفي سفلي' => strings.disabilityParaplegia,
    'شلل نصفي طولي' => strings.disabilityHemiplegia,
    'شلل ثلاثي' => strings.disabilityTriplegia,
    'شلل أحادي' => strings.disabilityMonoplegia,
    'شلل أطفال أحادي' => strings.disabilityPolioOneLimb,
    'شلل أطفال مزدوج' => strings.disabilityPolioTwoLimbs,
    'استسقاء الحبل الشوكي' => strings.disabilitySpinalHydrocephalus,
    'إصابات الحبل الشوكي' => strings.disabilitySpinalInjury,
    'العظم الزجاجي' => strings.disabilityBrittleBone,
    'أمراض عصبية' => strings.disabilityNeurological,
    'ضمور في الدماغ' => strings.disabilityBrainAtrophy,
    'إصابات دماغ' => strings.disabilityBrainInjury,
    'الصرع' => strings.disabilityEpilepsy,
    'طيف التوحّد (بسيط/متوسط)' => strings.disabilityAutismMild,
    'طيف التوحّد (شديد)' => strings.disabilityAutismSevere,
    'فرط الحركة وتشتت الانتباه' => strings.disabilityAdhd,
    'اضطرابات فصام الشخصية' => strings.disabilitySchizophrenia,
    'اضطرابات عصاب التحول' => strings.disabilityConversion,
    'اضطرابات سلوك الأطفال' => strings.disabilityChildBehavior,
    'صعوبة تعلم - معامل الذكاء (I.Q 71 - 89)' => strings.disabilityLearningIq,
    'تخلف عقلي بسيط - معامل الذكاء (I.Q 55 - 70)' => strings.disabilityIntellectualMild,
    'تخلف عقلي متوسط - معامل الذكاء (I.Q 41 - 54)' => strings.disabilityIntellectualModerate,
    'تخلف عقلي شديد - معامل الذكاء (I.Q 26 - 40)' => strings.disabilityIntellectualSevere,
    'تخلف عقلي شديد جداً - معامل الذكاء (I.Q < 25)' => strings.disabilityIntellectualProfound,
    'متلازمة داون' => strings.disabilityDownSyndrome,
    'أخرى' => strings.otherDisability,
    'بدون تكييف' => strings.noAdaptation,
    'غير محدد' => strings.notSpecified,
    _ => value,
  };

  /// Accept canonical Arabic and the currently displayed translation.
  static bool matches(String value, String query, AppLocalizations strings) {
    final search = query.trim().toLowerCase();
    return value.toLowerCase().contains(search) ||
        label(value, strings).toLowerCase().contains(search);
  }
}
