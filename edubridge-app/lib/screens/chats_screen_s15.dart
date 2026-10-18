// S15: specialist conversation list aligned to the Figma reference.
// Uses actual API conversations; never invents contacts or unread counts.
part of 'chats_screen.dart';

extension _SpecialistChatsS15 on _ChatsScreenState {
  static const _s15Blue = Color(0xFF1969C6);
  static const _s15Ink = Color(0xFF13314D);
  static const _s15Muted = Color(0xFF56718D);
  static const _s15Line = Color(0xFFD8E7F2);

  PreferredSizeWidget _s15AppBar() {
    return BrandAppBar(
      toolbarHeight: 116,
      titleSpacing: 4,
      centerTitle: false,
      leading: IconButton(
        tooltip: 'رجوع',
        onPressed: () => Navigator.maybePop(context),
        icon: const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0x33FFFFFF),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(Icons.arrow_forward_rounded,
                size: 23, color: Colors.white),
          ),
        ),
      ),
      title: const Text(
        'المحادثات',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 21,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _s15Navigation(JisrColors c) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFF8FA5B5), width: 1.5),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE2EEF9),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? _s15Blue : c.muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? _s15Blue : const Color(0xFF537394),
            ),
          ),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 2,
          onDestinationSelected: (index) {
            final Widget destination;
            switch (index) {
              case 0:
                destination = const SpecialistDashboardScreen();
                break;
              case 1:
                destination = const CaseDiscussionScreen(
                  showBottomNavigation: true,
                );
                break;
              case 2:
                return;
              case 3:
                destination = const LearningSupportRequestsScreen();
                break;
              default:
                return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(builder: (_) => destination),
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'الأطفال',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'دراسات الحالة',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'المحادثات',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'طلبات الدعم',
            ),
          ],
        ),
      ),
    );
  }

  Widget _s15ConversationCard(Map conversation) {
    final id = int.tryParse('${conversation['id'] ?? ''}');
    final otherName = _text(
      conversation['other_user_name'], fallback: 'مستخدم');
    final lastMessage = _text(conversation['last_message']);
    final lastDate = lastMessage.isNotEmpty &&
            conversation['last_message_at'] != null
        ? DateTime.tryParse(conversation['last_message_at'].toString())
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        shadowColor: const Color(0x12195491),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: _s15Line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: id == null ? null : () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: id,
                  otherUserName: otherName,
                  otherUserRole: _text(conversation['other_user_role']),
                  childName: _text(conversation['subject']),
                ),
              ),
            );
            if (mounted) _loadConversations();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFE4EFF9),
                  child: Text(
                    _initial(otherName),
                    style: const TextStyle(
                      color: _s15Blue,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _s15Ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (lastDate != null)
                            Text(
                              '${lastDate.day}/${lastDate.month}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _s15Muted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        lastMessage.isEmpty ? 'لا توجد رسائل بعد' : lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _s15Muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                const Directionality(
                  textDirection: TextDirection.ltr,
                  child: Icon(Icons.arrow_back_rounded,
                      color: _s15Blue, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _s15Body() {
    return RefreshIndicator(
      onRefresh: _refreshConversations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 90),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 92),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.red)),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loadConversations,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          else if (_conversations.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 96),
              child: Center(child: Text(
                'لا توجد محادثات بعد',
                style: TextStyle(
                  fontSize: 15,
                  color: _s15Muted,
                ),
              )),
            )
          else
            for (final item in _conversations)
              if (item is Map) _s15ConversationCard(item),
        ],
      ),
    );
  }

  Widget _buildS15(BuildContext context, {required String? role}) {
    final c = JisrColors.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: _s15AppBar(),
      bottomNavigationBar: role == 'specialist' ? _s15Navigation(c)
          : role == 'teacher' ? const TeacherNavigationBar() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        elevation: 3,
        backgroundColor: _s15Blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 23),
        label: const Text(
          'محادثة جديدة',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      body: _s15Body(),
    );
  }
}
