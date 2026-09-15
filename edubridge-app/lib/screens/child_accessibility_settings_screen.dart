// إعدادات التكييف لطفل واحد — مع خيار "أخرى" ونص حرّ
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../theme.dart';

class ChildAccessibilitySettingsScreen extends StatefulWidget {
  final int childId;
  final String childName;
  final String? disabilityTypeHint;

  const ChildAccessibilitySettingsScreen({
    super.key,
    required this.childId,
    required this.childName,
    this.disabilityTypeHint,
  });

  @override
  State<ChildAccessibilitySettingsScreen> createState() =>
      _ChildAccessibilitySettingsScreenState();
}

class _ChildAccessibilitySettingsScreenState
    extends State<ChildAccessibilitySettingsScreen> {
  final _customNameCtrl = TextEditingController();
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityTypeHint,
    );
    // إن كان الطفل مصنّفاً "أخرى" → أظهر حقل النص
    final p = AccessibilityService.instance.profileForChild(widget.childId);
    if (p?.type == DisabilityType.other) {
      _showCustomField = true;
      _customNameCtrl.text = p?.customDisabilityName ?? '';
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  AccessibilityProfile get _p =>
      AccessibilityService.instance.profileForChild(widget.childId) ??
      const AccessibilityProfile(type: DisabilityType.none);

  Future<void> _set(AccessibilityProfile next) =>
      AccessibilityService.instance.updateForChild(widget.childId, next);

  Future<void> _selectDisability(DisabilityType type) async {
    if (type == DisabilityType.other) {
      setState(() => _showCustomField = true);
      // لا نُطبّق البروفايل بعد — ننتظر إدخال النص
      return;
    }
    setState(() => _showCustomField = false);
    await AccessibilityService.instance.applyRecommendedForChild(
      widget.childId,
      type,
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ الإعاقة المخصّصة'),
        backgroundColor: Colors.green,
      ),
    );
    setState(() {});
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
              // رأس
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

              // ─── اختيار نوع الإعاقة ───
              Text(
                'نوع الإعاقة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 6),

              ...DisabilityType.values.map((t) {
                final emoji = disabilityEmojis[t] ?? '⚪';
                final label = disabilityLabels[t] ?? t.name;
                final isOther = t == DisabilityType.other;
                final customLabel =
                    isOther && p.type == DisabilityType.other
                        ? ' — ${p.customDisabilityName ?? ""}'
                        : '';

                return RadioListTile<DisabilityType>(
                  title: Text(
                    '$emoji  $label$customLabel',
                    style: const TextStyle(fontSize: 15),
                  ),
                  value: t,
                  groupValue: p.type,
                  onChanged: (v) {
                    if (v != null) _selectDisability(v);
                  },
                );
              }),

              // ─── حقل النص الحرّ عند اختيار "أخرى" ───
              if (_showCustomField) ...[
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

              const Divider(height: 32),

              // ─── خصائص متقدّمة ───
              Text(
                'خصائص متقدّمة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 8),

              _sw('فواصل ذهنية تلقائية',
                  'تظهر كل ${p.brainBreakIntervalMinutes} دقيقة',
                  p.brainBreaksEnabled,
                  (v) => _set(p.copyWith(brainBreaksEnabled: v))),

              if (p.brainBreaksEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: p.brainBreakIntervalMinutes.toDouble(),
                    min: 5,
                    max: 45,
                    divisions: 8,
                    label: '${p.brainBreakIntervalMinutes} د',
                    onChanged: (v) => _set(p.copyWith(
                        brainBreakIntervalMinutes: v.round())),
                  ),
                ),

              _sw('مؤقّت بصري', 'الوقت المتبقي كحلقة ملوّنة',
                  p.visualTimerEnabled,
                  (v) => _set(p.copyWith(visualTimerEnabled: v))),

              _sw('تقليل الحركات', 'أنيميشن هادئ',
                  p.reducedAnimations,
                  (v) => _set(p.copyWith(reducedAnimations: v))),

              _sw('خط زمني بصري', 'خطوات الدرس ثابتة ومرئية',
                  p.predictableTimeline,
                  (v) => _set(p.copyWith(predictableTimeline: v))),

              _sw('وضع الهدوء الحسي', 'إسكات الأصوات والاهتزازات',
                  p.sensoryCalmMode,
                  (v) => _set(p.copyWith(sensoryCalmMode: v))),

              _sw('أزرار ضخمة جداً', '≥ 88 بكسل',
                  p.extraLargeTouchTargets,
                  (v) => _set(p.copyWith(extraLargeTouchTargets: v))),

              _sw('نطق تلقائي عند اللمس', 'قراءة صوتية لكل عنصر',
                  p.autoReadOnTap,
                  (v) => _set(p.copyWith(autoReadOnTap: v))),

              _sw('تباين عالٍ', 'خلفية سوداء وألوان صريحة',
                  p.highContrast,
                  (v) => _set(p.copyWith(highContrast: v))),

              _sw('ملاحة بالإيماءات', 'سحب بأسهم',
                  p.gestureNavigationEnabled,
                  (v) => _set(p.copyWith(gestureNavigationEnabled: v))),

              _sw('تنبيهات بصرية فقط', 'استبدال الأصوات بوميض ملوّن',
                  p.visualAlertsEnabled,
                  (v) => _set(p.copyWith(visualAlertsEnabled: v))),

              const Divider(height: 32),
              // ✅ قسم مدة تجديد المؤقّت
              if (p.visualTimerEnabled && !p.noTimers) ...[
                const Divider(height: 32),
                Text(
                  '⏱️ مدة تجديد المؤقّت',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل كم دقيقة يتجدّد مؤقّت الدرس تلقائياً؟',
                  style: TextStyle(fontSize: 12.5, color: c.muted),
                ),
                const SizedBox(height: 12),
                
                // عرض القيمة الحالية
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.tintTeal,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: AppColors.tealDeep, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'كل ${p.timerRenewalMinutes} دقيقة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: c.onTint,
                              ),
                            ),
                            Text(
                              'التوصية حسب عمر الطفل: 4-7 سنوات → 3-5 د | 8-10 → 5-10 د | 11+ → 10-15 د',
                              style: TextStyle(fontSize: 11, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // اختيار المدة
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [3, 5, 10, 15, 20, 30].map((m) {
                    final selected = p.timerRenewalMinutes == m;
                    return ChoiceChip(
                      label: Text(
                        '$m د',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : c.body,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.tealDeep,
                      onSelected: (v) {
                        if (v) {
                          _set(p.copyWith(timerRenewalMinutes: m));
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
              // ─── الخصائص الجديدة ───
              Text(
                'خصائص الإعاقات الخاصة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 8),

              _sw('نطق بطيء', 'للتأتأة والإعاقة الذهنية',
                  p.slowSpeech,
                  (v) => _set(p.copyWith(slowSpeech: v))),

              _sw('قراءة بالإيقاع', 'لتقليل التأتأة',
                  p.rhythmReading,
                  (v) => _set(p.copyWith(rhythmReading: v))),

              _sw('تمارين النطق', 'تدريبات تفاعلية للنطق',
                  p.speechExercises,
                  (v) => _set(p.copyWith(speechExercises: v))),

              _sw('دروس خطوة بخطوة', 'تقسيم المهام لخطوات صغيرة',
                  p.stepByStepLessons,
                  (v) => _set(p.copyWith(stepByStepLessons: v))),

              _sw('ربط بالحياة اليومية', 'أمثلة من الواقع',
                  p.realLifeLinking,
                  (v) => _set(p.copyWith(realLifeLinking: v))),

              _sw('رموز على الألوان', '✓ ✗ ● ▲ لعمى الألوان',
                  p.colorSymbols,
                  (v) => _set(p.copyWith(colorSymbols: v))),

              _sw('أنماط بديلة للألوان', 'خطوط ونقاط',
                  p.colorPatterns,
                  (v) => _set(p.copyWith(colorPatterns: v))),

              _sw('فلاتر ملوّنة', 'تعديل الألوان للتمييز',
                  p.colorFiltersEnabled,
                  (v) => _set(p.copyWith(colorFiltersEnabled: v))),

              _sw('منع الوميض', 'للصرع — لا ومضات',
                  p.noFlashing,
                  (v) => _set(p.copyWith(noFlashing: v))),

              _sw('ألوان هادئة', 'تقليل التحفيز البصري',
                  p.calmColors,
                  (v) => _set(p.copyWith(calmColors: v))),

              _sw('زر طوارئ', 'اتصال سريع بالأهل',
                  p.emergencyButton,
                  (v) => _set(p.copyWith(emergencyButton: v))),

              _sw('لا مؤقّتات', 'بدون ضغط زمني',
                  p.noTimers,
                  (v) => _set(p.copyWith(noTimers: v))),

              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('إعادة الضبط'),
                onPressed: () => AccessibilityService.instance
                    .applyRecommendedForChild(
                        widget.childId, DisabilityType.none),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _sw(String t, String s, bool v, ValueChanged<bool> on) {
    return SwitchListTile(
      title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(s, style: const TextStyle(fontSize: 12.5)),
      value: v,
      onChanged: on,
    );
  }
}