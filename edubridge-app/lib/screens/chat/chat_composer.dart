// lib/screens/chat/chat_composer.dart
// ═══════════════════════════════════════════════════════════
//  Composer موحّد للمحادثة — يجمع:
//    • زر تبديل الوضع (نص / صور / إشارة)
//    • حقل الكتابة
//    • شريط AAC أو شريط الإشارة (حسب الوضع)
//    • زر الإرسال
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/accessibility_service.dart';
import '../../services/tts_service.dart';
import 'aac_quick_bar.dart';
import 'composer_mode.dart';
import 'composer_switcher.dart';
import 'sign_quick_bar.dart';

class ChatComposer extends StatefulWidget {
  /// نفس الـ controller المستخدم في الشاشة الأم
  final TextEditingController controller;

  /// يُستدعى عند الإرسال — يمرّر النص النهائي
  final ValueChanged<String> onSend;

  /// حالة الإرسال (يُعطّل الحقل والزر أثناءها)
  final bool isSending;

  /// Figma S16 visual treatment for specialist chat only.
  final bool figmaS16;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
    this.figmaS16 = false,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    // نضمن تحميل الوضع المحفوظ مرة واحدة
    ComposerModeService.instance.ensureLoaded();
  }

  // ═══════════════════════════════════════════════════════════
  //  إرسال — يجمع النص ويتحقق منه
  // ═══════════════════════════════════════════════════════════
  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
  }

  // ═══════════════════════════════════════════════════════════
  //  إضافة رمز/بطاقة إلى حقل الإدخال
  // ═══════════════════════════════════════════════════════════
  void _appendToInput(String insertion) {
    if (widget.isSending) return;
    final current = widget.controller.text.trimRight();
    final next = current.isEmpty ? insertion : '$current $insertion';

    widget.controller.text = next;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  إعادة الوضع إلى "نص" (عند إغلاق شريط)
  // ═══════════════════════════════════════════════════════════
  Future<void> _closeAssistBar() async {
    await ComposerModeService.instance.setMode(ComposerMode.text);
  }

  // ═══════════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return ValueListenableBuilder<ComposerMode>(
      valueListenable: ComposerModeService.instance.mode,
      builder: (context, mode, _) {
        return Container(
          decoration: BoxDecoration(
            color: c.card,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── شريط المساعدة (AAC أو إشارة) ───
              if (mode == ComposerMode.aac)
                AacQuickBar(
                  enabled: !widget.isSending,
                  onItemSelected: (_, spoken) => _appendToInput(spoken),
                  onClose: _closeAssistBar,
                )
              else if (mode == ComposerMode.sign)
                SignQuickBar(
                  onSignSelected: (insertion, _) => _appendToInput(insertion),
                  onClose: _closeAssistBar,
                ),

              if (mode == ComposerMode.aac) _buildMessagePreview(),

              // ─── حقل الإدخال + الأزرار ───
              widget.figmaS16
                  ? _buildS16InputRow(mode)
                  : _buildInputRow(c, mode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildS16InputRow(ComposerMode mode) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12, 10, 12,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const ComposerSwitcherButton(figmaS16: true),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isSending,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                minLines: 1,
                maxLines: 3,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: _hintFor(mode),
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF718DA4),
                  ),
                  counterText: '',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                      color: Color(0xFFD8E7F2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                      color: Color(0xFF196AC6), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final enabled =
                    value.text.trim().isNotEmpty && !widget.isSending;
                return IconButton.filled(
                  tooltip: 'إرسال',
                  onPressed: enabled ? _handleSend : null,
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 19, height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.mark_email_read_outlined, size: 23),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    maximumSize: const Size(48, 48),
                    shape: const CircleBorder(),
                    backgroundColor: const Color(0xFF196AC6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE9F1F7),
                    disabledForegroundColor: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('أسمع رسالتي', textAlign: TextAlign.center),
            onPressed: widget.isSending || value.text.trim().isEmpty
                ? null
                : () {
                    final text = widget.controller.text.trim();
                    final profile = AccessibilityService.instance.applicationProfile.value;
                    if (profile.slowSpeech) {
                      TtsService.instance.speakLineSlow(text);
                    } else {
                      TtsService.instance.speakLine(text);
                    }
                  },
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  صف الإدخال: زر الوضع + الحقل + الإرسال
  // ═══════════════════════════════════════════════════════════
  Widget _buildInputRow(JisrColors c, ComposerMode mode) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ─── زر تبديل الوضع ───
          const ComposerSwitcherButton(),
          const SizedBox(width: 8),

          // ─── حقل الإدخال ───
          Expanded(child: _buildTextField(mode)),

          const SizedBox(width: 8),

          // ─── زر الإرسال ───
          _buildSendButton(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  حقل الإدخال — يتغير الـ hint حسب الوضع
  // ═══════════════════════════════════════════════════════════
  Widget _buildTextField(ComposerMode mode) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: widget.controller,
          enabled: !widget.isSending,
          minLines: 1,
          maxLines: 4,
          maxLength: 2000,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: _hintFor(mode),
            counterText: '',
            suffixIcon: hasText && !widget.isSending
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'مسح',
                    onPressed: () => widget.controller.clear(),
                  )
                : null,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  زر الإرسال — يظهر دائرة أو مؤشر تحميل
  // ═══════════════════════════════════════════════════════════
  Widget _buildSendButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final canSend = value.text.trim().isNotEmpty && !widget.isSending;

        return IconButton.filled(
          tooltip: 'إرسال',
          onPressed: canSend ? _handleSend : null,
          icon: widget.isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(52, 52),
            backgroundColor:
                canSend ? AppColors.orange : AppColors.muted.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                AppColors.muted.withValues(alpha: 0.25),
            disabledForegroundColor: Colors.white70,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Hint لكل وضع
  // ═══════════════════════════════════════════════════════════
  String _hintFor(ComposerMode mode) {
    switch (mode) {
      case ComposerMode.text:
        return 'اكتب رسالتك...';
      case ComposerMode.aac:
        return 'اختر صوراً أو اكتب...';
      case ComposerMode.sign:
        return 'اختر رموز الإشارة أو اكتب...';
    }
  }
}