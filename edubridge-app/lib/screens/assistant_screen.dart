// lib/screens/assistant_screen.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart';
import '../services/assistant_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';
import '../widgets/pet_avatar.dart';
import 'children_screen.dart';
import 'lessons_screen.dart';
import 'chats_screen.dart';
import 'notifications_screen.dart';
part 'assistant_screen_view.dart';
part 'assistant_s12.dart';

const _structuredAssistantHeadings = <String>{
  'Goal', 'Materials', 'Steps', 'Duration', 'Notes', 'Task', 'Hint',
  'Next step', 'Summary', 'Observed strengths', 'Needs follow-up',
  'الهدف',
  'المواد',
  'الخطوات',
  'المدة',
  'ملاحظات',
  'المطلوب',
  'تلميح',
  'الخطوة التالية',
  'ملخص',
  'نقاط قوة ظاهرة',
  'يحتاج متابعة',
};

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

List<_AssistantResponseSection> _parseAssistantSections(String value) {
  final lines = _cleanAssistantText(value).split('\n');
  final sections = <_AssistantResponseSection>[];
  final intro = <String>[];
  String? currentTitle;
  final currentLines = <String>[];

  void flushIntro() {
    final text = intro.where((line) => line.trim().isNotEmpty).join('\n').trim();
    if (text.isNotEmpty) {
      sections.add(_AssistantResponseSection(text: text));
    }
    intro.clear();
  }

  void flushCurrent() {
    if (currentTitle == null) return;
    sections.add(_AssistantResponseSection(
      title: currentTitle,
      text: currentLines.where((line) => line.trim().isNotEmpty).join('\n').trim(),
    ));
    currentTitle = null;
    currentLines.clear();
  }

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final match = RegExp(r'^([^:：]{2,30})\s*[:：]?\s*(.*)$').firstMatch(line);
    final possibleHeading = match?.group(1)?.trim();
    if (possibleHeading != null && _structuredAssistantHeadings.contains(possibleHeading)) {
      flushIntro();
      flushCurrent();
      currentTitle = possibleHeading;
      final rest = match?.group(2)?.trim() ?? '';
      if (rest.isNotEmpty) currentLines.add(rest);
      continue;
    }

    if (currentTitle != null) {
      currentLines.add(line);
    } else {
      intro.add(line);
    }
  }

  flushIntro();
  flushCurrent();
  return sections;
}

// Preserve each stored message's reading direction when the app locale changes.
TextDirection _assistantTextDirection(String text, TextDirection fallback) {
  final firstLetter = RegExp(r'[A-Za-z\u0600-\u06FF]').firstMatch(text)?.group(0);
  if (firstLetter == null) return fallback;
  return RegExp(r'[\u0600-\u06FF]').hasMatch(firstLetter)
      ? TextDirection.rtl : TextDirection.ltr;
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
    content: '',
  );

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  int? _speakingIndex;
  bool _listening = false;
  List<AssistantMessage> _messages = const [_welcome];
  final Map<int, bool> _responseFeedback = {};
  bool _loadingHistory = true;
  bool _sending = false;
  XFile? _selectedImage;
  String? _role;

  @override
  void initState() {
    super.initState();
    assistantScreenVisible.value = true;
    _loadContext();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speakingIndex = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speakingIndex = null);
    });
  }

  @override
  void dispose() {
    assistantScreenVisible.value = false;
    _speech.stop();
    _tts.stop();
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
      if (hasLessonContext) context.l10n.noorExplainCurrentLesson,
      if (!hasLessonContext && _role == 'specialist') context.l10n.noorExplainLesson,
      ...switch (_role) {
        'parent' => [
            context.l10n.noorParentToday,
            context.l10n.noorParentHelp,
            context.l10n.noorHomeActivity,
          ],
        'teacher' => [
            context.l10n.noorSimplerTeaching,
            context.l10n.noorShortQuestions,
            context.l10n.noorFeedbackHelp,
          ],
        'specialist' => [
            context.l10n.noorSessionGoals,
            context.l10n.noorSummarizeProgress,
            context.l10n.noorFollowupActivity,
          ],
        _ => [
            context.l10n.noorSimplifyTopic,
            context.l10n.noorLearningActivity,
          ],
      },
    ];

    return items.take(4).toList(growable: false);
  }

  bool get _hasConversation =>
      _messages.any((message) => message.role == 'user');

  List<String> get _followUpSuggestions {
    final hasLessonContext = widget.lessonContext?.trim().isNotEmpty ?? false;
    final items = <String>[
      context.l10n.noorSimplifyMore,
      context.l10n.noorPracticalExample,
      if (hasLessonContext) context.l10n.noorThreeQuestions,
      ...switch (_role) {
        'parent' => [context.l10n.noorShortFollowup],
        'teacher' => [context.l10n.noorClassActivity],
        'specialist' => [context.l10n.noorNextLearningStep],
        _ => [context.l10n.noorShortExercise],
      },
    ];

    return items.take(4).toList(growable: false);
  }

  List<String> get _visibleSuggestions {
    if (!_hasConversation) return _suggestions;
    if (_messages.isEmpty || _messages.last.role != 'assistant') return const [];
    return _followUpSuggestions;
  }

  List<_NoorNavigationAction> get _navigationActions {
    final lessons = _NoorNavigationAction(
      label: context.l10n.lessons,
      icon: Icons.menu_book_rounded,
      builder: () => const LessonsScreen(),
    );
    final homeworks = _NoorNavigationAction(
      label: context.l10n.homework,
      icon: Icons.assignment_rounded,
      builder: () => const ChildrenScreen(destination: 'homeworks'),
    );
    final progress = _NoorNavigationAction(
      label: context.l10n.noorProgress,
      icon: Icons.trending_up_rounded,
      builder: () => const ChildrenScreen(forProgress: true),
    );
    final weekly = _NoorNavigationAction(
      label: context.l10n.weeklyProgress,
      icon: Icons.calendar_view_week_rounded,
      builder: () => const ChildrenScreen(destination: 'weekly-reports'),
    );
    final chats = _NoorNavigationAction(
      label: context.l10n.conversations,
      icon: Icons.chat_bubble_outline_rounded,
      builder: () => const ChatsScreen(),
    );
    final notifications = _NoorNavigationAction(
      label: context.l10n.notifications,
      icon: Icons.notifications_none_rounded,
      builder: () => const NotificationsScreen(),
    );

    return switch (_role) {
      'parent' => [lessons, homeworks, progress, chats],
      'teacher' => [lessons, homeworks, weekly, chats],
      'specialist' => [lessons, weekly, chats, notifications],
      'admin' => [lessons, homeworks, chats, notifications],
      'institution' || 'ministry' => [lessons, chats, notifications],
      _ => [lessons, notifications],
    };
  }

  String? get _assistantContext {
    final roleContext = _role == null ? '' : 'دور المستخدم داخل التطبيق: $_role.';
    final lessonContext = widget.lessonContext?.trim() ?? '';
    final context = [roleContext, lessonContext]
        .where((value) => value.isNotEmpty)
        .join('\n');
    return context.isEmpty ? null : context;
  }

  Future<String> _requestReply(List<AssistantMessage> messages) {
    return AssistantService.ask(
      messages: messages,
      context: _assistantContext,
    );
  }

  Future<void> _openNavigationAction(_NoorNavigationAction action) async {
    if (_sending) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => action.builder()),
    );
  }

  Future<void> _clearHistory() async {
    await _tts.stop();
    if (mounted) setState(() => _speakingIndex = null);
    await AssistantService.clearHistory();
    if (!mounted) return;
    setState(() {
      _messages = const [_welcome];
      _responseFeedback.clear();
    });
  }

  Future<void> _toggleReadAloud(int index) async {
    if (index < 0 || index >= _messages.length || _messages[index].isUser) return;
    final wasSpeaking = _speakingIndex == index;
    await _tts.stop();
    if (!mounted) return;
    setState(() => _speakingIndex = null);
    if (wasSpeaking) return;
    try {
      await _tts.setLanguage(_assistantTextDirection(
        _messages[index].content, Directionality.of(context)) == TextDirection.rtl
          ? 'ar-SA' : 'en-US');
      await _tts.setSpeechRate(0.45);
      if (!mounted) return;
      setState(() => _speakingIndex = index);
      await _tts.speak(_cleanAssistantText(_messages[index].content));
    } catch (_) {
      if (!mounted) return;
      setState(() => _speakingIndex = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noorReadFailed)),
      );
    }
  }

  Future<void> _copyResponse(int index) async {
    if (index < 0 || index >= _messages.length) return;
    await Clipboard.setData(ClipboardData(text: _messages[index].content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.noorCopied),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  void _rateResponse(int index, bool helpful) {
    setState(() {
      if (_responseFeedback[index] == helpful) {
        _responseFeedback.remove(index);
      } else {
        _responseFeedback[index] = helpful;
      }
    });
  }

  Future<void> _regenerateLastResponse() async {
    if (_sending) return;

    var assistantIndex = -1;
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == 'assistant' && _messages[i] != _welcome) {
        assistantIndex = i;
        break;
      }
    }
    if (assistantIndex < 1) return;

    final base = _messages.sublist(0, assistantIndex);
    if (base.isEmpty || base.last.role != 'user') return;
    final original = List<AssistantMessage>.from(_messages);

    setState(() {
      _messages = base;
      _sending = true;
      _responseFeedback.remove(assistantIndex);
    });
    await AssistantService.saveHistory(base);
    _scrollToBottom();

    try {
      final requestMessages = base
          .where((message) => message != _welcome)
          .toList(growable: false);
      final reply = await _requestReply(requestMessages);
      if (!mounted) return;
      setState(() {
        _messages = [
          ...base,
          AssistantMessage(role: 'assistant', content: reply),
        ];
      });
      await AssistantService.saveHistory(_messages);
    } catch (error) {
      if (!mounted) return;
      setState(() => _messages = original);
      await AssistantService.saveHistory(original);
      if (!mounted) return;
      final message = context.sharedMessage(error.toString().replaceFirst('Exception: ', ''));
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

  void _removeSelectedImage() {
    if (_sending) return;
    setState(() => _selectedImage = null);
  }

  Future<void> _toggleDictation() async {
    if (_sending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
      if (!mounted) return;
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noorSpeechUnavailable)),
        );
        return;
      }
      setState(() => _listening = true);
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(localeId:
          Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'ar_SA'),
        onResult: (result) {
          if (!mounted || !result.finalResult) return;
          final spoken = result.recognizedWords.trim();
          if (spoken.isEmpty) return;
          final existing = _inputController.text.trim();
          final combined = [existing, spoken].where((text) => text.isNotEmpty).join(' ');
          _inputController.value = TextEditingValue(
            text: combined.length > 2000 ? combined.substring(0, 2000) : combined,
            selection: TextSelection.collapsed(offset: combined.length > 2000 ? 2000 : combined.length),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _listening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noorDictationFailed)),
      );
    }
  }

  Future<void> _chooseImage() async {
    if (_sending) return;
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      if (await image.length() > 3 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.noorImageTooLarge)),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _selectedImage = image);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noorImagePickFailed)),
      );
    }
  }

  Future<void> _send([String? suggestedText]) async {
    if (_speakingIndex != null) {
      await _tts.stop();
      if (mounted) setState(() => _speakingIndex = null);
    }
    if (!mounted) return;
    final text = (suggestedText ?? _inputController.text).trim();
    final image = suggestedText == null ? _selectedImage : null;
    if ((text.isEmpty && image == null) || _sending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
    }

    if (!mounted) return;
    _inputController.clear();
    final question = text.isEmpty ? context.l10n.noorExplainImage : text;
    final updated = [
      ..._messages.where((message) => message != _welcome),
      AssistantMessage(role: 'user', content: image == null ? question : context.l10n.noorImageQuestion(question)),
    ];
    setState(() {
      _messages = updated;
      _selectedImage = null;
      _sending = true;
    });
    await AssistantService.saveHistory(updated);
    _scrollToBottom();

    try {
      final reply = image == null
          ? await _requestReply(updated)
          : await AssistantService.analyzeImage(image: image, question: question);
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
      final message = context.sharedMessage(error.toString().replaceFirst('Exception: ', ''));
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
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        return;
      }
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

class _NoorNavigationAction {
  final String label;
  final IconData icon;
  final Widget Function() builder;

  const _NoorNavigationAction({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

class _AssistantResponseSection {
  final String? title;
  final String text;

  const _AssistantResponseSection({this.title, required this.text});

  bool get isStructured => title != null;
}

class _MessageBubble extends StatelessWidget {
  final AssistantMessage message;
  final bool showActions;
  final bool isLastAssistant;
  final bool? feedback;
  final VoidCallback? onCopy;
  final VoidCallback? onReadAloud;
  final bool isSpeaking;
  final VoidCallback? onRegenerate;
  final ValueChanged<bool>? onFeedback;

  const _MessageBubble({
    required this.message,
    this.showActions = false,
    this.isLastAssistant = false,
    this.feedback,
    this.onCopy,
    this.onReadAloud,
    this.isSpeaking = false,
    this.onRegenerate,
    this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isUser = message.isUser;
    final displayContent = message == _AssistantScreenState._welcome
        ? context.l10n.noorWelcome : message.content;
    final sections = isUser
        ? const <_AssistantResponseSection>[]
        : _parseAssistantSections(displayContent);
    final hasStructured = sections.any((section) => section.isStructured);

    final contentWidget = isUser || !hasStructured
        ? Text(
            isUser ? displayContent : _cleanAssistantText(displayContent),
            textAlign: TextAlign.start,
            style: TextStyle(
              color: isUser ? Colors.white : c.body,
              fontSize: 16,
              height: 1.55,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections.map((section) {
              if (!section.isStructured) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    section.text,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: c.body,
                      fontSize: 16,
                      height: 1.55,
                    ),
                  ),
                );
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title!,
                      style: TextStyle(
                        color: c.heading,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (section.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.text,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          color: c.body,
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(growable: false),
          );

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 330),
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
        textDirection: _assistantTextDirection(displayContent, Directionality.of(context)),
        child: contentWidget,
      ),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            bubble,
            if (!isUser && showActions) ...[
              const SizedBox(height: 3),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  _ResponseToolButton(
                    tooltip: context.l10n.noorCopyTooltip,
                    icon: Icons.copy_rounded,
                    label: context.l10n.noorCopy,
                    onPressed: onCopy,
                  ),
                  _ResponseToolButton(
                    tooltip: isSpeaking ? context.l10n.noorStopReading : context.l10n.noorReadReply,
                    icon: isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                    label: isSpeaking ? context.l10n.lessonStopPlayback : context.l10n.listen,
                    onPressed: onReadAloud,
                  ),
                  if (isLastAssistant)
                    _ResponseToolButton(
                      tooltip: context.l10n.noorRegenerateTooltip,
                      icon: Icons.refresh_rounded,
                      label: context.l10n.noorRegenerate,
                      onPressed: onRegenerate,
                    ),
                  _ResponseToolButton(
                    tooltip: context.l10n.noorHelpful,
                    icon: Icons.thumb_up_alt_outlined,
                    active: feedback == true,
                    onPressed: onFeedback == null ? null : () => onFeedback!(true),
                  ),
                  _ResponseToolButton(
                    tooltip: context.l10n.noorNotHelpful,
                    icon: Icons.thumb_down_alt_outlined,
                    active: feedback == false,
                    onPressed: onFeedback == null ? null : () => onFeedback!(false),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResponseToolButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final String? label;
  final bool active;
  final VoidCallback? onPressed;

  const _ResponseToolButton({
    required this.tooltip,
    required this.icon,
    this.label,
    this.active = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Tooltip(message: tooltip, child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 3),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 15),
        label: label == null
            ? const SizedBox.shrink()
            : Text(label!, style: const TextStyle(fontSize: 11)),
        style: TextButton.styleFrom(
          minimumSize: const Size(32, 30),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          foregroundColor: active ? AppColors.brandBlue : c.muted,
          backgroundColor: active ? c.tintTeal : Colors.transparent,
          visualDensity: VisualDensity.compact,
        ),
      ),
    ));
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

class _NavigationActionChip extends StatelessWidget {
  final _NoorNavigationAction action;
  final ValueChanged<_NoorNavigationAction> onTap;

  const _NavigationActionChip({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: ActionChip(
        avatar: Icon(action.icon, size: 18),
        label: Text(context.l10n.noorOpenPage(action.label)),
        onPressed: () => onTap(action),
        ),
      ),
    );
  }
}
