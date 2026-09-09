import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final convs = await ApiService.getConversations();
      setState(() {
        _conversations = convs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'تعذّر تحميل المحادثات';
        _loading = false;
      });
    }
  }

  Future<void> _startNewConversation() async {
    // جلب قائمة المستخدمين (جميع الأدوار) واختيار أحدهم
    final users = await ApiService.getUsers();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserPickerSheet(
        users: users,
        onSelect: (user) async {
          Navigator.pop(context);
          try {
            final conversationId = await ApiService.createConversation(
              user['id'],
              'محادثة مع ${user['name']}',
            );
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: conversationId,
                  otherUserName: user['name'] ?? '',
                  otherUserRole: user['role'] ?? '',
                  childName: '',
                ),
              ),
            ).then((_) => _loadConversations());
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذّر إنشاء المحادثة: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'المحادثات'),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: AppColors.teal,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _conversations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 72, color: c.muted),
                            const SizedBox(height: 16),
                            Text('لا توجد محادثات بعد', style: TextStyle(color: c.muted)),
                            const SizedBox(height: 8),
                            Text('اضغط + لبدء محادثة جديدة', style: TextStyle(color: c.muted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _conversations.length,
                        itemBuilder: (context, i) {
                          final conv = _conversations[i];
                          final otherName = conv['other_user_name'] ?? 'مستخدم';
                          final lastMsg = conv['last_message'] ?? '';
                          final lastDate = conv['last_message_at'] != null
                              ? DateTime.tryParse(conv['last_message_at'])
                              : null;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.kidPalette[i % AppColors.kidPalette.length],
                                child: Text(
                                  otherName.isNotEmpty ? otherName.characters.first : '؟',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(otherName, style: TextStyle(fontWeight: FontWeight.bold, color: c.heading)),
                              subtitle: Text(
                                lastMsg.isNotEmpty ? lastMsg : 'لا توجد رسائل بعد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.muted),
                              ),
                              trailing: lastDate != null
                                  ? Text(
                                      '${lastDate.day}/${lastDate.month}/${lastDate.year}',
                                      style: TextStyle(fontSize: 11, color: c.muted),
                                    )
                                  : null,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: conv['id'],
                                      otherUserName: otherName,
                                      otherUserRole: conv['other_user_role'] ?? '',
                                      childName: conv['subject'] ?? '',
                                    ),
                                  ),
                                );
                                _loadConversations();
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

// شاشة اختيار مستخدم لبدء محادثة
class _UserPickerSheet extends StatelessWidget {
  final List users;
  final void Function(Map user) onSelect;

  const _UserPickerSheet({required this.users, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text('اختر مستخدماً للتواصل',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c.heading)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (users.isEmpty)
            Center(child: Text('لا يوجد مستخدمون متاحون', style: TextStyle(color: c.muted)))
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.kidPalette[i % AppColors.kidPalette.length],
                      child: Text(
                        (user['name'] ?? '؟').characters.first,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(user['name'] ?? ''),
                    subtitle: Text(user['email'] ?? ''),
                    onTap: () => onSelect(user),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}