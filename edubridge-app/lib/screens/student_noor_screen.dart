import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'assistant_screen.dart';
import 'create_homework_screen.dart';

class StudentNoorScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const StudentNoorScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<StudentNoorScreen> createState() => _StudentNoorScreenState();
}

class _StudentNoorScreenState extends State<StudentNoorScreen> {
  late Future<_StudentNoorData> _contextFuture;
  bool _generatingHomeworkDraft = false;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext();
  }

  Future<_StudentNoorData> _loadContext() async {
    final response = await ApiService.authGet(
      '/assistant/students/${widget.childId}/context',
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? 'تعذّر تحميل سياق الطالب.');
    }

    final promptContext = (data['prompt_context'] ?? '').toString().trim();
    final context = [
      'أنت تتحدث الآن عن الطالب ${widget.childName}.',
      promptContext,
    ].where((value) => value.trim().isNotEmpty).join('\n');

    final actions = (data['recommended_actions'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _StudentNoorAction.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.title.isNotEmpty)
        .take(3)
        .toList(growable: false);
    final role = (await ApiService.getRole() ?? '').trim().toLowerCase();

    return _StudentNoorData(
      context: context,
      actions: actions,
      role: role,
    );
  }

  Future<void> _openChat(_StudentNoorData data, {_StudentNoorAction? action}) async {
    final actionContext = action == null
        ? ''
        : [
            'التوصية الحالية: ${action.title}.',
            if (action.reason.isNotEmpty) 'السبب: ${action.reason}',
            if (action.prompt.isNotEmpty) 'موضوع مقترح للنقاش: ${action.prompt}',
          ].join('\n');
    final context = [data.context, actionContext]
        .where((value) => value.trim().isNotEmpty)
        .join('\n');

    await Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (_) => AssistantScreen(lessonContext: context),
      ),
    );
  }

  Future<void> _createHomeworkDraft() async {
    if (_generatingHomeworkDraft) return;
    setState(() => _generatingHomeworkDraft = true);

    try {
      final response = await ApiService.authPost(
        '/assistant/students/${widget.childId}/draft-homework',
        const {},
      );
      final data = ApiService.decodeMap(response.body);
      if (response.statusCode != 200 || data['draft'] is! Map) {
        throw Exception(
          data['error'] ?? data['message'] ?? 'تعذّر إنشاء مسودة الواجب.',
        );
      }

      final draft = Map<String, dynamic>.from(data['draft'] as Map);
      final title = (draft['title'] ?? '').toString().trim();
      final description = (draft['description'] ?? '').toString().trim();
      final subject = (draft['subject'] ?? '').toString().trim();
      final dueInDays = (draft['due_in_days'] as num?)?.toInt() ?? 7;
      if (title.isEmpty || description.isEmpty) {
        throw Exception('وصلت مسودة غير مكتملة من نور.');
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateHomeworkScreen(
            children: [
              {'id': widget.childId, 'name': widget.childName},
            ],
            initialChildId: widget.childId,
            initialTitle: title,
            initialDescription: description,
            initialSubject: subject.isEmpty ? null : subject,
            initialDueDate: DateTime.now().add(
              Duration(days: dueInDays.clamp(1, 30).toInt()),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingHomeworkDraft = false);
    }
  }

  PreferredSizeWidget _s13AppBar() {
    return BrandAppBar(
      toolbarHeight: 116,
      centerTitle: false,
      titleSpacing: 4,
      leading: IconButton(
        tooltip: 'رجوع',
        onPressed: () => Navigator.maybePop(context),
        icon: const CircleAvatar(
          radius: 21,
          backgroundColor: Color(0x33FFFFFF),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),
      ),
      title: Text(
        'نور • ${widget.childName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _s13SummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF175FB9), Color(0xFF21B9C7)],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ملخص نور الذكي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 17),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'هذه اقتراحات تعليمية مبنية على بيانات EduBridge المتاحة للطالب. لا تمثل تشخيصاً طبياً أو نفسياً، ولا يتم تنفيذ أي إجراء تلقائياً.',
            textAlign: TextAlign.start,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              height: 1.85,
            ),
          ),
        ],
      ),
    );
  }

  Widget _s13AskButton(_StudentNoorData data) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF196AC6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _openChat(data),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
            label: const Text(
              'اسأل نور عن هذا الطفل',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_StudentNoorData>(
      future: _contextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F9FC),
            appBar: _s13AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final message = snapshot.error.toString().replaceFirst('Exception: ', '');
          return Scaffold(
            backgroundColor: const Color(0xFFF5F9FC),
            appBar: _s13AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          setState(() => _contextFuture = _loadContext()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F9FC),
          appBar: _s13AppBar(),
          body: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 22),
            children: [
              _s13SummaryCard(),
              const SizedBox(height: 18),
              const Text(
                'الخطوات التالية المقترحة',
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Color(0xFF112F4A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              if (data.actions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFD8E6F2)),
                  ),
                  child: const Text(
                    'لا توجد خطوات متابعة مقترحة حاليًا.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF637F98)),
                  ),
                ),
              for (final action in data.actions) ...[
                _ActionCard(
                  action: action,
                  onAsk: () => _openChat(data, action: action),
                ),
                const SizedBox(height: 10),
              ],
              if (data.role == 'teacher') ...[
                const SizedBox(height: 4),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _generatingHomeworkDraft
                        ? null
                        : _createHomeworkDraft,
                    icon: _generatingHomeworkDraft
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_outlined),
                    label: Text(
                      _generatingHomeworkDraft
                          ? 'نور تجهّز المسودة...'
                          : 'إنشاء مسودة واجب بنور',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ستفتح المسودة في نموذج الواجب لتراجعها وتعدّلها قبل النشر.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF637F98), fontSize: 11.5),
                ),
                const SizedBox(height: 12),
              ],

            ],
          ),
          bottomNavigationBar: _s13AskButton(data),
        );
      },
    );
  }

}

class _ActionCard extends StatelessWidget {
  final _StudentNoorAction action;
  final VoidCallback onAsk;

  const _ActionCard({required this.action, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (action.priority) {
      'high' => const Color(0xFFC4362E),
      'medium' => const Color(0xFFAF680F),
      _ => const Color(0xFF038D98),
    };
    final priorityLabel = switch (action.priority) {
      'high' => 'أولوية عالية',
      'medium' => 'أولوية متوسطة',
      _ => 'اقتراح متابعة',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 18, 15, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD8E6F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x071A5C8E),
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  action.title,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFF112F4A),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (action.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              action.reason,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: Color(0xFF637F98),
                fontSize: 13,
                height: 2,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAsk,
              icon: const Icon(Icons.auto_awesome_rounded, size: 15),
              label: const Text(
                'ناقشها مع نور',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF196AC6),
                padding: const EdgeInsets.symmetric(horizontal: 0),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _StudentNoorData {
  final String context;
  final List<_StudentNoorAction> actions;
  final String role;

  const _StudentNoorData({
    required this.context,
    required this.actions,
    required this.role,
  });
}

class _StudentNoorAction {
  final String priority;
  final String title;
  final String reason;
  final String prompt;

  const _StudentNoorAction({
    required this.priority,
    required this.title,
    required this.reason,
    required this.prompt,
  });

  factory _StudentNoorAction.fromMap(Map<String, dynamic> map) {
    return _StudentNoorAction(
      priority: (map['priority'] ?? 'low').toString().trim().toLowerCase(),
      title: (map['title'] ?? '').toString().trim(),
      reason: (map['reason'] ?? '').toString().trim(),
      prompt: (map['suggested_prompt'] ?? '').toString().trim(),
    );
  }
}
