import '../utils/presentation_text.dart';
// lib/screens/chats_screen.dart
import 'package:flutter/material.dart';
import '../widgets/teacher_navigation_bar.dart';
import '../app_icons.dart';
import '../features/communication/data/conversation_repository.dart';
import '../features/communication/presentation/communication_list_controller.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'specialist/specialist_screen.dart';
import 'case_discussion/case_discussion_screen.dart';
import 'learning_support_requests/learning_support_requests_screen.dart';
import 'chat_screen.dart';
part 'chats_screen_view.dart';
part 'chats_screen_s15.dart';
part 'chats_user_picker_s19.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _repository = ConversationRepository();
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

    if (await _viewerRole == 'specialist') {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => SpecialistContactPickerDialog(
          users: users, onSelect: selectUser,
        ),
      );
    } else {
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _UserPickerSheet(
          users: users, onSelect: selectUser,
        ),
      );
    }
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
      if (snapshot.data == 'specialist') return _buildS15(context);
      return buildView(context);
    },
  );
}

class _UserPickerSheet extends StatelessWidget {
  final List users;
  final void Function(Map user) onSelect;

  const _UserPickerSheet({required this.users, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 60, 12, 12),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.users,
                  color: AppColors.brandBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
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
                  final color = AppColors.kidPalette[
                      i % AppColors.kidPalette.length];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: c.card,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: c.line),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => onSelect(user),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .14),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  PresentationText.initial(userName, trim: true, fallback: '؟'),
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: c.heading,
                                      ),
                                    ),
                                    if (userEmail.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        userEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: c.muted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_back_rounded,
                                size: 19,
                                color: c.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
