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
          // ═══ شريط معلومات المحادثة ═══
          _buildConversationHeader(c),

          // ═══ الرسائل ═══
          Expanded(child: _buildMessagesArea(c)),

          // ═══ Composer الجديد — يستبدل الصندوق القديم ═══
          ChatComposer(
            controller: _messageCtrl,
            isSending: _sending,
            onSend: (text) => _sendMessage(contentOverride: text),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  شريط المعلومات العلوي
  // ═══════════════════════════════════════════════════════════
  Widget _buildConversationHeader(JisrColors c) {
    return Container(
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
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  منطقة الرسائل (Loading / Error / Empty / List)
  // ═══════════════════════════════════════════════════════════
  Widget _buildMessagesArea(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState();
    }
    if (_messages.isEmpty) {
      return _buildEmptyState(c);
    }
    return _buildMessagesList(c);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: AppColors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMessages,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(JisrColors c) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.chat, size: 64, color: c.muted),
          const SizedBox(height: 16),
          Text(
            'لا توجد رسائل بعد',
            style: TextStyle(color: c.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'ابدأ المحادثة الآن',
            style: TextStyle(fontSize: 14, color: c.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(JisrColors c) {
    return ListView.builder(
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
          senderName: isMe ? 'أنا' : widget.otherUserName,
          time: date != null
              ? '${date.hour}:${date.minute.toString().padLeft(2, '0')}'
              : '',
          color: isMe ? AppColors.brandBlue : c.card,
          textColor: isMe ? Colors.white : c.body,
        );
      },
    );
  }
}