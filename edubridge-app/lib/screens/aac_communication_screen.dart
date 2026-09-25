// lib/screens/aac_communication_screen.dart
// AAC — التواصل البديل بالصور (لمن لا يستطيع الكلام)
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';

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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final items = _categories[_selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: AdaptiveHelper.surfaceColor(context),
      appBar: JisrAppBar(title: 'تواصل بالصور'),
      body: Column(
        children: [
          // ─── الجملة الحالية ───
          Container(
            margin: EdgeInsets.all(AdaptiveHelper.spacing),
            padding: EdgeInsets.all(AdaptiveHelper.spacing),
            decoration: BoxDecoration(
              color: AdaptiveHelper.cardColor(context),
              borderRadius:
                  BorderRadius.circular(AdaptiveHelper.cardRadius),
              border: Border.all(
                color: AdaptiveHelper.accentColor(context),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: _sentence.isEmpty
                      ? Center(
                          child: Text(
                            'اضغط على الصور لبناء جملة',
                            style: TextStyle(
                              fontSize: AdaptiveHelper.bodyFontSize - 2,
                              color: c.muted,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sentence.map((word) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AdaptiveHelper.accentColor(context)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word,
                                style: TextStyle(
                                  fontSize: AdaptiveHelper.bodyFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: AdaptiveHelper.accentColor(context),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                SizedBox(height: AdaptiveHelper.spacing),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, AdaptiveHelper.buttonHeight),
                        ),
                        onPressed: _speakAll,
                        icon: const Icon(AppIcons.volumeUp),
                        label: Text(
                          'قلها',
                          style:
                              TextStyle(fontSize: AdaptiveHelper.bodyFontSize),
                        ),
                      ),
                    ),
                    SizedBox(width: AdaptiveHelper.spacing / 2),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        minimumSize: Size(
                          AdaptiveHelper.buttonHeight,
                          AdaptiveHelper.buttonHeight,
                        ),
                      ),
                      onPressed: _removeLast,
                      icon: const Icon(Icons.backspace_outlined,
                          color: Colors.white),
                    ),
                    SizedBox(width: AdaptiveHelper.spacing / 2),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.red,
                        minimumSize: Size(
                          AdaptiveHelper.buttonHeight,
                          AdaptiveHelper.buttonHeight,
                        ),
                      ),
                      onPressed: _clear,
                      icon: const Icon(AppIcons.delete, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── التصنيفات ───
          SizedBox(
            height: AdaptiveHelper.buttonHeight * 0.9,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveHelper.spacing,
              ),
              children: _categories.keys.map((cat) {
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(
                      right: AdaptiveHelper.spacing / 2),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: AdaptiveHelper.bodyFontSize - 2,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : c.body,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AdaptiveHelper.accentColor(context),
                    onSelected: (v) {
                      if (v) setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── شبكة الصور ───
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(AdaptiveHelper.spacing),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 4 : 2,
                mainAxisSpacing: AdaptiveHelper.spacing,
                crossAxisSpacing: AdaptiveHelper.spacing,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final (icon, label, spoken) = items[i];
                return _AACChip(
                  icon: icon,
                  label: label,
                  onTap: () => _addToSentence(label, spoken),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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