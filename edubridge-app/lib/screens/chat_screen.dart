// شاشة الدردشة - التواصل بين المعلم والمختص
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل الرسائل';
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageCtrl.text.trim();
    if (content.isEmpty || _sending) return;

    setState(() {
      _sending = true;
    });

    try {
      await ApiService.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );

      _messageCtrl.clear();
      await _loadMessages();
    } catch (e) {
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
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: '${widget.otherUserName} (${widget.otherUserRole})',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // رأس المحادثة مع اسم الطفل
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.tintTeal,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                const Icon(Icons.child_care, color: AppColors.tealDeep),
                const SizedBox(width: 8),
                Text(
                  'مناقشة حالة: ${widget.childName}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: c.heading,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: c.muted),
                                const SizedBox(height: 16),
                                Text(
                                  'لا توجد رسائل بعد',
                                  style: TextStyle(color: c.muted),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ المحادثة الآن',
                                  style: TextStyle(fontSize: 14, color: c.muted),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final msg = _messages[i];
                              final isMe = msg['is_mine'] ?? false;
                              final date = msg['created_at'] != null
                                  ? DateTime.parse(msg['created_at'])
                                  : null;

                              return _ChatBubble(
                                message: msg['content'] ?? '',
                                isMe: isMe,
                                senderName: isMe ? 'أنا' : widget.otherUserName,
                                time: date != null
                                    ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                                    : '',
                                color: isMe ? AppColors.teal : c.card,
                                textColor: isMe ? Colors.white : c.body,
                              );
                            },
                          ),
          ),
          // حقل الإدخال
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: c.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// مكوّن فقاعة الدردشة
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                color: AppColors.orange,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.orange,
                child: Text(
                  senderName.characters.first,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orangeDeep,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: TextStyle(color: textColor),
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
              margin: const EdgeInsets.only(left: 8),
              decoration: const BoxDecoration(
                color: AppColors.tealDeep,
                shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.tealDeep,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}