part of 'chat_screen.dart';

extension _ChatScreenStateView on _ChatScreenState {
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
          time: date != null ? PresentationText.clock(date) : '',
          color: isMe ? AppColors.brandBlue : c.card,
          textColor: isMe ? Colors.white : c.body,
        );
      },
    );
  }
}
