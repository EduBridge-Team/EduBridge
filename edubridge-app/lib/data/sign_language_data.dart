// lib/data/sign_language_data.dart
// ═══════════════════════════════════════════════════════════
//  قاعدة بيانات لغة الإشارة العربية
//  - 100 رمز مُصنّف في 4 فئات
//  - حاليّاً أيقونات Material (يمكن ترقيتها لصور لاحقاً)
//  - كل عنصر يحمل: الحرف + النص المعروض + النص المنطوق + التلميح
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
//  عنصر واحد من رموز الإشارة
// ═══════════════════════════════════════════════════════════
class SignItem {
  /// الحرف أو الكلمة (يظهر في البطاقة)
  final String label;

  /// النص الذي يُضاف لحقل الإدخال عند الضغط
  /// (قد يختلف عن label — مثلاً "أ" قد تُضاف كـ "أ")
  final String insertion;

  /// النص المنطوق بصوت (TTS) عند الضغط
  final String spoken;

  /// أيقونة الرمز (ستُستبدل بصورة لاحقاً)
  final IconData icon;

  /// وصف مختصر للحركة — يظهر كتلميح
  final String? hint;

  const SignItem({
    required this.label,
    required this.insertion,
    required this.spoken,
    required this.icon,
    this.hint,
  });
}

// ═══════════════════════════════════════════════════════════
//  تصنيف من رموز الإشارة
// ═══════════════════════════════════════════════════════════
class SignCategory {
  final String id;
  final String label;
  final String emoji;
  final List<SignItem> items;

  const SignCategory({
    required this.id,
    required this.label,
    required this.emoji,
    required this.items,
  });
}

// ═══════════════════════════════════════════════════════════
//  قاعدة البيانات الكاملة — 100 رمز
// ═══════════════════════════════════════════════════════════
const kSignCategories = <SignCategory>[
  // ═══════════════════════════════════════════════════════════
  //  1. الأبجدية العربية — 28 حرفاً
  // ═══════════════════════════════════════════════════════════
  SignCategory(
    id: 'alphabet',
    label: 'الحروف',
    emoji: '🔤',
    items: [
      SignItem(
        label: 'أ', insertion: 'أ', spoken: 'ألف',
        icon: Icons.looks_one_outlined,
        hint: 'الإصبع السبابة مرفوع للأعلى',
      ),
      SignItem(
        label: 'ب', insertion: 'ب', spoken: 'باء',
        icon: Icons.pan_tool_outlined,
        hint: 'كف مفتوح مستقيم للأمام',
      ),
      SignItem(
        label: 'ت', insertion: 'ت', spoken: 'تاء',
        icon: Icons.looks_two_outlined,
        hint: 'إصبعان مفتوحان',
      ),
      SignItem(
        label: 'ث', insertion: 'ث', spoken: 'ثاء',
        icon: Icons.sign_language_outlined,
        hint: 'ثلاثة أصابع مفتوحة',
      ),
      SignItem(
        label: 'ج', insertion: 'ج', spoken: 'جيم',
        icon: Icons.back_hand_outlined,
        hint: 'كف مقوّس للأمام',
      ),
      SignItem(
        label: 'ح', insertion: 'ح', spoken: 'حاء',
        icon: Icons.pan_tool_alt_outlined,
        hint: 'كف مفتوح بحركة دائرية',
      ),
      SignItem(
        label: 'خ', insertion: 'خ', spoken: 'خاء',
        icon: Icons.waving_hand_outlined,
        hint: 'كف مع نقطة للأعلى',
      ),
      SignItem(
        label: 'د', insertion: 'د', spoken: 'دال',
        icon: Icons.looks_3_outlined,
        hint: 'إصبع معكوف',
      ),
      SignItem(
        label: 'ذ', insertion: 'ذ', spoken: 'ذال',
        icon: Icons.looks_4_outlined,
        hint: 'إصبع مع نقطة',
      ),
      SignItem(
        label: 'ر', insertion: 'ر', spoken: 'راء',
        icon: Icons.looks_5_outlined,
        hint: 'إصبع مرفوع مستقيم',
      ),
      SignItem(
        label: 'ز', insertion: 'ز', spoken: 'زاي',
        icon: Icons.looks_6_outlined,
        hint: 'إصبع مرفوع بنقطة',
      ),
      SignItem(
        label: 'س', insertion: 'س', spoken: 'سين',
        icon: Icons.front_hand_outlined,
        hint: 'أصابع مجمّعة للأمام',
      ),
      SignItem(
        label: 'ش', insertion: 'ش', spoken: 'شين',
        icon: Icons.volunteer_activism_outlined,
        hint: 'أصابع مفتوحة وممدودة',
      ),
      SignItem(
        label: 'ص', insertion: 'ص', spoken: 'صاد',
        icon: Icons.fingerprint,
        hint: 'إصبعان متقاربان',
      ),
      SignItem(
        label: 'ض', insertion: 'ض', spoken: 'ضاد',
        icon: Icons.touch_app_outlined,
        hint: 'كف مقوّس لأسفل',
      ),
      SignItem(
        label: 'ط', insertion: 'ط', spoken: 'طاء',
        icon: Icons.handshake_outlined,
        hint: 'كف مغلق مسطّح',
      ),
      SignItem(
        label: 'ظ', insertion: 'ظ', spoken: 'ظاء',
        icon: Icons.handshake_outlined,
        hint: 'كف مغلق مسطّح بنقطة',
      ),
      SignItem(
        label: 'ع', insertion: 'ع', spoken: 'عين',
        icon: Icons.thumb_up_alt_outlined,
        hint: 'إصبعان مقوّسان',
      ),
      SignItem(
        label: 'غ', insertion: 'غ', spoken: 'غين',
        icon: Icons.thumb_up_outlined,
        hint: 'إصبعان مقوّسان لأعلى',
      ),
      SignItem(
        label: 'ف', insertion: 'ف', spoken: 'فاء',
        icon: Icons.ads_click_outlined,
        hint: 'إبهام وسبابة ملامسان',
      ),
      SignItem(
        label: 'ق', insertion: 'ق', spoken: 'قاف',
        icon: Icons.pinch_outlined,
        hint: 'إصبعان مرفوعان',
      ),
      SignItem(
        label: 'ك', insertion: 'ك', spoken: 'كاف',
        icon: Icons.pan_tool_outlined,
        hint: 'كف للأمام براحة داخلية',
      ),
      SignItem(
        label: 'ل', insertion: 'ل', spoken: 'لام',
        icon: Icons.looks_one,
        hint: 'إبهام وسبابة بشكل L',
      ),
      SignItem(
        label: 'م', insertion: 'م', spoken: 'ميم',
        icon: Icons.back_hand,
        hint: 'إبهام مغلق على الكف',
      ),
      SignItem(
        label: 'ن', insertion: 'ن', spoken: 'نون',
        icon: Icons.waving_hand,
        hint: 'إبهام مفتوح داخل الكف',
      ),
      SignItem(
        label: 'هـ', insertion: 'ه', spoken: 'هاء',
        icon: Icons.pan_tool,
        hint: 'كف مفتوح مواجه للأمام',
      ),
      SignItem(
        label: 'و', insertion: 'و', spoken: 'واو',
        icon: Icons.front_hand,
        hint: 'إبهام وسبابة متباعدان',
      ),
      SignItem(
        label: 'ي', insertion: 'ي', spoken: 'ياء',
        icon: Icons.sign_language,
        hint: 'خنصر مرفوع',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  //  2. الكلمات الأساسية — 32 كلمة
  // ═══════════════════════════════════════════════════════════
  SignCategory(
    id: 'basic',
    label: 'كلمات أساسية',
    emoji: '💬',
    items: [
      SignItem(
        label: 'أنا', insertion: 'أنا ', spoken: 'أنا',
        icon: Icons.person_outline,
        hint: 'أشِر بإصبعك لصدرك',
      ),
      SignItem(
        label: 'أنت', insertion: 'أنت ', spoken: 'أنت',
        icon: Icons.person_outlined,
        hint: 'أشِر بإصبعك للأمام',
      ),
      SignItem(
        label: 'نحن', insertion: 'نحن ', spoken: 'نحن',
        icon: Icons.groups_outlined,
        hint: 'أشِر بكفك في دائرة',
      ),
      SignItem(
        label: 'نعم', insertion: 'نعم ', spoken: 'نعم',
        icon: Icons.thumb_up_alt_outlined,
        hint: 'قبضة مغلقة مع إبهام للأعلى',
      ),
      SignItem(
        label: 'لا', insertion: 'لا ', spoken: 'لا',
        icon: Icons.thumb_down_alt_outlined,
        hint: 'قبضة مع إبهام للأسفل',
      ),
      SignItem(
        label: 'مرحباً', insertion: 'مرحباً ', spoken: 'مرحباً',
        icon: Icons.waving_hand,
        hint: 'لوّح بكفك',
      ),
      SignItem(
        label: 'شكراً', insertion: 'شكراً ', spoken: 'شكراً',
        icon: Icons.volunteer_activism_outlined,
        hint: 'المس ذقنك ثم أشر للأسفل',
      ),
      SignItem(
        label: 'من فضلك', insertion: 'من فضلك ', spoken: 'من فضلك',
        icon: Icons.favorite_border,
        hint: 'حرّك كفك بشكل دائري على الصدر',
      ),
      SignItem(
        label: 'عفواً', insertion: 'عفواً ', spoken: 'عفواً',
        icon: Icons.sentiment_satisfied_outlined,
        hint: 'ابتسم وأشِر بإبهامك',
      ),
      SignItem(
        label: 'صباح', insertion: 'صباح ', spoken: 'صباح',
        icon: Icons.wb_sunny_outlined,
        hint: 'كف يرتفع من الأسفل',
      ),
      SignItem(
        label: 'مساء', insertion: 'مساء ', spoken: 'مساء',
        icon: Icons.nights_stay_outlined,
        hint: 'كف ينزل من الأعلى',
      ),
      SignItem(
        label: 'ليل', insertion: 'ليل ', spoken: 'ليل',
        icon: Icons.dark_mode_outlined,
        hint: 'غلق الكف ببطء',
      ),
      SignItem(
        label: 'يوم', insertion: 'يوم ', spoken: 'يوم',
        icon: Icons.light_mode_outlined,
        hint: 'فتح الكف من الأسفل للأعلى',
      ),
      SignItem(
        label: 'ماء', insertion: 'ماء ', spoken: 'أريد ماء',
        icon: Icons.water_drop_outlined,
        hint: 'إصبعان ينزلان من الفم',
      ),
      SignItem(
        label: 'طعام', insertion: 'طعام ', spoken: 'أريد طعام',
        icon: Icons.restaurant_outlined,
        hint: 'إصبعان للأمام نحو الفم',
      ),
      SignItem(
        label: 'حمام', insertion: 'حمام ', spoken: 'أريد الحمام',
        icon: Icons.wc_outlined,
        hint: 'حركة هزّ اليد',
      ),
      SignItem(
        label: 'نوم', insertion: 'نوم ', spoken: 'أريد أن أنام',
        icon: Icons.bedtime_outlined,
        hint: 'انحنِ برأسك على كفك',
      ),
      SignItem(
        label: 'بيت', insertion: 'بيت ', spoken: 'البيت',
        icon: Icons.home_outlined,
        hint: 'سقف بإصبعيك',
      ),
      SignItem(
        label: 'مدرسة', insertion: 'مدرسة ', spoken: 'المدرسة',
        icon: Icons.school_outlined,
        hint: 'كتاب مفتوح بكفيك',
      ),
      SignItem(
        label: 'معلم', insertion: 'معلم ', spoken: 'المعلم',
        icon: Icons.person_4_outlined,
        hint: 'شخص يُعلّم',
      ),
      SignItem(
        label: 'طالب', insertion: 'طالب ', spoken: 'الطالب',
        icon: Icons.school_outlined,
        hint: 'شخص يتعلم',
      ),
      SignItem(
        label: 'صديق', insertion: 'صديق ', spoken: 'صديق',
        icon: Icons.people_outline,
        hint: 'إصبعان متشابكان',
      ),
      SignItem(
        label: 'أمي', insertion: 'أمي ', spoken: 'أمي',
        icon: Icons.family_restroom_outlined,
        hint: 'أشِر لوجه أمّك',
      ),
      SignItem(
        label: 'أبي', insertion: 'أبي ', spoken: 'أبي',
        icon: Icons.family_restroom,
        hint: 'أشِر لوجه أبيك',
      ),
      SignItem(
        label: 'أخ', insertion: 'أخ ', spoken: 'أخي',
        icon: Icons.person_outline,
        hint: 'شخص بنفس الجيل',
      ),
      SignItem(
        label: 'أخت', insertion: 'أخت ', spoken: 'أختي',
        icon: Icons.person_2_outlined,
        hint: 'أنثى بنفس الجيل',
      ),
      SignItem(
        label: 'كتاب', insertion: 'كتاب ', spoken: 'كتاب',
        icon: Icons.menu_book_outlined,
        hint: 'كتاب بكفيك',
      ),
      SignItem(
        label: 'قلم', insertion: 'قلم ', spoken: 'قلم',
        icon: Icons.edit_outlined,
        hint: 'إصبع كأنه يكتب',
      ),
      SignItem(
        label: 'سيارة', insertion: 'سيارة ', spoken: 'سيارة',
        icon: Icons.directions_car_outlined,
        hint: 'كفان كعجلة قيادة',
      ),
      SignItem(
        label: 'هاتف', insertion: 'هاتف ', spoken: 'هاتف',
        icon: Icons.phone_outlined,
        hint: 'إبهام وخنصر كالهاتف',
      ),
      SignItem(
        label: 'وقت', insertion: 'وقت ', spoken: 'وقت',
        icon: Icons.schedule_outlined,
        hint: 'أشِر لمعصمك',
      ),
      SignItem(
        label: 'كبير', insertion: 'كبير ', spoken: 'كبير',
        icon: Icons.arrow_upward_outlined,
        hint: 'كفان يتباعدان',
      ),
      SignItem(
        label: 'صغير', insertion: 'صغير ', spoken: 'صغير',
        icon: Icons.arrow_downward_outlined,
        hint: 'كفان يتقاربان',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  //  3. المشاعر والحاجات — 20 كلمة
  // ═══════════════════════════════════════════════════════════
  SignCategory(
    id: 'feelings',
    label: 'مشاعر وحاجات',
    emoji: '💚',
    items: [
      SignItem(
        label: 'سعيد', insertion: 'سعيد ', spoken: 'أنا سعيد',
        icon: Icons.sentiment_very_satisfied_outlined,
        hint: 'ابتسم وأشِر للفم',
      ),
      SignItem(
        label: 'حزين', insertion: 'حزين ', spoken: 'أنا حزين',
        icon: Icons.sentiment_very_dissatisfied_outlined,
        hint: 'أشِر من العين للأسفل',
      ),
      SignItem(
        label: 'غاضب', insertion: 'غاضب ', spoken: 'أنا غاضب',
        icon: Icons.mood_bad_outlined,
        hint: 'حركة انفعالية بالكف',
      ),
      SignItem(
        label: 'خائف', insertion: 'خائف ', spoken: 'أنا خائف',
        icon: Icons.psychology_alt_outlined,
        hint: 'كفان يرتجفان على الصدر',
      ),
      SignItem(
        label: 'متعب', insertion: 'متعب ', spoken: 'أنا متعب',
        icon: Icons.battery_0_bar_outlined,
        hint: 'كف يهبط ببطء',
      ),
      SignItem(
        label: 'متحمس', insertion: 'متحمس ', spoken: 'أنا متحمس',
        icon: Icons.emoji_emotions_outlined,
        hint: 'كفان يرتفعان بسرعة',
      ),
      SignItem(
        label: 'أحبك', insertion: 'أحبك ', spoken: 'أحبك',
        icon: Icons.favorite_outline,
        hint: 'تشكيل كلمة بحب باليد',
      ),
      SignItem(
        label: 'مريض', insertion: 'مريض ', spoken: 'أنا مريض',
        icon: Icons.sick_outlined,
        hint: 'كف على البطن أو الجبهة',
      ),
      SignItem(
        label: 'ألم', insertion: 'ألم ', spoken: 'أشعر بألم',
        icon: Icons.healing_outlined,
        hint: 'أشِر لمكان الألم',
      ),
      SignItem(
        label: 'فرحان', insertion: 'فرحان ', spoken: 'أنا فرحان',
        icon: Icons.celebration_outlined,
        hint: 'تصفيق خفيف',
      ),
      SignItem(
        label: 'جوعان', insertion: 'جوعان ', spoken: 'أنا جوعان',
        icon: Icons.restaurant_menu_outlined,
        hint: 'كف على المعدة',
      ),
      SignItem(
        label: 'عطشان', insertion: 'عطشان ', spoken: 'أنا عطشان',
        icon: Icons.local_drink_outlined,
        hint: 'كف على الحلق',
      ),
      SignItem(
        label: 'بارد', insertion: 'بارد ', spoken: 'أشعر بالبرد',
        icon: Icons.ac_unit_outlined,
        hint: 'كفان على الكتفين',
      ),
      SignItem(
        label: 'حار', insertion: 'حار ', spoken: 'أشعر بالحرارة',
        icon: Icons.local_fire_department_outlined,
        hint: 'كف يمسح الجبهة',
      ),
      SignItem(
        label: 'مرتاح', insertion: 'مرتاح ', spoken: 'أنا مرتاح',
        icon: Icons.spa_outlined,
        hint: 'كفان مفتوحان بهدوء',
      ),
      SignItem(
        label: 'أريد', insertion: 'أريد ', spoken: 'أريد',
        icon: Icons.pan_tool_alt_outlined,
        hint: 'كفان مقوّسان للصدر',
      ),
      SignItem(
        label: 'لا أريد', insertion: 'لا أريد ', spoken: 'لا أريد',
        icon: Icons.do_not_touch_outlined,
        hint: 'كف يدفع للأمام',
      ),
      SignItem(
        label: 'أحتاج', insertion: 'أحتاج ', spoken: 'أحتاج',
        icon: Icons.volunteer_activism_outlined,
        hint: 'كف مفتوح للصدر',
      ),
      SignItem(
        label: 'مساعدة', insertion: 'مساعدة ', spoken: 'أحتاج مساعدة',
        icon: Icons.support_outlined,
        hint: 'كف تحت كف',
      ),
      SignItem(
        label: 'عناق', insertion: 'عناق ', spoken: 'أريد عناق',
        icon: Icons.favorite,
        hint: 'ذراعان مفتوحتان',
      ),
    ],
  ),

  // ═══════════════════════════════════════════════════════════
  //  4. الجمل الشائعة — 20 جملة
  // ═══════════════════════════════════════════════════════════
  SignCategory(
    id: 'phrases',
    label: 'جمل شائعة',
    emoji: '💭',
    items: [
      SignItem(
        label: 'كيف حالك؟', insertion: 'كيف حالك؟ ', spoken: 'كيف حالك؟',
        icon: Icons.sentiment_satisfied_alt_outlined,
        hint: 'كف مفتوح للأمام مع حركة',
      ),
      SignItem(
        label: 'بخير', insertion: 'أنا بخير ', spoken: 'أنا بخير',
        icon: Icons.thumb_up_outlined,
        hint: 'إبهام للأعلى',
      ),
      SignItem(
        label: 'ما اسمك؟', insertion: 'ما اسمك؟ ', spoken: 'ما اسمك؟',
        icon: Icons.badge_outlined,
        hint: 'أشِر للآخر ثم للفم',
      ),
      SignItem(
        label: 'اسمي...', insertion: 'اسمي ', spoken: 'اسمي',
        icon: Icons.drive_file_rename_outline,
        hint: 'أشِر لصدرك',
      ),
      SignItem(
        label: 'كم عمرك؟', insertion: 'كم عمرك؟ ', spoken: 'كم عمرك؟',
        icon: Icons.cake_outlined,
        hint: 'أشِر للآخر ثم ليدك',
      ),
      SignItem(
        label: 'أين...؟', insertion: 'أين ', spoken: 'أين',
        icon: Icons.help_outline,
        hint: 'كف مفتوح يتحرك',
      ),
      SignItem(
        label: 'متى...؟', insertion: 'متى ', spoken: 'متى',
        icon: Icons.schedule_outlined,
        hint: 'أشِر للمعصم',
      ),
      SignItem(
        label: 'لماذا؟', insertion: 'لماذا؟ ', spoken: 'لماذا؟',
        icon: Icons.question_mark_outlined,
        hint: 'إصبع على الجبهة',
      ),
      SignItem(
        label: 'مع السلامة', insertion: 'مع السلامة ', spoken: 'مع السلامة',
        icon: Icons.waving_hand_outlined,
        hint: 'لوّح بكفك',
      ),
      SignItem(
        label: 'إلى اللقاء', insertion: 'إلى اللقاء ', spoken: 'إلى اللقاء',
        icon: Icons.waving_hand,
        hint: 'لوّح مع ابتسامة',
      ),
      SignItem(
        label: 'تفضل', insertion: 'تفضل ', spoken: 'تفضل',
        icon: Icons.pan_tool_outlined,
        hint: 'كف مفتوح للأمام',
      ),
      SignItem(
        label: 'انتظر', insertion: 'انتظر ', spoken: 'انتظر',
        icon: Icons.pause_circle_outline,
        hint: 'كف واحد مرفوع',
      ),
      SignItem(
        label: 'اذهب', insertion: 'اذهب ', spoken: 'اذهب',
        icon: Icons.directions_walk_outlined,
        hint: 'كف يدفع للأمام',
      ),
      SignItem(
        label: 'تعال', insertion: 'تعال ', spoken: 'تعال',
        icon: Icons.waving_hand_outlined,
        hint: 'إصبعان ينحنيان نحوك',
      ),
      SignItem(
        label: 'اجلس', insertion: 'اجلس ', spoken: 'اجلس',
        icon: Icons.chair_outlined,
        hint: 'إصبعان للأسفل',
      ),
      SignItem(
        label: 'قف', insertion: 'قف ', spoken: 'قف',
        icon: Icons.accessibility_new_outlined,
        hint: 'كف للأعلى',
      ),
      SignItem(
        label: 'اسمع', insertion: 'اسمع ', spoken: 'اسمع',
        icon: Icons.hearing_outlined,
        hint: 'أشِر لأذنك',
      ),
      SignItem(
        label: 'انظر', insertion: 'انظر ', spoken: 'انظر',
        icon: Icons.visibility_outlined,
        hint: 'إصبعان لعينيك',
      ),
      SignItem(
        label: 'افهمت؟', insertion: 'هل افهمت؟ ', spoken: 'هل افهمت؟',
        icon: Icons.psychology_alt_outlined,
        hint: 'أشِر لجبهتك',
      ),
      SignItem(
        label: 'فهمت', insertion: 'فهمت ', spoken: 'فهمت',
        icon: Icons.lightbulb_outline,
        hint: 'إصبع على الجبهة',
      ),
    ],
  ),
];

// ═══════════════════════════════════════════════════════════
//  إجمالي عدد الرموز
// ═══════════════════════════════════════════════════════════
int get kTotalSigns =>
    kSignCategories.fold(0, (sum, cat) => sum + cat.items.length);