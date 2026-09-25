// lib/screens/aac_communication_screen.dart
// AAC — التواصل البديل بالصور (لمن لا يستطيع الكلام)
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
part 'aac_communication_view.dart';

class AACCommunicationScreen extends StatefulWidget {
  final String childName;
  const AACCommunicationScreen({super.key, required this.childName});

  @override
  State<AACCommunicationScreen> createState() =>
      _AACCommunicationScreenState();
}

class _AACCommunicationScreenState extends State<AACCommunicationScreen> {
  final List<String> _sentence = [];
  String _selectedCategory = 'أساسية';

  static const _categories = {
    'أساسية': [
      (AppIcons.speech, 'مرحباً', 'مرحبا'),
      (AppIcons.profile, 'أنا', 'أنا'),
      (AppIcons.check, 'نعم', 'نعم'),
      (AppIcons.close, 'لا', 'لا'),
      (AppIcons.starFilled, 'شكراً', 'شكرا'),
      (AppIcons.users, 'من فضلك', 'من فضلك'),
      (Icons.sentiment_satisfied, 'سعيد', 'أنا سعيد'),
      (Icons.sentiment_dissatisfied, 'حزين', 'أنا حزين'),
    ],
    'احتياجات': [
      (Icons.water_drop_outlined, 'ماء', 'أريد ماء'),
      (Icons.restaurant_outlined, 'طعام', 'أريد طعام'),
      (Icons.wc_outlined, 'حمام', 'أريد الحمام'),
      (Icons.bedtime_outlined, 'نوم', 'أريد أن أنام'),
      (Icons.sick_outlined, 'مرض', 'أنا مريض'),
      (Icons.ac_unit_outlined, 'بارد', 'أشعر بالبرد'),
      (Icons.wb_sunny_outlined, 'حار', 'أشعر بالحرارة'),
      (Icons.volunteer_activism_outlined, 'عناق', 'أريد عناق'),
    ],
    'مشاعر': [
      (Icons.mood_bad_outlined, 'غاضب', 'أنا غاضب'),
      (Icons.psychology_outlined, 'خائف', 'أنا خائف'),
      (Icons.help_outline, 'مرتبك', 'أنا مرتبك'),
      (Icons.favorite_outline, 'محبوب', 'أشعر بالحب'),
      (Icons.battery_0_bar_outlined, 'متعب', 'أنا متعب'),
      (Icons.emoji_emotions_outlined, 'متحمس', 'أنا متحمس'),
      (Icons.psychology_alt_outlined, 'أفكر', 'أنا أفكر'),
      (Icons.spa_outlined, 'مرتاح', 'أنا مرتاح'),
    ],
    'أنشطة': [
      (Icons.videogame_asset_outlined, 'ألعب', 'أريد أن ألعب'),
      (Icons.menu_book_outlined, 'أقرأ', 'أريد أن أقرأ'),
      (Icons.palette_outlined, 'أرسم', 'أريد أن أرسم'),
      (Icons.music_note_outlined, 'أسمع', 'أريد سماع موسيقى'),
      (Icons.movie_outlined, 'أشاهد', 'أريد مشاهدة'),
      (Icons.directions_run_outlined, 'ألعب', 'أريد أن أتحرك'),
      (Icons.weekend_outlined, 'أرتاح', 'أريد الراحة'),
      (Icons.edit_note_outlined, 'أدرس', 'أريد أن أدرس'),
    ],
    'أشخاص': [
      (Icons.woman_outlined, 'أمي', 'أريد أمي'),
      (Icons.man_outlined, 'أبي', 'أريد أبي'),
      (Icons.child_friendly_outlined, 'أخي', 'أريد أخي'),
      (Icons.girl_outlined, 'أختي', 'أريد أختي'),
      (AppIcons.teacher, 'معلمي', 'أريد معلمي'),
      (Icons.medical_services_outlined, 'الطبيب', 'أريد الطبيب'),
      (AppIcons.specialist, 'المختص', 'أريد المختص'),
      (AppIcons.users, 'أصدقائي', 'أريد أصدقائي'),
    ],
  };

  void _addToSentence(String text, String spoken) {
    AdaptiveHelper.hapticFeedback();
    TtsService.instance.speakLine(spoken);
    setState(() => _sentence.add(text));
  }

  void _removeLast() {
    if (_sentence.isEmpty) return;
    AdaptiveHelper.hapticFeedback();
    setState(() => _sentence.removeLast());
  }

  void _clear() {
    AdaptiveHelper.hapticFeedback();
    setState(() => _sentence.clear());
  }

  void _speakAll() {
    if (_sentence.isEmpty) return;
    AdaptiveHelper.hapticFeedback();
    TtsService.instance.speakLine(_sentence.join(' '));
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}

class _AACChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AACChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
      child: Container(
        decoration: BoxDecoration(
          color: AdaptiveHelper.cardColor(context),
          borderRadius: BorderRadius.circular(AdaptiveHelper.cardRadius),
          border: Border.all(
            color: AdaptiveHelper.accentColor(context).withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AdaptiveHelper.iconSize * 1.5,
              color: AdaptiveHelper.accentColor(context),
            ),
            SizedBox(height: AdaptiveHelper.spacing / 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize,
                  fontWeight: FontWeight.bold,
                  color: AdaptiveHelper.textColor(context),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}