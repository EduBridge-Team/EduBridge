part of 'chats_screen.dart';

extension _ChatsScreenStateView on _ChatsScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'المحادثات'),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        backgroundColor: AppColors.brandBlue,
        child: const Icon(AppIcons.add, color: Colors.white),
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.chat, size: 72, color: c.muted),
                            const SizedBox(height: 16),
                            Text('لا توجد محادثات بعد',
                                style: TextStyle(color: c.muted)),
                            const SizedBox(height: 8),
                            Text('اضغط + لبدء محادثة جديدة',
                                style: TextStyle(color: c.muted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.kidPalette[
                                    i % AppColors.kidPalette.length],
                                child: Text(
                                  _initial(otherName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                otherName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: c.heading,
                                ),
                              ),
                              subtitle: Text(
                                lastMsg.isNotEmpty
                                    ? lastMsg
                                    : 'لا توجد رسائل بعد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: c.muted),
                              ),
                              trailing: lastDate != null
                                  ? Text(
                                      '${lastDate.day}/${lastDate.month}/${lastDate.year}',
                                      style: TextStyle(
                                          fontSize: 11, color: c.muted),
                                    )
                                  : null,
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
                            ),
                          );
                        },
                      ),
      ),
    );
  
  }
}
