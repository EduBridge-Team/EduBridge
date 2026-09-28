// lib/screens/chat/sign_quick_bar.dart
// ═══════════════════════════════════════════════════════════
//  شريط رموز لغة الإشارة — يظهر فوق حقل الإدخال في المحادثة
//  - 4 تصنيفات قابلة للتبديل
//  - شريط أفقي من البطاقات
//  - اضغط = أضف + نطق | اضغط مطوّلاً = تلميح
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/sign_language_data.dart';
import '../../services/tts_service.dart';
import '../../theme.dart';

class SignQuickBar extends StatefulWidget {
  /// عند اختيار رمز: يُمرّر النص المُضاف + النص المنطوق
  final void Function(String insertion, String spoken) onSignSelected;

  /// زر إغلاق الشريط (يعيد الوضع إلى "نص")
  final VoidCallback? onClose;

  const SignQuickBar({
    super.key,
    required this.onSignSelected,
    this.onClose,
  });

  @override
  State<SignQuickBar> createState() => _SignQuickBarState();
}

class _SignQuickBarState extends State<SignQuickBar> {
  /// التصنيف المفتوح حالياً (افتراضياً: الحروف)
  String _activeCategoryId = kSignCategories.first.id;

  SignCategory get _activeCategory => kSignCategories.firstWhere(
        (c) => c.id == _activeCategoryId,
        orElse: () => kSignCategories.first,
      );

  // ═══════════════════════════════════════════════════════════
  //  عند ضغط رمز
  // ═══════════════════════════════════════════════════════════
  void _onTapSign(SignItem item) {
    HapticFeedback.lightImpact();
    TtsService.instance.speakLine(item.spoken);
    widget.onSignSelected(item.insertion, item.spoken);
  }

  // ═══════════════════════════════════════════════════════════
  //  عند ضغط مطوّل — عرض التلميح
  // ═══════════════════════════════════════════════════════════
  void _onLongPressSign(SignItem item) {
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: AppColors.navy,
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.label} — كيف تشير؟',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.hint ?? 'لا يوجد تلميح',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
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

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line, width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(c),
          _buildCategoryTabs(c),
          _buildSignRow(c),
        ],
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
              color: AppColors.pink.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.sign_language,
              size: 18,
              color: AppColors.pink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'لغة الإشارة العربية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: c.heading,
                  ),
                ),
                Text(
                  'اضغط = إضافة | اضغط مطوّلاً = تلميح',
                  style: TextStyle(fontSize: 10.5, color: c.muted),
                ),
              ],
            ),
          ),
          if (widget.onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: c.muted, size: 20),
              tooltip: 'إغلاق لغة الإشارة',
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
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
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: kSignCategories.length,
        itemBuilder: (context, i) {
          final cat = kSignCategories[i];
          final selected = cat.id == _activeCategoryId;

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeCategoryId = cat.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.pink
                      : c.tintTeal.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.pink : c.line,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat.emoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : c.body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  صف الرموز
  // ═══════════════════════════════════════════════════════════
  Widget _buildSignRow(JisrColors c) {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        itemCount: _activeCategory.items.length,
        itemBuilder: (context, i) {
          final item = _activeCategory.items[i];
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: _SignCard(
              item: item,
              onTap: () => _onTapSign(item),
              onLongPress: () => _onLongPressSign(item),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة رمز واحد
// ═══════════════════════════════════════════════════════════
class _SignCard extends StatelessWidget {
  final SignItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SignCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 78,
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.pink.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.08),
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
                color: AppColors.pink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 24,
                color: AppColors.pink,
              ),
            ),
            const SizedBox(height: 4),

            // الحرف/الكلمة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}