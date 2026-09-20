// screens/children_accessibility_overview_screen.dart
// شاشة تعرض كل الأبناء وحالة التكييف الخاصة بكل واحد
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_button.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';
import 'child_accessibility_settings_screen.dart';

class ChildrenAccessibilityOverviewScreen extends StatefulWidget {
  const ChildrenAccessibilityOverviewScreen({super.key});

  @override
  State<ChildrenAccessibilityOverviewScreen> createState() =>
      _ChildrenAccessibilityOverviewScreenState();
}

class _ChildrenAccessibilityOverviewScreenState
    extends State<ChildrenAccessibilityOverviewScreen> {
  List _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiService.authGet('/children');
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        final list = data['children'] ?? [];

        // ✅ إنشاء بروفايل افتراضي لكل طفل جديد
        for (final c in list) {
          final id = c['id'] as int;
          if (AccessibilityService.instance.profileForChild(id) == null) {
            await AccessibilityService.instance.ensureChildProfile(
              id,
              disabilityTypeHint: c['disability_type']?.toString(),
            );
          }
        }

        if (!mounted) return;
        setState(() {
          _children = list;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب الأطفال';
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  فتح إعدادات الطفل
  // ═══════════════════════════════════════════════════════════
  Future<void> _openChildSettings(Map child) async {
    final id = child['id'] as int;
    final name = (child['name'] ?? '').toString();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChildAccessibilitySettingsScreen(
          childId: id,
          childName: name,
          disabilityTypeHint: child['disability_type']?.toString(),
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  // ═══════════════════════════════════════════════════════════
  //  بناء الواجهة
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: 'احتياجات الأبناء الخاصة',
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.accessibility_new, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'احتياجات الأبناء',
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث',
              onPressed: _load,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_children.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      itemCount: _children.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _buildHeader();
        return _buildChildCard(_children[i - 1], i - 1);
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        backgroundColor:
            AdaptiveHelper.accentColor(context).withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(
              Icons.tips_and_updates,
              size: AdaptiveHelper.iconSize,
              color: AdaptiveHelper.accentColor(context),
            ),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    'خصص التكييف لكل طفل',
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: AdaptiveHelper.spacing / 4),
                  AdaptiveText(
                    'كل طفل له احتياجات مختلفة. اضغط على طفلك لتخصيص تجربته.',
                    type: AdaptiveTextType.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(Map child, int index) {
    final name = (child['name'] ?? '').toString();
    final id = child['id'] as int;
    final age = child['age'] ?? '?';
    final disabilityType = child['disability_type']?.toString();

    final profile = AccessibilityService.instance.profileForChild(id) ??
        const AccessibilityProfile(type: DisabilityType.none);

    final color = AppColors.kidPalette[index % AppColors.kidPalette.length];
    final emoji = disabilityEmojis[profile.type] ?? '⚪';
    final label = profile.type == DisabilityType.other
        ? (profile.customDisabilityName ?? 'مخصّص')
        : (disabilityLabels[profile.type] ?? 'بدون تكييف');

    final activeFeatures = _countActiveFeatures(profile);

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing),
      child: AdaptiveCard(
        onTap: () => _openChildSettings(child),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AdaptiveHelper.avatarSize,
                  height: AdaptiveHelper.avatarSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '🙂',
                    style: TextStyle(
                      fontSize: AdaptiveHelper.avatarSize * 0.4,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: AdaptiveHelper.spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdaptiveText(
                        name,
                        type: AdaptiveTextType.subtitle,
                        fontWeight: FontWeight.bold,
                      ),
                      SizedBox(height: AdaptiveHelper.spacing / 4),
                      AdaptiveText(
                        'العمر: $age سنة',
                        type: AdaptiveTextType.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: AdaptiveHelper.accentColor(context),
                  size: AdaptiveHelper.iconSize,
                ),
              ],
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AdaptiveHelper.spacing / 1.5,
                vertical: AdaptiveHelper.spacing / 2,
              ),
              decoration: BoxDecoration(
                color: AdaptiveHelper.accentColor(context)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AdaptiveHelper.accentColor(context)
                      .withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Text(emoji,
                      style:
                          TextStyle(fontSize: AdaptiveHelper.iconSize)),
                  SizedBox(width: AdaptiveHelper.spacing / 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AdaptiveText(
                          'نوع الإعاقة',
                          type: AdaptiveTextType.label,
                          color: AdaptiveHelper.accentColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 2),
                        AdaptiveText(
                          label,
                          type: AdaptiveTextType.body,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AdaptiveHelper.spacing / 2),

            if (activeFeatures > 0) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: AdaptiveHelper.iconSize * 0.7,
                    color: AppColors.green,
                  ),
                  SizedBox(width: AdaptiveHelper.spacing / 3),
                  AdaptiveText(
                    '$activeFeatures ميزة تكييف مُفعّلة',
                    type: AdaptiveTextType.caption,
                    color: AppColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: AdaptiveHelper.spacing / 2),
            ],

            Wrap(
              spacing: AdaptiveHelper.spacing / 3,
              runSpacing: AdaptiveHelper.spacing / 3,
              children: _buildFeatureBadges(profile),
            ),

            SizedBox(height: AdaptiveHelper.spacing),

            AdaptiveButton(
              label: 'تخصيص التكييف',
              icon: Icons.tune,
              backgroundColor: AdaptiveHelper.accentColor(context),
              onPressed: () => _openChildSettings(child),
            ),
          ],
        ),
      ),
    );
  }

  int _countActiveFeatures(AccessibilityProfile p) {
    int count = 0;
    final features = [
      p.brainBreaksEnabled,
      p.visualTimerEnabled,
      p.reducedAnimations,
      p.predictableTimeline,
      p.sensoryCalmMode,
      p.extraLargeTouchTargets,
      p.autoReadOnTap,
      p.simpleIconsGrid,
      p.highContrast,
      p.gestureNavigationEnabled,
      p.visualAlertsEnabled,
      p.slowSpeech,
      p.rhythmReading,
      p.stepByStepLessons,
      p.realLifeLinking,
      p.colorSymbols,
      p.colorPatterns,
      p.colorFiltersEnabled,
      p.noFlashing,
      p.calmColors,
      p.emergencyButton,
      p.noTimers,
      p.speechExercises,
      p.screenReaderOptimized,
      p.textOnlyMode,
      p.largeMouseCursor,
      p.keyboardOnlyNavigation,
      p.eyeTrackingOptimized,
      p.switchControl,
      p.noTimedInteractions,
      p.iconOnlyMode,
      p.verySimpleLanguage,
      p.repetitionMode,
      p.rewardSystem,
      p.routineStructure,
      p.maxOptionsCount3,
      p.shortSentences,
      p.detailedAltText,
      p.audioDescriptions,
      p.videoCaptions,
      p.soundDescriptions,
      p.signLanguageTranslation,
      p.visualNotifications,
      p.flashAlerts,
      p.vibrationAlerts,
      p.voiceToText,
      p.wordPrediction,
      p.pictureCommunication,
      p.voiceControl,
      p.keyboardShortcuts,
    ];
    for (final f in features) {
      if (f) count++;
    }
    return count;
  }

  List<Widget> _buildFeatureBadges(AccessibilityProfile p) {
    final badges = <Widget>[];

    void addBadge(String emoji, String label, Color color) {
      badges.add(
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AdaptiveHelper.spacing / 2,
            vertical: AdaptiveHelper.spacing / 4,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize - 5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (p.videoCaptions) addBadge('📝', 'ترجمات', AppColors.pink);
    if (p.signLanguageTranslation) {
      addBadge('🤟', 'لغة إشارة', AppColors.pink);
    }
    if (p.vibrationAlerts) addBadge('📳', 'اهتزاز', AppColors.pink);
    if (p.detailedAltText) addBadge('🔊', 'وصف صوتي', AppColors.navy);
    if (p.audioDescriptions) {
      addBadge('🎧', 'وصف فيديو', AppColors.navy);
    }
    if (p.pictureCommunication) {
      addBadge('🖼️', 'تواصل بالصور', AppColors.purple);
    }
    if (p.voiceToText) addBadge('🎤', 'كتابة صوتية', AppColors.purple);
    if (p.slowSpeech) addBadge('🐢', 'نطق بطيء', AppColors.orangeDeep);
    if (p.voiceControl) addBadge('🎙️', 'تحكم صوتي', AppColors.tealDeep);
    if (p.keyboardOnlyNavigation || p.keyboardShortcuts) {
      addBadge('⌨️', 'لوحة مفاتيح', AppColors.tealDeep);
    }
    if (p.verySimpleLanguage) {
      addBadge('💡', 'لغة مبسّطة', AppColors.purple);
    }
    if (p.iconOnlyMode) addBadge('🎨', 'أيقونات', AppColors.purple);
    if (p.rewardSystem) addBadge('⭐', 'مكافآت', AppColors.yellow);
    if (p.shortSentences) {
      addBadge('📏', 'جمل قصيرة', AppColors.purple);
    }
    if (p.extraLargeTouchTargets) {
      addBadge('🔘', 'أزرار كبيرة', AppColors.tealDeep);
    }
    if (p.autoReadOnTap) addBadge('👆', 'نطق باللمس', AppColors.teal);
    if (p.highContrast) addBadge('🌓', 'تباين عالٍ', AppColors.navy);
    if (p.noTimers) addBadge('⏸️', 'بدون وقت', AppColors.green);
    if (p.reducedAnimations) {
      addBadge('🎬', 'حركة هادئة', AppColors.teal);
    }
    if (p.emergencyButton) addBadge('🚨', 'طوارئ', AppColors.red);

    if (badges.isEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚪', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                'لا توجد ميزات',
                style: TextStyle(
                  fontSize: AdaptiveHelper.bodyFontSize - 5,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return badges;
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Icon(
          Icons.people_outline,
          size: AdaptiveHelper.iconSize * 2,
          color: Colors.grey,
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        const AdaptiveText(
          'لا يوجد أبناء مسجّلون بعد',
          type: AdaptiveTextType.subtitle,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AdaptiveHelper.spacing / 2),
        const AdaptiveText(
          'أضف أطفالك من الشاشة الرئيسية',
          type: AdaptiveTextType.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AdaptiveHelper.iconSize * 2,
              color: Colors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveText(
              _error!,
              type: AdaptiveTextType.body,
              textAlign: TextAlign.center,
              color: Colors.red,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            AdaptiveButton(
              label: 'إعادة المحاولة',
              icon: Icons.refresh,
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }
}