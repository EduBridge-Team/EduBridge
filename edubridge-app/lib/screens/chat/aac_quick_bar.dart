// lib/screens/chat/aac_quick_bar.dart
// ═══════════════════════════════════════════════════════════
//  شريط التواصل بالصور (AAC) — يظهر فوق حقل الإدخال
//  - 5 تصنيفات قابلة للتبديل
//  - شريط أفقي من البطاقات
//  - اضغط = أضف + نطق | اضغط مطوّلاً = سماع العبارة
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/accessibility_service.dart';
import '../../data/aac_data.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

class AacQuickBar extends StatefulWidget {
  /// عند اختيار بطاقة: يُمرّر النص المعروض + النص المنطوق
  final void Function(String label, String spoken) onItemSelected;

  /// زر إغلاق الشريط
  final VoidCallback? onClose;
  final bool enabled;

  const AacQuickBar({
    super.key,
    required this.onItemSelected,
    this.onClose,
    this.enabled = true,
  });

  @override
  State<AacQuickBar> createState() => _AacQuickBarState();
}

class _AacQuickBarState extends State<AacQuickBar> {
  /// التصنيف المفتوح حالياً
  late String _activeCategoryKey;

  @override
  void initState() {
    super.initState();
    _activeCategoryKey = kAacCategories.keys.first;
  }

  AccessibilityProfile get _profile =>
      AccessibilityService.instance.applicationProfile.value;

  void _feedback() {
    // The chat uses the account profile, never a child opened elsewhere.
    if (_profile.vibrationAlerts && !_profile.sensoryCalmMode) {
      HapticFeedback.selectionClick();
    }
  }

  void _speak(String text) {
    // Selecting a communication symbol is an explicit speech request.
    if (_profile.slowSpeech) {
      TtsService.instance.speakLineSlow(text);
    } else {
      TtsService.instance.speakLine(text);
    }
  }

  List<AacItem> get _activeItems =>
      kAacCategories[_activeCategoryKey] ?? const [];

  // ═══════════════════════════════════════════════════════════
  //  عند ضغط بطاقة
  // ═══════════════════════════════════════════════════════════
  void _onTapItem(AacItem item) {
    if (!widget.enabled) return;
    _feedback();
    _speak(item.spoken);
    widget.onItemSelected(item.label, item.spoken);
  }

  // ═══════════════════════════════════════════════════════════
  //  عند ضغط مطوّل — عرض تفاصيل البطاقة
  // ═══════════════════════════════════════════════════════════
  void _onLongPressItem(AacItem item) {
    if (!widget.enabled) return;
    _feedback();
    _speak(item.spoken);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppColors.navy,
          content: Row(
            children: [
              const Icon(
                Icons.record_voice_over,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'صوتياً يقول: "${item.spoken}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.applicationProfile,
      builder: (context, profile, _) => Container(
        decoration: BoxDecoration(
          color: c.card,
          border: Border(top: BorderSide(color: c.line, width: 1.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(c),
            _buildCategoryTabs(c),
            _buildItemsRow(c),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الرأس — عنوان + إغلاق
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.grid_view_rounded,
              size: 18,
              color: AppColors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'التواصل بالصور',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                Text(
                  'اضغط للإضافة والنطق • اضغط مطوّلاً لسماع العبارة',
                  style: TextStyle(fontSize: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: c.muted, size: 20),
              tooltip: 'إغلاق التواصل بالصور',
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  التصنيفات
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryTabs(JisrColors c) {
    final keys = kAacCategories.keys.toList();

    return SizedBox(
      height: 24 + MediaQuery.textScalerOf(context).scale(14) * 2,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: keys.length,
        itemBuilder: (context, i) {
          final key = keys[i];
          final selected = key == _activeCategoryKey;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: GestureDetector(
              onTap: !widget.enabled ? null : () {
                _feedback();
                setState(() => _activeCategoryKey = key);
              },
              child: AnimatedContainer(
                duration: _profile.sensoryCalmMode || _profile.reducedAnimations ||
                    _profile.noFlashing || MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero : const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.orange
                      : c.tintTeal.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.orange : c.line,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: selected ? Colors.white : c.body,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  صف البطاقات
  // ═══════════════════════════════════════════════════════════
  Widget _buildItemsRow(JisrColors c) {
    return SizedBox(
      height: 72 + MediaQuery.textScalerOf(context).scale(14) * 3,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        itemCount: _activeItems.length,
        itemBuilder: (context, i) {
          final item = _activeItems[i];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _AacCard(
              item: item,
              onTap: widget.enabled ? () => _onTapItem(item) : null,
              onLongPress: widget.enabled ? () => _onLongPressItem(item) : null,
              largeTargets: _profile.extraLargeTouchTargets,
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة AAC واحدة
// ═══════════════════════════════════════════════════════════
class _AacCard extends StatelessWidget {
  final AacItem item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool largeTargets;

  const _AacCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
    required this.largeTargets,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: item.spoken,
      excludeSemantics: true,
      onTap: onTap,
      onLongPress: onLongPress,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: (largeTargets ? 112.0 : 96.0) *
              (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.orange.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // الأيقونة
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 22,
                  color: AppColors.orangeDeep,
                ),
              ),
              const SizedBox(height: 4),

              // النص
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
