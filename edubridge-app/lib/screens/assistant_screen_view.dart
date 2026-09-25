part of 'assistant_screen.dart';

extension _AssistantScreenStateView on _AssistantScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final hasLessonContext = widget.lessonContext?.trim().isNotEmpty ?? false;

    return Scaffold(
      appBar: JisrAppBar(
        title: 'نور — المساعد الذكي',
        actions: [
          IconButton(
            tooltip: 'مسح المحادثة',
            onPressed: _sending ? null : _clearHistory,
            icon: const Icon(AppIcons.delete),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              color: c.tintYellow,
              child: Row(
                children: [
                  const PetAvatar(size: 58),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasLessonContext
                          ? 'نور يعرف الدرس المفتوح ويمكنه شرحه بطريقة أبسط.'
                          : 'رفيق تعليمي ذكي — لا تشارك معلومات شخصية.',
                      style: TextStyle(
                        color: c.onTint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loadingHistory)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const _TypingBubble();
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
              ),
            if (!_loadingHistory && _messages.length <= 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (hasLessonContext)
                      _SuggestionChip(
                        text: 'اشرح هذا الدرس ببساطة',
                        onTap: _send,
                      ),
                    _SuggestionChip(
                      text: 'اقترح نشاطاً تعليمياً',
                      onTap: _send,
                    ),
                    _SuggestionChip(
                      text: 'كيف أستخدم التطبيق؟',
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سؤالك لنور...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'إرسال',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(AppIcons.send),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(52, 52),
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  
  }
}
