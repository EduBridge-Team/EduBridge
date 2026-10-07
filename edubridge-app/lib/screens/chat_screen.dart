import '../utils/presentation_text.dart';
// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../features/communication/data/conversation_repository.dart';
import '../features/communication/presentation/communication_list_controller.dart';
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
  final _repository = ConversationRepository();
  late final CommunicationListController _listController;
  List get _messages => _listController.items;
  bool get _loading => _listController.loading;
  String? get _error => _listController.error;

  void _onListChanged() {
    if (mounted) setState(() {});
  }
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listController = CommunicationListController(
      load: () => _repository.loadMessages(widget.conversationId), errorMessage: 'تعذّر تحميل الرسائل',
    )..addListener(_onListChanged);
    _loadMessages();
  }

  @override
  void dispose() {
    _listController.removeListener(_onListChanged);
    _listController.dispose();
    _messageCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final loaded = await _listController.reload();
    if (loaded && mounted) _scrollToBottom();
  }

  Future<void> _sendMessage({String? contentOverride}) async {
    final content = (contentOverride ?? _messageCtrl.text).trim();
    if (content.isEmpty || _sending) return;

    _messageCtrl.clear();
    setState(() => _sending = true);

    try {
      await _repository.send(widget.conversationId, content);

      if (!mounted) return;
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذّر إرسال الرسالة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
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
    final initial = PresentationText.initial(senderName, trim: true, fallback: '؟');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                style: TextStyle(
                  fontSize: 14,
                  color: c.infoText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(6),
                  bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(20),
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
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: c.infoText,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(color: textColor, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.90)
                          : c.muted,
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
              child: Icon(AppIcons.profile, size: 17, color: c.infoText),
            ),
        ],
      ),
    );
  }
}
