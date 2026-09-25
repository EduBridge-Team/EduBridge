// lib/screens/case_discussion/case_discussion_detail.dart
part of 'case_discussion_screen.dart';

class _CaseDiscussionDetail extends StatefulWidget {
  final int discussionId;
  const _CaseDiscussionDetail({required this.discussionId});

  @override
  State<_CaseDiscussionDetail> createState() => _CaseDiscussionDetailState();
}

class _CaseDiscussionDetailState extends State<_CaseDiscussionDetail> {
  CaseDiscussion? _discussion;
  bool _loading = true;
  bool _sending = false;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _refreshTimer;
  CaseMessageType _msgType = CaseMessageType.text;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshSilently(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await ApiService.getCaseDiscussionDetails(widget.discussionId);
    if (!mounted) return;
    setState(() {
      _discussion = data != null ? CaseDiscussion.fromJson(data) : null;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _refreshSilently() async {
    final data = await ApiService.getCaseDiscussionDetails(widget.discussionId);
    if (!mounted || data == null) return;
    final fresh = CaseDiscussion.fromJson(data);
    if (fresh.messages.length != (_discussion?.messages.length ?? 0)) {
      setState(() => _discussion = fresh);
      _scrollToBottom();
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputCtrl.clear();

    try {
      await ApiService.addCaseMessage(
        discussionId: widget.discussionId,
        content: text,
        type: _msgType.name,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر الإرسال: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _resolve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إغلاق دراسة الحالة'),
        content: const Text(
          'هل أنت متأكد من اعتبار هذه الدراسة محلولة؟ لن تُقبل رسائل جديدة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final ok = await ApiService.resolveCaseDiscussion(widget.discussionId);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إغلاق دراسة الحالة'),
          backgroundColor: AppColors.green,
        ),
      );
      _load();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final d = _discussion;

    return Scaffold(
      appBar: JisrAppBar(
        title: d != null ? 'دراسة حالة — ${d.childName}' : 'دراسة حالة',
        actions: [
          if (d != null && d.status != CaseDiscussionStatus.resolved)
            IconButton(
              icon: const Icon(AppIcons.check),
              tooltip: 'إغلاق الدراسة',
              onPressed: _resolve,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text('تعذّر التحميل'))
              : Column(
                  children: [
                    _buildInfoHeader(d, c),
                    Expanded(child: _buildMessages(d, c)),
                    if (d.status != CaseDiscussionStatus.resolved)
                      _buildComposer(c)
                    else
                      _buildResolvedBanner(c),
                  ],
                ),
    );
  }

  Widget _buildInfoHeader(CaseDiscussion d, JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: c.tintTeal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.child, color: AppColors.brandBlue, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.topic,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        )),
                    if (d.disabilityType != null)
                      Text(d.disabilityType!,
                          style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: d.status == CaseDiscussionStatus.resolved
                      ? AppColors.green.withValues(alpha: 0.15)
                      : AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  d.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: d.status == CaseDiscussionStatus.resolved
                        ? AppColors.green
                        : AppColors.orangeDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: d.participants.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      p.role == 'teacher'
                          ? AppIcons.teacher
                          : AppIcons.specialist,
                      size: 12,
                      color: AppColors.brandBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(p.name,
                        style: TextStyle(fontSize: 11, color: c.body)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(CaseDiscussion d, JisrColors c) {
    if (d.messages.isEmpty) {
      return Center(
        child: Text('لا توجد رسائل بعد — ابدأ النقاش',
            style: TextStyle(color: c.muted, fontSize: 14)),
      );
    }
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: d.messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: d.messages[i]),
    );
  }

  Widget _buildComposer(JisrColors c) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('رسالة', CaseMessageType.text, AppIcons.chat),
                const SizedBox(width: 6),
                _typeChip('ملاحظة', CaseMessageType.observation, AppIcons.view),
                const SizedBox(width: 6),
                _typeChip('سؤال', CaseMessageType.question, AppIcons.info),
                const SizedBox(width: 6),
                _typeChip('قرار', CaseMessageType.decision, AppIcons.check),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  enabled: !_sending,
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  minimumSize: const Size(50, 50),
                ),
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, CaseMessageType type, IconData icon) {
    final selected = _msgType == type;
    return ChoiceChip(
      avatar: Icon(icon,
          size: 16, color: selected ? Colors.white : AppColors.brandBlue),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: AppColors.brandBlue,
      labelStyle: TextStyle(
        color: selected ? Colors.white : null,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => _msgType = type),
    );
  }

  Widget _buildResolvedBanner(JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: AppColors.green.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.check, color: AppColors.green),
          const SizedBox(width: 8),
          Text('تم إغلاق هذه الدراسة',
              style:
                  TextStyle(color: c.onTint, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  _MessageBubble — كامل
// ═══════════════════════════════════════════════════════════
class _MessageBubble extends StatelessWidget {
  final CaseMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    Color bgColor;
    Color iconColor;
    String typeLabel;
    IconData typeIcon;

    switch (message.type) {
      case CaseMessageType.observation:
        bgColor = c.tintYellow;
        iconColor = AppColors.orangeDeep;
        typeLabel = 'ملاحظة';
        typeIcon = AppIcons.view;
        break;
      case CaseMessageType.decision:
        bgColor = AppColors.green.withValues(alpha: 0.1);
        iconColor = AppColors.green;
        typeLabel = 'قرار';
        typeIcon = AppIcons.check;
        break;
      case CaseMessageType.question:
        bgColor = c.tintTeal;
        iconColor = AppColors.brandBlue;
        typeLabel = 'سؤال';
        typeIcon = AppIcons.info;
        break;
      default:
        bgColor = c.card;
        iconColor = c.muted;
        typeLabel = '';
        typeIcon = AppIcons.chat;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: iconColor.withValues(alpha: 0.15),
                  child: Icon(typeIcon, size: 14, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                if (typeLabel.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${message.createdAt.hour}:${message.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body),
            ),
          ],
        ),
      ),
    );
  }
}