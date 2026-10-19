import '../../l10n/l10n.dart';
// Text message composer shared by chat screens.
import 'package:flutter/material.dart';
import '../../theme.dart';

class ChatComposer extends StatefulWidget {
  /// نفس الـ controller المستخدم في الشاشة الأم
  final TextEditingController controller;

  /// يُستدعى عند الإرسال — يمرّر النص النهائي
  final ValueChanged<String> onSend;

  /// حالة الإرسال (يُعطّل الحقل والزر أثناءها)
  final bool isSending;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  // ═══════════════════════════════════════════════════════════
  //  إرسال — يجمع النص ويتحقق منه
  // ═══════════════════════════════════════════════════════════
  void _handleSend() {
    final text = widget.controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: _buildS16InputRow(),
    );
  }

  Widget _buildS16InputRow() {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12, 10, 12,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isSending,
                textDirection: Directionality.of(context),
                textAlign: TextAlign.start,
                minLines: 1,
                maxLines: 3,
                maxLength: 2000,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: context.l10n.messagePlaceholder,
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
                  tooltip: context.l10n.send,
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

  // ═══════════════════════════════════════════════════════════
  //  صف الإدخال: الحقل والإرسال
  // ═══════════════════════════════════════════════════════════
}
