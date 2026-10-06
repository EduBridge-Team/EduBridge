part of 'chat_screen.dart';

extension _ChatScreenStateView on _ChatScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: widget.otherUserName,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConversationHeader(c),
          Expanded(child: _buildMessagesArea(c)),
          ChatComposer(
            controller: _messageCtrl,
            isSending: _sending,
            onSend: (text) => _sendMessage(contentOverride: text),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationHeader(JisrColors c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.tintTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.childName.isNotEmpty ? AppIcons.child : AppIcons.chat,
              color: c.infoText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.childName.isNotEmpty
                      ? 'مناقشة حالة: ${widget.childName}'
                      : 'محادثة عامة',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
                if (widget.otherUserRole.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.otherUserRole,
                    style: TextStyle(fontSize: 12.5, color: c.muted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea(JisrColors c) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildErrorState(c);
    if (_messages.isEmpty) return _buildEmptyState(c);
    return _buildMessagesList(c);
  }

  Widget _buildErrorState(JisrColors c) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        const Icon(AppIcons.error, size: 54, color: AppColors.red),
        const SizedBox(height: 14),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.dangerText, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton.icon(
            onPressed: _loadMessages,
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(JisrColors c) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Center(
          child: Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(color: c.tintTeal, shape: BoxShape.circle),
            child: Icon(AppIcons.chat, size: 38, color: c.infoText),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'ابدأ المحادثة',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.heading),
        ),
        const SizedBox(height: 6),
        Text(
          'أرسل أول رسالة وابدأ التواصل مباشرة.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
      ],
    );
  }

  Widget _buildMessagesList(JisrColors c) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg['is_mine'] ?? false;
        final date = msg['created_at'] != null ? DateTime.parse(msg['created_at']) : null;

        return _ChatBubble(
          message: msg['content'] ?? '',
          isMe: isMe,
          senderName: isMe ? 'أنا' : widget.otherUserName,
          time: date != null ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}' : '',
          color: isMe ? AppColors.brandBlue : c.card,
          textColor: isMe ? Colors.white : c.body,
        );
      },
    );
  }
}
