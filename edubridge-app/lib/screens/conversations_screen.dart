import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

/// قائمة محادثات عامة؛ لا تعتمد على دور المستخدم أو وجود طفل مرتبط به.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final conversations = await ApiService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = conversations;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر تحميل المحادثات';
          _loading = false;
        });
      }
    }
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final otherUser = conversation['other_user'] is Map
        ? Map<String, dynamic>.from(conversation['other_user'])
        : <String, dynamic>{};
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conversation['id'] as int,
          otherUserName: (otherUser['name'] ?? 'مستخدم').toString(),
          otherUserRole: (otherUser['role'] ?? '').toString(),
        ),
      ),
    );
  }

  Future<void> _startConversation() async {
    List<dynamic> users;
    try {
      users = await ApiService.getUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => users.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Text('لا يوجد مستخدمون متاحون للمحادثة'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('اختر مستخدماً لبدء محادثة',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...users.map((user) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text((user['name'] ?? 'مستخدم').toString()),
                      subtitle: Text((user['email'] ?? '').toString()),
                      onTap: () async {
                        final id = int.tryParse('${user['id']}');
                        if (id == null) return;
                        final conversationId =
                            await ApiService.createConversation(
                                id, 'محادثة جديدة');
                        if (!sheetContext.mounted) return;
                        Navigator.pop(sheetContext);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conversationId,
                              otherUserName:
                                  (user['name'] ?? 'مستخدم').toString(),
                              otherUserRole: (user['role'] ?? '').toString(),
                            ),
                          ),
                        );
                      },
                    )),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = JisrColors.of(context);
    return Scaffold(
      appBar: JisrAppBar(
        title: 'المحادثات',
        actions: [
          IconButton(
            onPressed: _startConversation,
            tooltip: 'إنشاء محادثة جديدة',
            icon: const Icon(Icons.add_comment),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startConversation,
        tooltip: 'محادثة جديدة',
        child: const Icon(Icons.add_comment),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _conversations.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 180),
                            Icon(Icons.chat_bubble_outline,
                                size: 64, color: colors.muted),
                            const SizedBox(height: 12),
                            Center(
                              child: Text('لا توجد محادثات بعد',
                                  style: TextStyle(color: colors.muted)),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _conversations.length,
                          itemBuilder: (_, index) {
                            final conversation = Map<String, dynamic>.from(
                                _conversations[index] as Map);
                            final otherUser = conversation['other_user'] is Map
                                ? conversation['other_user'] as Map
                                : const {};
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person)),
                                title: Text(
                                    (otherUser['name'] ?? 'مستخدم').toString()),
                                subtitle: Text(
                                    (conversation['subject'] ?? 'محادثة')
                                        .toString()),
                                onTap: () => _openConversation(conversation),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
