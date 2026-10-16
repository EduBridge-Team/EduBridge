// S12: specialist-only Noor assistant layout matching the supplied Figma reference.
// The shared conversation, message persistence, speech and image controls are reused.
part of 'assistant_screen.dart';

extension _AssistantS12 on _AssistantScreenState {
  static const Color _s12Blue = Color(0xFF1C68C5);
  static const Color _s12Teal = Color(0xFF00AABF);
  static const Color _s12Ink = Color(0xFF15334E);
  static const Color _s12Line = Color(0xFFD7E7F3);

  Widget _buildSpecialistS12(BuildContext context) {
    final showSuggestions = !_sending &&
        _visibleSuggestions.isNotEmpty &&
        MediaQuery.viewInsetsOf(context).bottom == 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        toolbarHeight: 116,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 5,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
          child: Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1DB7C7), Color(0xFF1765C2)],
                ),
              ),
            ),
            Positioned(
              left: -55,
              bottom: -86,
              child: IgnorePointer(
                child: Container(
                  width: 166,
                  height: 166,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 12,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -16,
              bottom: -83,
              child: IgnorePointer(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 10,
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
        leading: IconButton(
          tooltip: 'رجوع',
          onPressed: () => Navigator.maybePop(context),
          icon: const CircleAvatar(
            radius: 21,
            backgroundColor: Color(0x33FFFFFF),
            // Keep the visual arrow pointing right, as in the S12 reference,
            // without changing the surrounding Arabic RTL layout.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 23),
            ),
          ),
        ),
        title: const Text(
          'نور — المساعد الذكي',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'مسح المحادثة',
            onPressed: _sending ? null : _clearHistory,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 23, color: Colors.white),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _s12ContextBanner(),
            if (_loadingHistory)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                  itemCount: _messages.length + (_sending ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return Semantics(
                        liveRegion: true,
                        label: 'نور يكتب الرد',
                        child: _TypingBubble(),
                      );
                    }
                    final message = _messages[index];
                    final showActions = message.role == 'assistant' &&
                        message != _AssistantScreenState._welcome;
                    final lastReply = showActions &&
                        index == _messages.length - 1 && !_sending;
                    return Semantics(
                      container: true,
                      label: message.isUser ? 'رسالة المستخدم' : 'رد نور',
                      child: _MessageBubble(
                        message: message,
                        showActions: showActions,
                        isLastAssistant: lastReply,
                        feedback: _responseFeedback[index],
                        onCopy: showActions ? () => _copyResponse(index) : null,
                        onReadAloud: showActions
                            ? () => _toggleReadAloud(index) : null,
                        isSpeaking: _speakingIndex == index,
                        onRegenerate: lastReply ? _regenerateLastResponse : null,
                        onFeedback: showActions
                            ? (helpful) => _rateResponse(index, helpful)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            if (!_loadingHistory && showSuggestions) _s12Suggestions(),
            if (!_loadingHistory && !_sending && _hasConversation &&
                _navigationActions.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
                child: Row(
                  children: _navigationActions.map(
                    (action) => _NavigationActionChip(
                      action: action,
                      onTap: _openNavigationAction,
                    ),
                  ).toList(growable: false),
                ),
              ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('صورة محددة: ${_selectedImage!.name}',
                        overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      tooltip: 'إزالة الصورة',
                      onPressed: _sending ? null : _removeSelectedImage,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            _s12Composer(),
          ],
        ),
      ),
    );
  }

  Widget _s12ContextBanner() {
    final hasLessonContext = widget.lessonContext?.trim().isNotEmpty ?? false;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF2F6),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          // Reuse the approved Noor character, shared with the assistant
          // launcher, instead of a generic smile emoji/icon.
          const SizedBox(
            width: 52,
            height: 52,
            child: PetAvatar(size: 52),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              hasLessonContext
                  ? 'نور يعرف الدرس المفتوح ودورك داخل EduBridge ويمكنه شرحه بطريقة أبسط.'
                  : 'نور يراعي دورك داخل EduBridge ويمكنه مساعدتك في تبسيط الدروس والمتابعة.',
              textAlign: TextAlign.start,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: _s12Ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _s12Suggestions() {
    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 218),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final suggestion in _visibleSuggestions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _send(suggestion),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: Text(
                        suggestion,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _s12Teal,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: _s12Teal, width: 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 9,
                        ),
                        minimumSize: const Size(0, 42),
                        shape: const StadiumBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _s12Composer() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _s12Line),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B14456C),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_sending,
              minLines: 1,
              maxLines: 3,
              maxLength: 2000,
              textDirection: TextDirection.rtl,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'اكتب سؤالك لنور...',
                hintStyle: TextStyle(color: Color(0xFF7893AA), fontSize: 14),
                isDense: true,
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                counterText: '',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'خيارات السؤال',
            enabled: !_sending,
            icon: Icon(
              _listening ? Icons.mic_rounded : Icons.more_horiz_rounded,
              color: _listening ? _s12Teal : const Color(0xFF6A86A1),
              size: 20,
            ),
            onSelected: (value) {
              if (value == 'picture') _chooseImage();
              if (value == 'speech') _toggleDictation();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'picture',
                child: Text('إرفاق صورة تعليمية'),
              ),
              PopupMenuItem(
                value: 'speech',
                child: Text(_listening
                    ? 'إيقاف الإملاء الصوتي' : 'إملاء السؤال صوتيًا'),
              ),
            ],
          ),
          IconButton.filled(
            tooltip: 'إرسال',
            onPressed: _sending ? null : () => _send(),
            icon: const Icon(Icons.mark_email_read_outlined, size: 21),
            style: IconButton.styleFrom(
              backgroundColor: _s12Blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 44),
              maximumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }
}
