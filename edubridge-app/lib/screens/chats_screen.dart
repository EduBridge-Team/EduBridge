// lib/screens/chats_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
part 'chats_screen_view.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List _conversations = [];
  bool _loading = true;
  String? _error;

  String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _initial(Object? value) {
    final text = _text(value, fallback: '؟').trim();
    return text.isEmpty ? '؟' : text.characters.first;
  }

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
    List users;
    try {
      users = await ApiService.getConversationUsers();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
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
  Widget build(BuildContext context) => buildView(context);
}

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
              const Icon(AppIcons.users, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'اختر مستخدماً للتواصل',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.heading),
                ),
              ),
              IconButton(
                icon: const Icon(AppIcons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (users.isEmpty)
            Center(
              child: Text('لا يوجد مستخدمون متاحون',
                  style: TextStyle(color: c.muted)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  final userName = (user['name'] ?? '').toString();
                  final userEmail = (user['email'] ?? '').toString();
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.kidPalette[
                          i % AppColors.kidPalette.length],
                      child: Text(
                        userName.trim().isEmpty
                            ? '؟'
                            : userName.trim().characters.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(userName),
                    subtitle: Text(userEmail),
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