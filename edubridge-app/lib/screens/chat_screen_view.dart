part of 'chat_screen.dart';

extension _ChatScreenStateView on _ChatScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: '${widget.otherUserName} (${widget.otherUserRole})',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.tintTeal,
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.child, color: AppColors.brandBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.childName.isNotEmpty
                        ? 'مناقشة حالة: ${widget.childName}'
                        : 'محادثة عامة',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.heading,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!,
                                style:
                                    const TextStyle(color: AppColors.red)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('إعادة المحاولة'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(AppIcons.chat, size: 64, color: c.muted),
                                const SizedBox(height: 16),
                                Text('لا توجد رسائل بعد',
                                    style: TextStyle(color: c.muted)),
                                const SizedBox(height: 8),
                                Text('ابدأ المحادثة الآن',
                                    style: TextStyle(
                                        fontSize: 14, color: c.muted)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final msg = _messages[i];
                              final isMe = msg['is_mine'] ?? false;
                              final date = msg['created_at'] != null
                                  ? DateTime.parse(msg['created_at'])
                                  : null;

                              return _ChatBubble(
                                message: msg['content'] ?? '',
                                isMe: isMe,
                                senderName:
                                    isMe ? 'أنا' : widget.otherUserName,
                                time: date != null
                                    ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                                    : '',
                                color: isMe ? AppColors.brandBlue : c.card,
                                textColor: isMe ? Colors.white : c.body,
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: c.card,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.brandBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(AppIcons.send, color: Colors.white),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  
  }
}
