part of 'chats_screen.dart';

extension _ChatsScreenStateView on _ChatsScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      bottomNavigationBar: const TeacherNavigationBar(),
      appBar: JisrAppBar(title: 'المحادثات'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(AppIcons.add),
        label: const Text(
          'محادثة جديدة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.red)))
                : _conversations.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 120),
                          Container(
                            width: 84,
                            height: 84,
                            margin: const EdgeInsets.symmetric(horizontal: 105),
                            decoration: BoxDecoration(
                              color: c.tintTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              AppIcons.chat,
                              size: 40,
                              color: AppColors.brandBlue,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'لا توجد محادثات بعد',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ابدأ محادثة مع أحد أعضاء فريق الدعم التعليمي.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: c.muted,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
                        itemCount: _conversations.length,
                        itemBuilder: (context, i) {
                          final conv = _conversations[i];
                          final otherName = _text(
                            conv['other_user_name'],
                            fallback: 'مستخدم',
                          );
                          final lastMsg = _text(conv['last_message']);
                          final lastDate = conv['last_message_at'] != null
                              ? DateTime.tryParse(
                                  conv['last_message_at'].toString(),
                                )
                              : null;
                          final color = AppColors.kidPalette[
                              i % AppColors.kidPalette.length];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: c.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(color: c.line),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversationId: conv['id'],
                                      otherUserName: otherName,
                                      otherUserRole:
                                          conv['other_user_role'] ?? '',
                                      childName: conv['subject'] ?? '',
                                    ),
                                  ),
                                );
                                  _loadConversations();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 54,
                                        height: 54,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: .14),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          _initial(otherName),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    otherName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: c.heading,
                                                    ),
                                                  ),
                                                ),
                                                if (lastDate != null)
                                                  Text(
                                                    '${lastDate.day}/${lastDate.month}',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: c.muted,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              lastMsg.isNotEmpty
                                                  ? lastMsg
                                                  : 'لا توجد رسائل بعد',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                color: c.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
    );
  
  }
}