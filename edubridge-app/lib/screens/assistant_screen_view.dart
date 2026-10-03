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
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.tintYellow,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  const PetAvatar(size: 54),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasLessonContext
                          ? 'نور يعرف الدرس المفتوح ودورك داخل EduBridge ويمكنه شرحه بطريقة أبسط.'
                          : 'نور يراعي دورك داخل EduBridge — لا تشارك معلومات شخصية.',
                      style: TextStyle(
                        color: c.onTint,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
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
            if (!_loadingHistory)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: _suggestions
                      .map((text) => _SuggestionChip(text: text, onTap: _send))
                      .toList(growable: false),
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: EdgeInsets.fromLTRB(
                10,
                10,
                10,
                10 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: c.line),
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
                      backgroundColor: AppColors.brandBlue,
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
