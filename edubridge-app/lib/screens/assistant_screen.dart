import 'package:flutter/material.dart';

import '../services/assistant_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import '../widgets/pet_avatar.dart';

class AssistantScreen extends StatefulWidget {
  final String? lessonContext;

  const AssistantScreen({super.key, this.lessonContext});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  static const _welcome = AssistantMessage(
    role: 'assistant',
    content:
        'مرحباً! أنا نور ✨\nأستطيع تبسيط الدروس والإجابة عن أسئلتك. كيف أساعدك؟',
  );

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<AssistantMessage> _messages = const [_welcome];
  bool _loadingHistory = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    assistantScreenVisible.value = true;
    _loadHistory();
  }

  @override
  void dispose() {
    assistantScreenVisible.value = false;
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await AssistantService.loadHistory();
    if (!mounted) return;
    setState(() {
      _messages = history.isEmpty ? const [_welcome] : history;
      _loadingHistory = false;
    });
    _scrollToBottom();
  }

  Future<void> _clearHistory() async {
    await AssistantService.clearHistory();
    if (!mounted) return;
    setState(() => _messages = const [_welcome]);
  }

  Future<void> _send([String? suggestedText]) async {
    final text = (suggestedText ?? _inputController.text).trim();
    if (text.isEmpty || _sending) return;

    _inputController.clear();
    final updated = [
      ..._messages.where((message) => message != _welcome),
      AssistantMessage(role: 'user', content: text),
    ];
    setState(() {
      _messages = updated;
      _sending = true;
    });
    await AssistantService.saveHistory(updated);
    _scrollToBottom();

    try {
      final reply = await AssistantService.ask(
        messages: updated,
        context: widget.lessonContext,
      );
      if (!mounted) return;
      setState(() {
        _messages = [
          ...updated,
          AssistantMessage(role: 'assistant', content: reply),
        ];
      });
      await AssistantService.saveHistory(_messages);
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final hasLessonContext = widget.lessonContext?.trim().isNotEmpty ?? false;

    return Scaffold(
      appBar: JisrAppBar(
        title: 'نور — المساعد الذكي',
        actions: [
          IconButton(
            tooltip: 'مسح المحادثة',
            onPressed: _sending ? null : _clearHistory,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: c.tintYellow,
              child: Row(
                children: [
                  const PetAvatar(size: 58),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasLessonContext
                          ? 'نور يعرف الدرس المفتوح ويمكنه شرحه بطريقة أبسط.'
                          : 'رفيق تعليمي ذكي — لا تشارك معلومات شخصية.',
                      style: TextStyle(
                        color: c.onTint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loadingHistory)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
            if (!_loadingHistory && _messages.length <= 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (hasLessonContext)
                      _SuggestionChip(
                        text: 'اشرح هذا الدرس ببساطة',
                        onTap: _send,
                      ),
                    _SuggestionChip(
                      text: 'اقترح نشاطاً تعليمياً',
                      onTap: _send,
                    ),
                    _SuggestionChip(
                      text: 'كيف أستخدم التطبيق؟',
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك لنور...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'إرسال',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
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
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.tealDeep : c.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: c.line),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : c.body,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: JisrColors.of(context).card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: JisrColors.of(context).line),
        ),
        child: const SizedBox(
          width: 38,
          child: LinearProgressIndicator(minHeight: 3),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ActionChip(
        avatar: const Icon(Icons.auto_awesome, size: 18),
        label: Text(text),
        onPressed: () => onTap(text),
      ),
    );
  }
}
