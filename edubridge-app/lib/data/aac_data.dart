// lib/data/aac_data.dart
// ═══════════════════════════════════════════════════════════
//  قاعدة بيانات التواصل بالصور (AAC)
//  - يُستخدم من: شريط المحادثة + الأوامر الصوتية
//  - البنية تسمح بترقية كل عنصر لصورة حقيقية لاحقاً
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../app_icons.dart';

// ═══════════════════════════════════════════════════════════
//  عنصر AAC واحد
// ═══════════════════════════════════════════════════════════
class AacItem {
  final IconData icon;
  final String label;      // النص المعروض
  final String spoken;     // النص المنطوق
  final String? imagePath; // للترقية المستقبلية

  const AacItem({
    required this.icon,
    required this.label,
    required this.spoken,
    this.imagePath,
  });
}

// ═══════════════════════════════════════════════════════════
//  قاعدة البيانات الكاملة — 5 تصنيفات
// ═══════════════════════════════════════════════════════════
const kAacCategories = <String, List<AacItem>>{
  'أساسية': [
    AacItem(icon: AppIcons.speech, label: 'مرحباً', spoken: 'مرحبا'),
    AacItem(icon: AppIcons.profile, label: 'أنا', spoken: 'أنا'),
    AacItem(icon: AppIcons.check, label: 'نعم', spoken: 'نعم'),
    AacItem(icon: AppIcons.close, label: 'لا', spoken: 'لا'),
    AacItem(icon: AppIcons.starFilled, label: 'شكراً', spoken: 'شكرا'),
    AacItem(icon: AppIcons.users, label: 'من فضلك', spoken: 'من فضلك'),
    AacItem(
      icon: Icons.sentiment_satisfied,
      label: 'سعيد',
      spoken: 'أنا سعيد',
    ),
    AacItem(
      icon: Icons.sentiment_dissatisfied,
      label: 'حزين',
      spoken: 'أنا حزين',
    ),
  ],
  'احتياجات': [
    AacItem(
      icon: Icons.water_drop_outlined,
      label: 'ماء',
      spoken: 'أريد ماء',
    ),
    AacItem(
      icon: Icons.restaurant_outlined,
      label: 'طعام',
      spoken: 'أريد طعام',
    ),
    AacItem(icon: Icons.wc_outlined, label: 'حمام', spoken: 'أريد الحمام'),
    AacItem(
      icon: Icons.bedtime_outlined,
      label: 'نوم',
      spoken: 'أريد أن أنام',
    ),
    AacItem(icon: Icons.sick_outlined, label: 'مرض', spoken: 'أنا مريض'),
    AacItem(
      icon: Icons.ac_unit_outlined,
      label: 'بارد',
      spoken: 'أشعر بالبرد',
    ),
    AacItem(
      icon: Icons.wb_sunny_outlined,
      label: 'حار',
      spoken: 'أشعر بالحرارة',
    ),
    AacItem(
      icon: Icons.volunteer_activism_outlined,
      label: 'عناق',
      spoken: 'أريد عناق',
    ),
  ],
  'مشاعر': [
    AacItem(icon: Icons.mood_bad_outlined, label: 'غاضب', spoken: 'أنا غاضب'),
    AacItem(
      icon: Icons.psychology_outlined,
      label: 'خائف',
      spoken: 'أنا خائف',
    ),
    AacItem(
      icon: Icons.help_outline,
      label: 'مرتبك',
      spoken: 'أنا مرتبك',
    ),
    AacItem(
      icon: Icons.favorite_outline,
      label: 'محبوب',
      spoken: 'أشعر بالحب',
    ),
    AacItem(
      icon: Icons.battery_0_bar_outlined,
      label: 'متعب',
      spoken: 'أنا متعب',
    ),
    AacItem(
      icon: Icons.emoji_emotions_outlined,
      label: 'متحمس',
      spoken: 'أنا متحمس',
    ),
    AacItem(
      icon: Icons.psychology_alt_outlined,
      label: 'أفكر',
      spoken: 'أنا أفكر',
    ),
    AacItem(icon: Icons.spa_outlined, label: 'مرتاح', spoken: 'أنا مرتاح'),
  ],
  'أنشطة': [
    AacItem(
      icon: Icons.videogame_asset_outlined,
      label: 'ألعب',
      spoken: 'أريد أن ألعب',
    ),
    AacItem(
      icon: Icons.menu_book_outlined,
      label: 'أقرأ',
      spoken: 'أريد أن أقرأ',
    ),
    AacItem(
      icon: Icons.palette_outlined,
      label: 'أرسم',
      spoken: 'أريد أن أرسم',
    ),
    AacItem(
      icon: Icons.music_note_outlined,
      label: 'أسمع',
      spoken: 'أريد سماع موسيقى',
    ),
    AacItem(
      icon: Icons.movie_outlined,
      label: 'أشاهد',
      spoken: 'أريد مشاهدة',
    ),
    AacItem(
      icon: Icons.directions_run_outlined,
      label: 'أتحرك',
      spoken: 'أريد أن أتحرك',
    ),
    AacItem(
      icon: Icons.weekend_outlined,
      label: 'أرتاح',
      spoken: 'أريد الراحة',
    ),
    AacItem(
      icon: Icons.edit_note_outlined,
      label: 'أدرس',
      spoken: 'أريد أن أدرس',
    ),
  ],
  'أشخاص': [
    AacItem(icon: Icons.woman_outlined, label: 'أمي', spoken: 'أريد أمي'),
    AacItem(icon: Icons.man_outlined, label: 'أبي', spoken: 'أريد أبي'),
    AacItem(
      icon: Icons.child_friendly_outlined,
      label: 'أخي',
      spoken: 'أريد أخي',
    ),
    AacItem(icon: Icons.girl_outlined, label: 'أختي', spoken: 'أريد أختي'),
    AacItem(icon: AppIcons.teacher, label: 'معلمي', spoken: 'أريد معلمي'),
    AacItem(
      icon: Icons.medical_services_outlined,
      label: 'الطبيب',
      spoken: 'أريد الطبيب',
    ),
    AacItem(
      icon: AppIcons.specialist,
      label: 'المختص',
      spoken: 'أريد المختص',
    ),
    AacItem(icon: AppIcons.users, label: 'أصدقائي', spoken: 'أريد أصدقائي'),
  ],
};