// Specialist-only S16 chat detail, matching the supplied Figma screen.
// Uses the existing message repository and shared accessible composer.
part of 'chat_screen.dart';

extension _S16SpecialistChat on _ChatScreenState {
  static const _blue = Color(0xFF1C6BC6);
  static const _ink = Color(0xFF15334E);
  static const _muted = Color(0xFF6D879F);
  static const _edge = Color(0xFFD8E7F1);

  String _s16RoleLabel(String role) {
    switch (role.toLowerCase().trim()) {
      case 'parent':
      case 'guardian':
        return context.l10n.parentLabel;
      case 'specialist':
        return context.l10n.specialistLabel;
      case 'teacher':
        return context.l10n.teacherLabel;
      case 'admin':
        return context.l10n.administratorLabel;
      default:
        return role;
    }
  }

  PreferredSizeWidget _s16AppBar() {
    return BrandAppBar(
      toolbarHeight: 116,
      titleSpacing: 4,
      centerTitle: false,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: () => Navigator.maybePop(context),
        icon: CircleAvatar(
          radius: 22,
          backgroundColor: Color(0x33FFFFFF),
          child: Directionality(
            textDirection: Directionality.of(context),
            child: Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 23),
          ),
        ),
      ),
      title: Text(
        widget.otherUserName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 21, color: Colors.white, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: context.l10n.refreshConversation,
          onPressed: _loading ? null : _loadMessages,
          icon: const Icon(Icons.refresh_rounded,
            color: Colors.white, size: 25),
        ),
        const SizedBox(width: 5),
      ],
    );
  }

  Widget _s16ConversationHeader() {
    final subject = widget.childName.trim();
    final label = subject.isEmpty
        ? context.l10n.generalConversation
        : context.l10n.caseDiscussionSubject(subject);
    final role = _s16RoleLabel(widget.otherUserRole);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      padding: const EdgeInsets.fromLTRB(15, 16, 14, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _edge),
        boxShadow: const [
          BoxShadow(color: Color(0x08154C80),
            blurRadius: 9, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 51, height: 51,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF6F8),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF05A8B9),
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.65,
                  ),
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    role,
                    style: const TextStyle(
                      color: _muted, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _s16EmptyChat() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 23, 18, 20),
      children: [
        Center(
          child: Container(
            width: 132, height: 132,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD8F3F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: _blue, size: 48,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.startConversation,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ink, fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.startConversationDescription,
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  Widget _s16MessagesArea(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildErrorState(c);
    }
    if (_messages.isEmpty) {
      return _s16EmptyChat();
    }
    return _buildMessagesList(c);
  }

  Widget _buildS16(BuildContext context) {
    final c = JisrColors.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: _s16AppBar(),
      body: SafeArea(
        top: false,
        child: Column(children: [
          _s16ConversationHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadMessages,
              child: _s16MessagesArea(c),
            ),
          ),
          ChatComposer(
            controller: _messageCtrl,
            isSending: _sending,
            onSend: (text) => _sendMessage(contentOverride: text),
          ),
        ]),
      ),
    );
  }
}
