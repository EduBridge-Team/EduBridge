import '../utils/presentation_text.dart';
// lib/screens/chats_screen.dart
import 'package:flutter/material.dart';
import '../widgets/teacher_navigation_bar.dart';
import '../features/communication/data/conversation_repository.dart';
import '../features/communication/presentation/communication_list_controller.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'specialist/specialist_screen.dart';
import 'case_discussion/case_discussion_screen.dart';
import 'learning_support_requests/learning_support_requests_screen.dart';
import 'chat_screen.dart';
part 'chats_screen_s15.dart';
part 'chats_user_picker_s19.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, this.repository});

  final ConversationRepository? repository;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  late final _repository = widget.repository ?? ConversationRepository();
  late final Future<String?> _viewerRole = ApiService.getRole();
  late final CommunicationListController _listController;
  List get _conversations => _listController.items;
  bool get _loading => _listController.loading;
  String? get _error => _listController.error;

  void _onListChanged() {
    if (mounted) setState(() {});
  }

  String _text(Object? value, {String fallback = ''}) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _initial(Object? value) =>
      PresentationText.initial(value, trim: true);

  @override
  void initState() {
    super.initState();
    _listController = CommunicationListController(
      load: _repository.loadConversations, errorMessage: 'تعذّر تحميل المحادثات',
    )..addListener(_onListChanged);
    _loadConversations();
  }

  @override
  void dispose() {
    _listController.removeListener(_onListChanged);
    _listController.dispose();
    super.dispose();
  }

  Future<void> _refreshConversations() =>
      _loadConversations(showLoader: false);

  Future<void> _loadConversations({bool showLoader = true}) async {
    await _listController.reload(showLoader: showLoader);
  }

  Future<void> _startNewConversation() async {
    List users;
    try {
      users = await _repository.availableUsers();
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    if (!mounted) return;

    Future<void> selectUser(Map user) async {
      Navigator.of(context).pop();
      try {
        final conversationId = await _repository.create(
          user['id'], 'محادثة مع ${user['name']}',
        );
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: conversationId,
              otherUserName: user['name'] ?? '',
              otherUserRole: user['role'] ?? '',
              childName: '',
            ),
          ),
        );
        if (mounted) _loadConversations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر إنشاء المحادثة: $e')),
        );
      }
    }

    await showDialog<void>(
      context: context,
      builder: (_) => ContactPickerDialog(users: users, onSelect: selectUser),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _viewerRole,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return _buildS15(context, role: snapshot.data);
    },
  );
}
