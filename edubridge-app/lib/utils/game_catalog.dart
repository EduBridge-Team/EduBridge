// فهرس الألعاب — يُحدّد أي لعبة تناسب أي عمر وإعاقة
import '../services/accessibility_service.dart';

enum AgeGroup {
  preschool,   // 4-6 سنوات
  primary,     // 7-10 سنوات
  preparatory, // 11-15 سنة
}

AgeGroup ageGroupOf(int age) {
  if (age <= 6) return AgeGroup.preschool;
  if (age <= 10) return AgeGroup.primary;
  return AgeGroup.preparatory;
}

String ageGroupLabel(AgeGroup g) {
  switch (g) {
    case AgeGroup.preschool:
      return 'رياض الأطفال (4-6)';
    case AgeGroup.primary:
      return 'الابتدائي (7-10)';
    case AgeGroup.preparatory:
      return 'الإعدادي (11-15)';
  }
}

class GameInfo {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final List<AgeGroup> ages;
  final List<DisabilityType> disabilities;
  final bool isUniversal; // تناسب الجميع

  const GameInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.ages,
    this.disabilities = const [],
    this.isUniversal = false,
  });
}

// ═══════════════════════════════════════════════════════════
//  فهرس جميع الألعاب
// ═══════════════════════════════════════════════════════════
const kGameCatalog = <GameInfo>[
  // ═══ الحسّية والانتباه ═══
  GameInfo(
    id: 'animal_sounds',
    title: 'أصوات الحيوانات',
    description: 'استمع وحدّد الحيوان',
    emoji: '🐶',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    isUniversal: true,
  ),
  GameInfo(
    id: 'matching',
    title: 'المطابقة',
    description: 'اعثر على البطاقات المتشابهة',
    emoji: '🎴',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    isUniversal: true,
  ),
  GameInfo(
    id: 'shapes',
    title: 'الأشكال',
    description: 'تعرّف على الأشكال الهندسية',
    emoji: '🔺',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    isUniversal: true,
  ),

  // ═══ الألوان والرموز ═══
  GameInfo(
    id: 'colors_simple',
    title: 'الألوان',
    description: 'اختر اللون الصحيح',
    emoji: '🎨',
    ages: [AgeGroup.preschool],
    isUniversal: true,
  ),
  GameInfo(
    id: 'colors_symbols',
    title: 'الألوان بالرموز',
    description: 'تعلّم الألوان بدون الاعتماد على البصر',
    emoji: '🌈',
    ages: [AgeGroup.preschool, AgeGroup.primary, AgeGroup.preparatory],
    disabilities: [
      DisabilityType.colorBlindness,
      DisabilityType.blind,
    ],
  ),

  // ═══ الأرقام والحساب ═══
  GameInfo(
    id: 'numbers_count',
    title: 'العدّ البسيط',
    description: 'اعدّ من 1 إلى 10',
    emoji: '🔢',
    ages: [AgeGroup.preschool],
    isUniversal: true,
  ),
  GameInfo(
    id: 'numbers_math',
    title: 'سباق الحساب',
    description: 'حلّ المسائل بسرعة',
    emoji: '➕',
    ages: [AgeGroup.primary, AgeGroup.preparatory],
    disabilities: [
      DisabilityType.adhd,
      DisabilityType.mildIntellectual,
      DisabilityType.none,
    ],
    isUniversal: true,
  ),

  // ═══ الكلمات والقراءة ═══
  GameInfo(
    id: 'visual_words',
    title: 'الكلمات البصرية',
    description: 'اربط الصورة بالكلمة',
    emoji: '💙',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    isUniversal: true,
  ),
  GameInfo(
    id: 'word_builder',
    title: 'بناء الكلمة',
    description: 'رتّب الحروف لتكوين كلمة',
    emoji: '🔤',
    ages: [AgeGroup.primary, AgeGroup.preparatory],
    isUniversal: true,
  ),

  // ═══ التسلسل والمنطق ═══
  GameInfo(
    id: 'sequence_simple',
    title: 'الترتيب البسيط',
    description: 'رتّب الصور حسب الترتيب',
    emoji: '🧩',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    disabilities: [
      DisabilityType.autismMild,
      DisabilityType.autismSevere,
      DisabilityType.mildIntellectual,
    ],
    isUniversal: true,
  ),
  GameInfo(
    id: 'story_sequencer',
    title: 'رتّب القصة',
    description: 'رتّب أحداث القصة',
    emoji: '📖',
    ages: [AgeGroup.primary, AgeGroup.preparatory],
    isUniversal: true,
  ),
  GameInfo(
    id: 'logic_puzzle',
    title: 'لغز المنطق',
    description: 'فكّر وحلّ اللغز',
    emoji: '🧠',
    ages: [AgeGroup.preparatory],
    isUniversal: true,
  ),

  // ═══ الأصوات والسمع (للأعمى) ═══
  GameInfo(
    id: 'audio_matching',
    title: 'لعبة الأصوات',
    description: 'استمع وطابق الأصوات',
    emoji: '🎧',
    ages: [AgeGroup.preschool, AgeGroup.primary, AgeGroup.preparatory],
    disabilities: [DisabilityType.blind],
  ),

  // ═══ الإشارة (للأصمّ) ═══
  GameInfo(
    id: 'sign_language',
    title: 'لغة الإشارة',
    description: 'تعلّم الحروف بالإشارة',
    emoji: '🤟',
    ages: [AgeGroup.preschool, AgeGroup.primary, AgeGroup.preparatory],
    disabilities: [DisabilityType.deaf],
  ),

  // ═══ الحركة (ADHD) ═══
  GameInfo(
    id: 'quick_action',
    title: 'الحركة السريعة',
    description: 'تحرّك بسرعة! 30 ثانية',
    emoji: '⚡',
    ages: [AgeGroup.preschool, AgeGroup.primary],
    disabilities: [DisabilityType.adhd],
  ),

  // ═══ الإيقاع (التأتأة) ═══
  GameInfo(
    id: 'rhythm',
    title: 'الإيقاع',
    description: 'انقر مع الكلمات',
    emoji: '🎵',
    ages: [AgeGroup.preschool, AgeGroup.primary, AgeGroup.preparatory],
    disabilities: [
      DisabilityType.stuttering,
      DisabilityType.speechDisorders,
    ],
  ),
];

/// الألعاب المناسبة لبروفايل معيّن + عمر
List<GameInfo> gamesFor(DisabilityType type, AgeGroup age) {
  return kGameCatalog.where((game) {
    // 1. يجب أن تناسب العمر
    if (!game.ages.contains(age)) return false;

    // 2. إذا كانت "للجميع" → مناسبة
    if (game.isUniversal) return true;

    // 3. إذا كانت مخصّصة → يجب أن يكون النوع ضمن disabilities
    return game.disabilities.contains(type);
  }).toList();
}