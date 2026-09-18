// lib/screens/aac_communication_screen.dart
// AAC — التواصل البديل بالصور (لمن لا يستطيع الكلام)
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
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
      ('👋', 'مرحباً', 'مرحبا'),
      ('🙋', 'أنا', 'أنا'),
      ('✅', 'نعم', 'نعم'),
      ('❌', 'لا', 'لا'),
      ('🙏', 'شكراً', 'شكرا'),
      ('🙋‍♂️', 'من فضلك', 'من فضلك'),
      ('😊', 'سعيد', 'أنا سعيد'),
      ('😢', 'حزين', 'أنا حزين'),
    ],
    'احتياجات': [
      ('💧', 'ماء', 'أريد ماء'),
      ('🍎', 'طعام', 'أريد طعام'),
      ('🚽', 'حمام', 'أريد الحمام'),
      ('😴', 'نوم', 'أريد أن أنام'),
      ('🤒', 'مرض', 'أنا مريض'),
      ('🥶', 'بارد', 'أشعر بالبرد'),
      ('🥵', 'حار', 'أشعر بالحرارة'),
      ('🤗', 'عناق', 'أريد عناق'),
    ],
    'مشاعر': [
      ('😡', 'غاضب', 'أنا غاضب'),
      ('😨', 'خائف', 'أنا خائف'),
      ('😕', 'مرتبك', 'أنا مرتبك'),
      ('🥰', 'محبوب', 'أشعر بالحب'),
      ('😔', 'متعب', 'أنا متعب'),
      ('😃', 'متحمس', 'أنا متحمس'),
      ('🤔', 'أفكر', 'أنا أفكر'),
      ('😌', 'مرتاح', 'أنا مرتاح'),
    ],
    'أنشطة': [
      ('🎮', 'ألعب', 'أريد أن ألعب'),
      ('📚', 'أقرأ', 'أريد أن أقرأ'),
      ('🎨', 'أرسم', 'أريد أن أرسم'),
      ('🎵', 'أسمع', 'أريد سماع موسيقى'),
      ('🎬', 'أشاهد', 'أريد مشاهدة'),
      ('🏃', 'ألعب', 'أريد أن أتحرك'),
      ('🛏️', 'أرتاح', 'أريد الراحة'),
      ('📝', 'أدرس', 'أريد أن أدرس'),
    ],
    'أشخاص': [
      ('👩', 'أمي', 'أريد أمي'),
      ('👨', 'أبي', 'أريد أبي'),
      ('👶', 'أخي', 'أريد أخي'),
      ('👧', 'أختي', 'أريد أختي'),
      ('👨‍🏫', 'معلمي', 'أريد معلمي'),
      ('🧑‍⚕️', 'الطبيب', 'أريد الطبيب'),
      ('🧩', 'المختص', 'أريد المختص'),
      ('👥', 'أصدقائي', 'أريد أصدقائي'),
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
      appBar: JisrAppBar(title: '🗣️ تواصل بالصور'),
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
                        icon: const Icon(Icons.volume_up),
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
                      icon: const Icon(Icons.backspace, color: Colors.white),
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
                      icon: const Icon(Icons.clear_all, color: Colors.white),
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
                final (emoji, label, spoken) = items[i];
                return _AACChip(
                  emoji: emoji,
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
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _AACChip({
    required this.emoji,
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
            Text(emoji, style: TextStyle(fontSize: AdaptiveHelper.iconSize * 1.5)),
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