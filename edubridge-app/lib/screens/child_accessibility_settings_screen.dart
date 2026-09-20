// screens/child_accessibility_settings_screen.dart
// إعدادات التكييف لطفل واحد — مقسّمة حسب فئة الإعاقة
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';
import '../widgets/disability_catalog.dart';

class ChildAccessibilitySettingsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final String? disabilityTypeHint;
  final bool deactivateOnExit;

  const ChildAccessibilitySettingsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.disabilityTypeHint,
    this.deactivateOnExit = true,
  });

  @override
  State<ChildAccessibilitySettingsScreen> createState() =>
      _ChildAccessibilitySettingsScreenState();
}

class _ChildAccessibilitySettingsScreenState
    extends State<ChildAccessibilitySettingsScreen> {
  final _customNameCtrl = TextEditingController();
  String? _selectedDisability;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityTypeHint,
    );
    _selectedDisability = widget.disabilityTypeHint;
    _customNameCtrl.text = widget.disabilityTypeHint ?? '';
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    if (widget.deactivateOnExit) {
      AccessibilityService.instance.setActiveChild(null);
    }
    super.dispose();
  }

  AccessibilityProfile get _p =>
      AccessibilityService.instance.profileForChild(widget.childId) ??
      const AccessibilityProfile(type: DisabilityType.none);

  Future<void> _set(AccessibilityProfile next) =>
      AccessibilityService.instance.updateForChild(widget.childId, next);

  Future<void> _openDisabilityPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DisabilityPickerSheet(
        currentValue: _selectedDisability,
      ),
    );

    if (result == null) return;

    setState(() => _selectedDisability = result);

    if (result == 'أخرى') return;

    final type = disabilityTypeForCategory(result);
    await AccessibilityService.instance.applyRecommendedForChild(
      widget.childId,
      type,
      customName: type == DisabilityType.other ? result : null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تم تطبيق التكييف الموصى به لـ "$result"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _applyCustom() async {
    final name = _customNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى كتابة اسم الإعاقة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    await AccessibilityService.instance.applyRecommendedForChild(
      widget.childId,
      DisabilityType.other,
      customName: name,
    );
    if (!mounted) return;
    setState(() => _selectedDisability = name);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ الإعاقة المخصّصة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'إعدادات ${widget.childName}'),
      body: ValueListenableBuilder<AccessibilityProfile>(
        valueListenable: AccessibilityService.instance.profile,
        builder: (context, _, __) {
          final p = _p;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══ رأس توضيحي ═══
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_care,
                        color: AppColors.tealDeep, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'هذه الإعدادات تُطبَّق على ${widget.childName} فقط.',
                        style: TextStyle(color: c.onTint, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═══ نوع الإعاقة ═══
              _sectionTitle('نوع الإعاقة', c),
              const SizedBox(height: 8),
              _buildDisabilitySelector(c),

              if (_selectedDisability == 'أخرى') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.tintOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note,
                              color: AppColors.orangeDeep, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'اكتب اسم الإعاقة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: c.onTint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customNameCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'مثال: اضطراب المعالجة السمعية',
                          filled: true,
                          fillColor: c.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('حفظ الإعاقة'),
                          onPressed: _applyCustom,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════
              //  👁️ ميزات الإعاقات البصرية
              // ═══════════════════════════════════════════════
              _featureSection(
                'ميزات الإعاقات البصرية',
                '👁️',
                AppColors.navy,
                c,
                [
                  _sw('تحسين لقارئ الشاشة',
                      'دعم NVDA و JAWS و VoiceOver',
                      p.screenReaderOptimized,
                      (v) => _set(p.copyWith(screenReaderOptimized: v))),
                  _sw('وصف تفصيلي للصور',
                      'وصف صوتي لكل صورة (Alt Text)',
                      p.detailedAltText,
                      (v) => _set(p.copyWith(detailedAltText: v))),
                  _sw('وصف صوتي للفيديوهات',
                      'صوت يشرح ما يحدث في الفيديو',
                      p.audioDescriptions,
                      (v) => _set(p.copyWith(audioDescriptions: v))),
                  _sw('اختصارات لوحة المفاتيح',
                      'Alt+1, Alt+2... للتنقل السريع',
                      p.keyboardShortcuts,
                      (v) => _set(p.copyWith(keyboardShortcuts: v))),
                  _sw('واجهة نصية فقط',
                      'إزالة كل الرسومات غير الضرورية',
                      p.textOnlyMode,
                      (v) => _set(p.copyWith(textOnlyMode: v))),
                  _sw('مؤشر فأرة كبير',
                      'مؤشر واضح ومكبّر',
                      p.largeMouseCursor,
                      (v) => _set(p.copyWith(largeMouseCursor: v))),
                ],
              ),

              // ═══════════════════════════════════════════════
              //  👂 ميزات الإعاقات السمعية
              // ═══════════════════════════════════════════════
              _featureSection(
                'ميزات الإعاقات السمعية',
                '👂',
                AppColors.pink,
                c,
                [
                  _sw('ترجمة نصية للفيديوهات',
                      'Captions لكل محتوى مرئي',
                      p.videoCaptions,
                      (v) => _set(p.copyWith(videoCaptions: v))),
                  _sw('وصف الأصوات البيئية',
                      'مثل [موسيقى] [باب يطرق]',
                      p.soundDescriptions,
                      (v) => _set(p.copyWith(soundDescriptions: v))),
                  _sw('ترجمة لغة الإشارة',
                      'عرض مترجم لغة الإشارة',
                      p.signLanguageTranslation,
                      (v) => _set(p.copyWith(signLanguageTranslation: v))),
                  _sw('إشعارات بصرية',
                      'بدل الأصوات — إشعارات مرئية',
                      p.visualNotifications,
                      (v) => _set(p.copyWith(visualNotifications: v))),
                  _sw('تنبيهات بوميض',
                      'وميض ملوّن للإشعارات المهمة',
                      p.flashAlerts,
                      (v) => _set(p.copyWith(flashAlerts: v))),
                  _sw('اهتزاز قوي',
                      'للتنبيهات والنجاح',
                      p.vibrationAlerts,
                      (v) => _set(p.copyWith(vibrationAlerts: v))),
                ],
              ),

              // ═══════════════════════════════════════════════
              //  🗣️ ميزات اضطرابات النطق واللغة
              // ═══════════════════════════════════════════════
              _featureSection(
                'ميزات اضطرابات النطق واللغة',
                '🗣️',
                AppColors.orangeDeep,
                c,
                [
                  _sw('تحويل الكلام إلى نص',
                      'Speech-to-Text للكتابة',
                      p.voiceToText,
                      (v) => _set(p.copyWith(voiceToText: v))),
                  _sw('اقتراح كلمات',
                      'Word Prediction أثناء الكتابة',
                      p.wordPrediction,
                      (v) => _set(p.copyWith(wordPrediction: v))),
                  _sw('تواصل بالصور',
                      'AAC — اختيار صور بدل الكلام',
                      p.pictureCommunication,
                      (v) => _set(p.copyWith(pictureCommunication: v))),
                  _sw('جمل قصيرة جداً',
                      '8-10 كلمات كحد أقصى',
                      p.shortSentences,
                      (v) => _set(p.copyWith(shortSentences: v))),
                  _sw('وقت غير محدود',
                      'بدون ضغط زمني أو مؤقّتات',
                      p.unlimitedTime,
                      (v) => _set(p.copyWith(unlimitedTime: v))),
                ],
              ),

              // ═══════════════════════════════════════════════
              //  🦽 ميزات الإعاقات الحركية والعصبية
              // ═══════════════════════════════════════════════
              _featureSection(
                'ميزات الإعاقات الحركية والعصبية',
                '🦽',
                AppColors.tealDeep,
                c,
                [
                  _sw('تحكم بلوحة المفاتيح فقط',
                      'بدون حاجة للفأرة',
                      p.keyboardOnlyNavigation,
                      (v) =>
                          _set(p.copyWith(keyboardOnlyNavigation: v))),
                  _sw('تحكم صوتي',
                      'Voice Control لكل الأوامر',
                      p.voiceControl,
                      (v) => _set(p.copyWith(voiceControl: v))),
                  _sw('تتبع العين',
                      'Eye Tracking — تحكم بالنظر',
                      p.eyeTrackingOptimized,
                      (v) => _set(p.copyWith(eyeTrackingOptimized: v))),
                  _sw('مفاتيح تبديل',
                      'Switch Control للأجهزة المساعدة',
                      p.switchControl,
                      (v) => _set(p.copyWith(switchControl: v))),
                 
                  _sw('بدون تفاعل مؤقّت',
                      'لا شيء يختفي بسرعة',
                      p.noTimedInteractions,
                      (v) => _set(p.copyWith(noTimedInteractions: v))),
                ],
              ),

              // ═══════════════════════════════════════════════
              //  🧠 ميزات الإعاقات الذهنية والنطورية
              // ═══════════════════════════════════════════════
              _featureSection(
                'ميزات الإعاقات الذهنية والنطورية',
                '🧠',
                AppColors.purple,
                c,
                [
                  _sw('وضع الأيقونات فقط',
                      'بدون نصوص — أيقونات كبيرة',
                      p.iconOnlyMode,
                      (v) => _set(p.copyWith(iconOnlyMode: v))),
                  _sw('لغة مبسّطة جداً',
                      'كلمات وجمل قصيرة وسهلة',
                      p.verySimpleLanguage,
                      (v) => _set(p.copyWith(verySimpleLanguage: v))),
                  _sw('تكرار المحتوى',
                      'إعادة تلقائية للمفاهيم',
                      p.repetitionMode,
                      (v) => _set(p.copyWith(repetitionMode: v))),
                  _sw('نظام المكافآت',
                      'نجوم وشارات للتشجيع',
                      p.rewardSystem,
                      (v) => _set(p.copyWith(rewardSystem: v))),
                  _sw('روتين ثابت',
                      'نفس الترتيب في كل جلسة',
                      p.routineStructure,
                      (v) => _set(p.copyWith(routineStructure: v))),
                  _sw('حد أقصى 3 خيارات',
                      'تقليل عدد الخيارات المعروضة',
                      p.maxOptionsCount3,
                      (v) => _set(p.copyWith(maxOptionsCount3: v))),
                ],
              ),

              // ═══════════════════════════════════════════════
              //  ⚙️ خصائص عامة
              // ═══════════════════════════════════════════════
              _featureSection(
                'خصائص عامة',
                '⚙️',
                AppColors.muted,
                c,
                [
                  _sw('أزرار ضخمة جداً', '≥ 88 بكسل',
                      p.extraLargeTouchTargets,
                      (v) => _set(p.copyWith(extraLargeTouchTargets: v))),
                  _sw('تقليل الحركات', 'أنيميشن هادئ',
                      p.reducedAnimations,
                      (v) => _set(p.copyWith(reducedAnimations: v))),
                  _sw('نطق تلقائي عند اللمس', 'قراءة صوتية لكل عنصر',
                      p.autoReadOnTap,
                      (v) => _set(p.copyWith(autoReadOnTap: v))),
                  _sw('نطق بطيء', 'للتأتأة والإعاقة الذهنية',
                      p.slowSpeech,
                      (v) => _set(p.copyWith(slowSpeech: v))),
                  _sw('تباين عالٍ', 'خلفية سوداء وألوان صريحة',
                      p.highContrast,
                      (v) => _set(p.copyWith(highContrast: v))),
                  _sw('وضع الهدوء الحسي', 'إسكات الأصوات والاهتزازات',
                      p.sensoryCalmMode,
                      (v) => _set(p.copyWith(sensoryCalmMode: v))),
                  _sw('زر طوارئ', 'اتصال سريع بالأهل',
                      p.emergencyButton,
                      (v) => _set(p.copyWith(emergencyButton: v))),
                ],
              ),

              // ═══ إعادة الضبط ═══
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('إعادة الضبط'),
                onPressed: () {
                  setState(() => _selectedDisability = null);
                  AccessibilityService.instance.applyRecommendedForChild(
                      widget.childId, DisabilityType.none);
                },
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  // ═══ دوال مساعدة ═══

  Widget _sectionTitle(String title, JisrColors c) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: c.heading,
      ),
    );
  }

  Widget _featureSection(
    String title,
    String emoji,
    Color color,
    JisrColors c,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabilitySelector(JisrColors c) {
    final hasValue = _selectedDisability != null;

    return InkWell(
      onTap: _openDisabilityPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue ? AppColors.teal : c.line,
            width: hasValue ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.medical_services,
              color: hasValue ? AppColors.teal : c.muted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نوع الإعاقة',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasValue ? AppColors.teal : c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasValue ? _selectedDisability! : 'اضغط للاختيار',
                    style: TextStyle(
                      fontSize: 15,
                      color: hasValue ? c.heading : c.muted,
                      fontWeight:
                          hasValue ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: hasValue ? AppColors.teal : c.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sw(String t, String s, bool v, ValueChanged<bool> on) {
    return SwitchListTile(
      dense: true,
      title: Text(t,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14.5)),
      subtitle: Text(s, style: const TextStyle(fontSize: 11.5)),
      value: v,
      onChanged: on,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BottomSheet لاختيار نوع الإعاقة
// ═══════════════════════════════════════════════════════════
class _DisabilityPickerSheet extends StatefulWidget {
  final String? currentValue;
  const _DisabilityPickerSheet({this.currentValue});

  @override
  State<_DisabilityPickerSheet> createState() =>
      _DisabilityPickerSheetState();
}

class _DisabilityPickerSheetState extends State<_DisabilityPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<DisabilityCategory> get _filteredCategories {
    if (_search.trim().isEmpty) return kDisabilityCategories;
    final q = _search.trim().toLowerCase();
    final result = <DisabilityCategory>[];
    for (final cat in kDisabilityCategories) {
      final matchingItems = cat.items
          .where((item) => item.toLowerCase().contains(q))
          .toList();
      if (matchingItems.isNotEmpty ||
          cat.label.toLowerCase().contains(q)) {
        result.add(DisabilityCategory(
          label: cat.label,
          emoji: cat.emoji,
          items: matchingItems.isEmpty ? cat.items : matchingItems,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final categories = _filteredCategories;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: c.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.medical_services,
                    color: AppColors.tealDeep, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'اختر نوع الإعاقة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ابحث عن إعاقة...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: c.tintTeal.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              children: [
                _buildNoDisabilityOption(c),
                const SizedBox(height: 8),
                ...categories.map((cat) => _buildCategory(cat, c)),
                const SizedBox(height: 8),
                _buildOtherOption(c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDisabilityOption(JisrColors c) {
    final isSelected = widget.currentValue == 'بدون تكييف';
    return InkWell(
      onTap: () => Navigator.pop(context, 'بدون تكييف'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.teal.withValues(alpha: 0.15)
              : c.tintTeal.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.teal : c.line,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('⚪', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'بدون تكييف',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(DisabilityCategory cat, JisrColors c) {
    final hasCurrent = widget.currentValue != null &&
        cat.items.contains(widget.currentValue);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line, width: 1.5),
      ),
      child: ExpansionTile(
        initiallyExpanded: hasCurrent,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.only(bottom: 8, left: 8, right: 8),
        iconColor: AppColors.tealDeep,
        collapsedIconColor: c.muted,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(cat.emoji,
              style: const TextStyle(fontSize: 22)),
        ),
        title: Text(
          cat.label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.heading,
          ),
        ),
        subtitle: Text(
          '${cat.items.length} ${cat.items.length == 1 ? 'حالة' : 'حالات'}',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        children: cat.items.map((item) {
          final isSelected = widget.currentValue == item;
          return InkWell(
            onTap: () => Navigator.pop(context, item),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              margin: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.teal.withValues(alpha: 0.2)
                    : c.tintTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border.all(color: AppColors.teal, width: 2)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.arrow_left,
                    size: 18,
                    color: AppColors.tealDeep,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        color: c.heading,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOtherOption(JisrColors c) {
    final isSelected = widget.currentValue == 'أخرى';
    return InkWell(
      onTap: () => Navigator.pop(context, 'أخرى'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.2)
              : AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('✏️', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أخرى',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    'اكتب نوع الإعاقة بنفسك',
                    style: TextStyle(fontSize: 12, color: c.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_left, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}