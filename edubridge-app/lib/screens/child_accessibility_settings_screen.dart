// إعدادات التكييف لطفل واحد فقط — تُفتح من داخل واجهة الطفل
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
  @override
  void initState() {
    super.initState();
    AccessibilityService.instance.setActiveChild(
      widget.childId,
      disabilityTypeHint: widget.disabilityTypeHint,
    );
  }

  AccessibilityProfile get _p =>
      AccessibilityService.instance.profileForChild(widget.childId) ??
      const AccessibilityProfile(type: DisabilityType.none);

  Future<void> _set(AccessibilityProfile next) =>
      AccessibilityService.instance.updateForChild(widget.childId, next);

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
                        'هذه الإعدادات تُطبَّق على ${widget.childName} فقط، '
                        'ولن تؤثر على بقية الأطفال.',
                        style: TextStyle(color: c.onTint, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('نوع الإعاقة',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.heading)),
              const SizedBox(height: 6),

              ...DisabilityType.values
                  .map((t) => RadioListTile<DisabilityType>(
                        title: Text(disabilityLabels[t] ?? t.name),
                        value: t,
                        groupValue: p.type,
                        onChanged: (v) {
                          if (v != null) {
                            AccessibilityService.instance
                                .applyRecommendedForChild(widget.childId, v);
                          }
                        },
                      )),

              const Divider(height: 32),
              Text('خصائص متقدّمة',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: c.heading)),
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

              _sw('تقليل الحركات', 'أنيميشن هادئ', p.reducedAnimations,
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

              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('إعادة الضبط لهذا الطفل'),
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