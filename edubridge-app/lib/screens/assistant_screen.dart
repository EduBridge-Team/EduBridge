// lib/screens/assistant_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/assistant_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import '../widgets/pet_avatar.dart';
part 'assistant_screen_view.dart';

String _cleanAssistantText(String value) {
  final lines = value.replaceAll('\r\n', '\n').split('\n');
  final cleaned = <String>[];

  for (var line in lines) {
    var current = line.trimRight();
    current = current.replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '');
    current = current.replaceFirst(RegExp(r'^\s*[-*+]\s+'), '• ');
    current = current.replaceFirst(RegExp(r'^\s*\d+[.)]\s+'), '• ');
    current = current.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '');

    if (RegExp(r'^\s*[-_:| ]{3,}\s*$').hasMatch(current)) continue;

    if (current.contains('|')) {
      final cells = current
          .split('|')
          .map((cell) => cell.trim())
          .where((cell) => cell.isNotEmpty)
          .toList();
      if (cells.isNotEmpty) current = cells.join(' — ');
    }

    if (current.isEmpty && cleaned.isNotEmpty && cleaned.last.isEmpty) continue;
    cleaned.add(current);
  }

  return cleaned.join('\n').trim();
}

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
        'مرحباً! أنا نور\nأستطيع تبسيط الدروس والإجابة عن أسئلتك. كيف أساعدك؟',
  );

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  List<AssistantMessage> _messages = const [_welcome];
  bool _loadingHistory = true;
  bool _sending = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    assistantScreenVisible.value = true;
    _loadContext();
  }

  @override
  void dispose() {
    assistantScreenVisible.value = false;
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContext() async {
    final history = await AssistantService.loadHistory();
    final role = await ApiService.getRole();
    if (!mounted) return;

    setState(() {
      _messages = history.isEmpty ? const [_welcome] : history;
      _role = role;
      _loadingHistory = false;
    });
    _scrollToBottom();
  }

  List<String> get _suggestions {
    final hasLessonContext = widget.lessonContext?.trim().isNotEmpty ?? false;
    final items = <String>[
      if (hasLessonContext) 'اشرح هذا الدرس ببساطة',
      ...switch (_role) {
        'parent' => const [
            'لخّص لي ما يمكنني متابعته اليوم',
            'كيف أساعد طفلي في هذا الدرس؟',
            'اقترح نشاطاً منزلياً قصيراً',
          ],
        'teacher' => const [
            'اقترح طريقة أبسط لشرح الدرس',
            'أنشئ أسئلة قصيرة على هذا الموضوع',
            'ساعدني في صياغة تغذية راجعة تعليمية',
          ],
        'specialist' => const [
            'ساعدني في تجهيز أهداف الجلسة القادمة',
            'لخّص التقدم الموجود في السياق',
            'اقترح نشاطاً تعليمياً مناسباً للمتابعة',
          ],
        _ => const [
            'بسّط لي هذا الموضوع',
            'اقترح نشاطاً تعليمياً',
          ],
      },
    ];

    return items.take(4).toList(growable: false);
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
      final roleContext = _role == null ? '' : 'دور المستخدم داخل التطبيق: $_role.';
      final lessonContext = widget.lessonContext?.trim() ?? '';
      final context = [roleContext, lessonContext]
          .where((value) => value.isNotEmpty)
          .join('\n');

      final reply = await AssistantService.ask(
        messages: updated,
        context: context.isEmpty ? null : context,
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
  Widget build(BuildContext context) => buildView(context);
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isUser = message.isUser;
    final content = isUser ? message.content : _cleanAssistantText(message.content);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brandBlue : c.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: c.line),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            content,
            textAlign: TextAlign.start,
            style: TextStyle(
              color: isUser ? Colors.white : c.body,
              fontSize: 16,
              height: 1.55,
            ),
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
        avatar: const Icon(AppIcons.info, size: 18),
        label: Text(text),
        onPressed: () => onTap(text),
      ),
    );
  }
}
