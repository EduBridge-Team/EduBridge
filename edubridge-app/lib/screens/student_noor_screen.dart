import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
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
  late Future<String> _contextFuture;

  @override
  void initState() {
    super.initState();
    _contextFuture = _loadContext();
  }

  Future<String> _loadContext() async {
    final response = await ApiService.authGet(
      '/assistant/students/${widget.childId}/context',
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? 'تعذّر تحميل سياق الطالب.');
    }
    final context = (data['prompt_context'] ?? '').toString().trim();
    return [
      'أنت تتحدث الآن عن الطالب ${widget.childName}.',
      context,
    ].where((value) => value.trim().isNotEmpty).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
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
        return AssistantScreen(lessonContext: snapshot.data);
      },
    );
  }
}
