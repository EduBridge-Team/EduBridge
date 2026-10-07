import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'assistant_screen.dart';

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

    return _StudentNoorData(context: context, actions: actions);
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

  @override
  Widget build(BuildContext context) {
    final colors = JisrColors.of(context);
    return FutureBuilder<_StudentNoorData>(
      future: _contextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final message = snapshot.error.toString().replaceFirst('Exception: ', '');
          return Scaffold(
            appBar: AppBar(title: const Text('نور')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(() => _contextFuture = _loadContext()),
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
          appBar: AppBar(
            title: Text('نور • ${widget.childName}'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'ملخص نور الذكي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'هذه اقتراحات تعليمية مبنية على بيانات EduBridge المتاحة للطالب. لا تمثل تشخيصاً طبياً أو نفسياً، ولا يتم تنفيذ أي إجراء تلقائياً.',
                      style: TextStyle(color: Colors.white, height: 1.55),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (data.actions.isNotEmpty) ...[
                Text(
                  'الخطوات التالية المقترحة',
                  style: TextStyle(
                    color: colors.heading,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                for (final action in data.actions) ...[
                  _ActionCard(
                    action: action,
                    onAsk: () => _openChat(data, action: action),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 6),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _openChat(data),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text(
                    'اسأل نور عن هذا الطالب',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
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
    final c = JisrColors.of(context);
    final priorityColor = switch (action.priority) {
      'high' => AppColors.red,
      'medium' => AppColors.orangeDeep,
      _ => AppColors.brandTealDeep,
    };
    final priorityLabel = switch (action.priority) {
      'high' => 'أولوية عالية',
      'medium' => 'أولوية متوسطة',
      _ => 'اقتراح متابعة',
    };

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  action.title,
                  style: TextStyle(
                    color: c.heading,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (action.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              action.reason,
              style: TextStyle(color: c.body, height: 1.5, fontSize: 13),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onAsk,
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: const Text('ناقشها مع نور'),
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

  const _StudentNoorData({required this.context, required this.actions});
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
