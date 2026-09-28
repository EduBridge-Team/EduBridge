// lib/screens/chat/composer_switcher.dart
// ═══════════════════════════════════════════════════════════
//  زر تبديل وضع التواصل داخل المحادثة
//  - زر صغير بجانب حقل الإدخال (يتغير شكله حسب الوضع)
//  - عند الضغط: Bottom Sheet لاختيار الوضع
//  - يستخدم ComposerModeService للحفظ التلقائي
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import 'composer_mode.dart';

// ═══════════════════════════════════════════════════════════
//  الزر الصغير — يتغير حسب الوضع الحالي
// ═══════════════════════════════════════════════════════════
class ComposerSwitcherButton extends StatelessWidget {
  const ComposerSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ComposerMode>(
      valueListenable: ComposerModeService.instance.mode,
      builder: (context, mode, _) {
        final meta = _metaFor(mode);
        final color = _colorFor(mode);

        return Tooltip(
          message: 'وضع: ${meta.label}',
          child: Material(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                HapticFeedback.selectionClick();
                await _showPicker(context);
              },
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  meta.icon,
                  size: 22,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  فتح الـ Bottom Sheet
  // ═══════════════════════════════════════════════════════════
  Future<void> _showPicker(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ComposerModePickerSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Bottom Sheet — اختيار الوضع
// ═══════════════════════════════════════════════════════════
class _ComposerModePickerSheet extends StatelessWidget {
  const _ComposerModePickerSheet();

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── المقبض ───
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ─── العنوان ───
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'كيف تريد أن تتواصل؟',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'اختر الطريقة الأنسب لك',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── الخيارات ───
            ...kComposerModes.map(
              (meta) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ComposerModeTile(meta: meta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  بطاقة وضع واحد
// ═══════════════════════════════════════════════════════════
class _ComposerModeTile extends StatelessWidget {
  final ComposerModeMeta meta;

  const _ComposerModeTile({required this.meta});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return ValueListenableBuilder<ComposerMode>(
      valueListenable: ComposerModeService.instance.mode,
      builder: (context, currentMode, _) {
        final selected = currentMode == meta.mode;
        final accent = _colorFor(meta.mode);

        return Material(
          color: selected
              ? accent.withValues(alpha: 0.08)
              : c.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              HapticFeedback.selectionClick();
              await ComposerModeService.instance.setMode(meta.mode);
              if (context.mounted) Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? accent : c.line,
                  width: selected ? 2 : 1.2,
                ),
              ),
              child: Row(
                children: [
                  // الأيقونة
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      meta.icon,
                      size: 26,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // النصوص
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          meta.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: selected ? accent : c.heading,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.description,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: c.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // علامة الصح
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: accent,
                      size: 24,
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: c.muted,
                      size: 14,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Helpers — لون وأيقونة لكل وضع
// ═══════════════════════════════════════════════════════════
ComposerModeMeta _metaFor(ComposerMode mode) {
  return kComposerModes.firstWhere(
    (m) => m.mode == mode,
    orElse: () => kComposerModes.first,
  );
}

Color _colorFor(ComposerMode mode) {
  switch (mode) {
    case ComposerMode.text:
      return AppColors.navy;
    case ComposerMode.aac:
      return AppColors.orange;
    case ComposerMode.sign:
      return AppColors.pink;
  }
}