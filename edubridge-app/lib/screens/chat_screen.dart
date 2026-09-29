// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat/chat_composer.dart';

part 'chat_screen_view.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String otherUserName;
  final String otherUserRole;
  final String childName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.childName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List _messages = [];
  final _messageCtrl = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final messages = await ApiService.getMessages(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الرسائل';
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  يقبل نصاً مباشراً من ChatComposer أو من الحقل
  // ═══════════════════════════════════════════════════════════
  Future<void> _sendMessage({String? contentOverride}) async {
    final content = (contentOverride ?? _messageCtrl.text).trim();
    if (content.isEmpty || _sending) return;

    _messageCtrl.clear();
    setState(() => _sending = true);

    try {
      await ApiService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إرسال الرسالة: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String senderName;
  final String time;
  final Color color;
  final Color textColor;

  const _ChatBubble({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.time,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final initial = senderName.trim().isNotEmpty
        ? senderName.trim().characters.first
        : '؟';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : const Radius.circular(6),
                  bottomRight: isMe
                      ? const Radius.circular(6)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe)
            Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                AppIcons.profile,
                size: 17,
                color: AppColors.brandBlue,
              ),
            ),
        ],
      ),
    );
  }
}