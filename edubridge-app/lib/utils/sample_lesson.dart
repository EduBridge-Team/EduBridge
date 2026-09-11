// دروس تجريبية لكل نوع إعاقة — للاختبار والعرض
import '../services/accessibility_service.dart';

class SampleLesson {
  final String title;
  final String content;
  final String emoji;
  final List<String> steps; // للدرس خطوة بخطوة

  const SampleLesson({
    required this.title,
    required this.content,
    required this.emoji,
    this.steps = const [],
  });
}

/// يعيد دروساً تجريبية حسب نوع الإعاقة
List<Map<String, dynamic>> getSampleLessons(DisabilityType type) {
  switch (type) {
    // ═════════════════════════════════════════════
    // 1. ADHD — دروس قصيرة، حيوية، تفاعلية
    // ═════════════════════════════════════════════
    case DisabilityType.adhd:
      return [
        {
          'id': -1,
          'title': '⚡ الأرقام السريعة',
          'content':
              'لعبة سريعة لتعلّم الأرقام من 1 إلى 10. عندك 30 ثانية!',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🎨 ألوان حولنا',
          'content': 'تعرّف على الألوان الأساسية: أحمر، أزرق، أصفر.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '🏃 حروف وحركة',
          'content': 'اقفز مع كل حرف: ألف، باء، تاء.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 2. توحّد — دروس ثابتة، روتينية، واضحة
    // ═════════════════════════════════════════════
    case DisabilityType.autismMild:
    case DisabilityType.autismSevere:
      return [
        {
          'id': -1,
          'title': '🌅 الروتين اليومي',
          'content':
              'نتعلّم خطوات الصباح: ١. أستيقظ، ٢. أغسل وجهي، ٣. ألبس ملابسي.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🔢 العدّ من 1 إلى 5',
          'content':
              'خطوة بخطوة: واحد، اثنان، ثلاثة، أربعة، خمسة.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '🎨 الألوان الهادئة',
          'content':
              'تعلّم اللون الأزرق: لون السماء والبحر.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 3. داون — دروس بسيطة، مصوّرة، بطيئة
    // ═════════════════════════════════════════════
    case DisabilityType.downSyndrome:
      return [
        {
          'id': -1,
          'title': '🍎 الفواكه',
          'content':
              'هذه تفاحة 🍎. التفاحة لونها أحمر. أكل التفاحة مفيد!',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🐶 الحيوانات',
          'content':
              'هذا كلب 🐶. الكلب يقول: هَو هَو. الكلب صديق الإنسان.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '🌞 الطقس',
          'content':
              'اليوم الشمس مشرقة ☀️. نلبس ملابس خفيفة. نشرب ماء كثيراً.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 4. عمى — دروس صوتية، وصفية، مفصّلة
    // ═════════════════════════════════════════════
    case DisabilityType.blind:
      return [
        {
          'id': -1,
          'title': '🎵 أصوات الحيوانات',
          'content':
              'سنستمع لأصوات الحيوانات. الكلب يعوي: هَو هَو. القطة تموء: مياو.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '✋ الملمس والأشكال',
          'content':
              'المستطيل له 4 أضلاع. المربع كل أضلاعه متساوية. الدائرة ليس لها زوايا.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '👃 الروائح',
          'content':
              'الوردة لها رائحة جميلة 🌹. الليمون له رائحة حامضة 🍋.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 5. طرش — دروس بصرية، نصوص، إشارات
    // ═════════════════════════════════════════════
    case DisabilityType.deaf:
      return [
        {
          'id': -1,
          'title': '🤟 حروف الإشارة',
          'content':
              'تعلّم إشارة حرف الألف: ارفع إبهامك للأعلى 👍. حرف الباء: افتح كفّك ✋.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '📖 القراءة البصرية',
          'content':
              'انظر للكلمات: بيت 🏠، شمس ☀️، قمر 🌙. اربط كل كلمة بصورتها.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '🎨 الألوان بالإشارة',
          'content':
              'الأحمر: ضع إصبعك على شفتيك. الأزرق: أشر للسماء.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 6. تأتأة — دروس قصيرة، بطيئة، بدون ضغط
    // ═════════════════════════════════════════════
    case DisabilityType.stuttering:
      return [
        {
          'id': -1,
          'title': '🐢 القراءة البطيئة',
          'content':
              'اقرأ معي ببطء: أنا... أحب... القراءة. لا يوجد وقت محدّد.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🎵 الإيقاع والكلام',
          'content':
              'انقر بإصبعك مع كل كلمة: بيت، شمس، قمر. الإيقاع يساعد على الطلاقة.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 7. اضطرابات نطق
    // ═════════════════════════════════════════════
    case DisabilityType.speechDisorders:
      return [
        {
          'id': -1,
          'title': '👄 تمارين النطق',
          'content':
              'قل: را را را (بحرف الراء). سا سا سا (بحرف السين). شا شا شا (بحرف الشين).',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🎤 أصوات الحروف',
          'content':
              'كل حرف له صوت: ب مثل بيضة 🥚. ت مثل تفاحة 🍎. س مثل سمكة 🐟.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 8. إعاقة ذهنية بسيطة — خطوة بخطوة
    // ═════════════════════════════════════════════
    case DisabilityType.mildIntellectual:
      return [
        {
          'id': -1,
          'title': '🧼 غسل اليدين',
          'content':
              'الخطوة 1: افتح الماء. الخطوة 2: ضع الصابون. الخطوة 3: افرك يديك. الخطوة 4: اشطف بالماء. الخطوة 5: جفّف يديك.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🍽️ آداب الطعام',
          'content':
              'الخطوة 1: اجلس على الكرسي. الخطوة 2: قل "بسم الله". الخطوة 3: استخدم الملعقة. الخطوة 4: كل بهدوء.',
          'is_sample': true,
        },
        {
          'id': -3,
          'title': '👕 ترتيب الملابس',
          'content':
              'الخطوة 1: افتح الخزانة. الخطوة 2: ضع القمصان معاً. الخطوة 3: ضع البناطيل معاً. الخطوة 4: أغلق الخزانة.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 9. عمى ألوان
    // ═════════════════════════════════════════════
    case DisabilityType.colorBlindness:
      return [
        {
          'id': -1,
          'title': '🔴 تعلّم الألوان بالرموز',
          'content':
              'أحمر ▲ - أزرق ■ - أخضر ● - أصفر ★. هذه الرموز تساعدك على التمييز.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🎨 الأنماط والتصنيف',
          'content':
              'صنّف الأشكال حسب الشكل (وليس اللون): المربعات معاً، الدوائر معاً.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 10. صرع — دروس هادئة، بدون وميض
    // ═════════════════════════════════════════════
    case DisabilityType.epilepsy:
      return [
        {
          'id': -1,
          'title': '🧘 التنفّس الهادئ',
          'content':
              'خذ نفساً عميقاً (4 ثوانٍ). احتفظ بالهواء (4 ثوانٍ). أخرجه ببطء (6 ثوانٍ).',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '📖 قصة هادئة',
          'content':
              'كان هناك أرنب صغير 🐰 يعيش في غابة خضراء. كل يوم يأكل الجزر ويستمع لأصوات الطيور.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 11. أخرى
    // ═════════════════════════════════════════════
    case DisabilityType.other:
      return [
        {
          'id': -1,
          'title': '📚 درس تجريبي',
          'content':
              'هذا درس تجريبي لعرض شكل المحتوى حسب الإعاقة المخصّصة.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🎯 درس قابل للتخصيص',
          'content':
              'يمكنك تخصيص هذا الدرس بما يناسب احتياجات الطفل.',
          'is_sample': true,
        },
      ];

    // ═════════════════════════════════════════════
    // 12. بدون إعاقة
    // ═════════════════════════════════════════════
    case DisabilityType.none:
    default:
      return [
        {
          'id': -1,
          'title': '📖 درس تجريبي',
          'content':
              'هذا درس تجريبي لعرض الشكل الطبيعي للدروس في التطبيق.',
          'is_sample': true,
        },
        {
          'id': -2,
          'title': '🌍 التعلّم والمتعة',
          'content':
              'هنا يمكنك أن تجد كل الدروس التعليمية الممتعة.',
          'is_sample': true,
        },
      ];
  }
}

/// يعيد إيموجي مميّز لكل إعاقة
String getDisabilityEmoji(DisabilityType type) {
  switch (type) {
    case DisabilityType.adhd:
      return '⚡';
    case DisabilityType.autismMild:
    case DisabilityType.autismSevere:
      return '🧩';
    case DisabilityType.downSyndrome:
      return '💙';
    case DisabilityType.blind:
      return '👁️';
    case DisabilityType.deaf:
      return '👂';
    case DisabilityType.stuttering:
      return '🗣️';
    case DisabilityType.speechDisorders:
      return '💬';
    case DisabilityType.mildIntellectual:
      return '🧠';
    case DisabilityType.colorBlindness:
      return '🌈';
    case DisabilityType.epilepsy:
      return '⚕️';
    case DisabilityType.other:
      return '✏️';
    case DisabilityType.none:
    default:
      return '📚';
  }
}