// lib/screens/case_discussion_screen.dart
// دراسة الحالة — نقاش بين المعلم والمختص بخصوص طفل
import 'dart:async';
import 'package:flutter/material.dart';
import '../model/case_discussion_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CaseDiscussionScreen extends StatefulWidget {
  /// عند عدم تمرير discussionId → نفتح قائمة كل الدراسات
  final int? discussionId;
  final int? filterChildId;

  const CaseDiscussionScreen({
    super.key,
    this.discussionId,
    this.filterChildId,
  });

  @override
  State<CaseDiscussionScreen> createState() => _CaseDiscussionScreenState();
}

class _CaseDiscussionScreenState extends State<CaseDiscussionScreen> {
  @override
  Widget build(BuildContext context) {
    if (widget.discussionId == null) {
      return _CaseDiscussionList(filterChildId: widget.filterChildId);
    }
    return _CaseDiscussionDetail(discussionId: widget.discussionId!);
  }
}

// ═══════════════════════════════════════════════════════════
//  قائمة دراسات الحالة
// ═══════════════════════════════════════════════════════════
class _CaseDiscussionList extends StatefulWidget {
  final int? filterChildId;

  const _CaseDiscussionList({this.filterChildId});

  @override
  State<_CaseDiscussionList> createState() => _CaseDiscussionListState();
}

class _CaseDiscussionListState extends State<_CaseDiscussionList> {
  List<CaseDiscussion> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService.getCaseDiscussions(
        childId: widget.filterChildId,
      );
      if (!mounted) return;
      setState(() {
        _items = raw
            .map((e) => CaseDiscussion.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل دراسات الحالة';
        _loading = false;
      });
    }
  }

  Future<void> _openNewDiscussion() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewDiscussionSheet(),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: '📋 دراسات الحالة',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDiscussion,
        icon: const Icon(Icons.add),
        label: const Text('دراسة جديدة'),
        backgroundColor: AppColors.teal,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _items.isEmpty
                    ? _buildEmpty(c)
                    : _buildList(c),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 12),
            const Text('تعذّر التحميل',
                style: TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );

  Widget _buildEmpty(JisrColors c) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.forum_outlined, size: 80, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دراسات حالة بعد',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: c.muted,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'اضغط + لبدء دراسة حالة جديدة',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          ),
        ],
      );

  Widget _buildList(JisrColors c) {
    final open =
        _items.where((d) => d.status != CaseDiscussionStatus.resolved).toList();
    final resolved =
        _items.where((d) => d.status == CaseDiscussionStatus.resolved).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (open.isNotEmpty) ...[
          _sectionHeader('🔵 نشطة', open.length, AppColors.teal),
          ...open.map((d) => _DiscussionTile(discussion: d)),
          const SizedBox(height: 16),
        ],
        if (resolved.isNotEmpty) ...[
          _sectionHeader('✅ محلولة', resolved.length, AppColors.green),
          ...resolved.map((d) => _DiscussionTile(discussion: d)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final CaseDiscussion discussion;

  const _DiscussionTile({required this.discussion});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isResolved = discussion.status == CaseDiscussionStatus.resolved;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _CaseDiscussionDetail(
                discussionId: discussion.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isResolved
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AppColors.teal.withValues(alpha: 0.15),
                    child: Text(discussion.childAvatar,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          discussion.childName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        Text(
                          discussion.topic,
                          style: TextStyle(fontSize: 13, color: c.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (discussion.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${discussion.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: discussion.participants.take(4).map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${p.emoji} ${p.name}',
                      style: TextStyle(fontSize: 11, color: c.onTint),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  تفاصيل دراسة الحالة (دردشة)
// ═══════════════════════════════════════════════════════════
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
    // تحديث تلقائي كل 10 ثوان
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
    final data =
        await ApiService.getCaseDiscussionDetails(widget.discussionId);
    if (!mounted) return;
    setState(() {
      _discussion =
          data != null ? CaseDiscussion.fromJson(data) : null;
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _refreshSilently() async {
    final data =
        await ApiService.getCaseDiscussionDetails(widget.discussionId);
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
          content: Text('✅ تم إغلاق دراسة الحالة'),
          backgroundColor: Colors.green,
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
        title: d != null ? '📋 ${d.childName}' : 'دراسة حالة',
        actions: [
          if (d != null && d.status != CaseDiscussionStatus.resolved)
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
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
              Text(d.childAvatar, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.topic,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                    if (d.disabilityType != null)
                      Text(
                        d.disabilityType!,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.line),
                ),
                child: Text(
                  '${p.emoji} ${p.name}',
                  style: TextStyle(fontSize: 11, color: c.body),
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
        child: Text(
          'لا توجد رسائل بعد — ابدأ النقاش',
          style: TextStyle(color: c.muted, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(12),
      itemCount: d.messages.length,
      itemBuilder: (context, i) {
        final m = d.messages[i];
        return _MessageBubble(message: m);
      },
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
          // اختيار نوع الرسالة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('رسالة', CaseMessageType.text, Icons.chat_bubble_outline),
                const SizedBox(width: 6),
                _typeChip('ملاحظة', CaseMessageType.observation,
                    Icons.visibility_outlined),
                const SizedBox(width: 6),
                _typeChip('سؤال', CaseMessageType.question, Icons.help_outline),
                const SizedBox(width: 6),
                _typeChip('قرار', CaseMessageType.decision, Icons.gavel),
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
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.teal,
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
                    : const Icon(Icons.send),
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
          size: 16,
          color: selected ? Colors.white : AppColors.tealDeep),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: AppColors.teal,
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
          const Icon(Icons.check_circle, color: AppColors.green),
          const SizedBox(width: 8),
          Text(
            'تم إغلاق هذه الدراسة',
            style: TextStyle(
              color: c.onTint,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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
        typeIcon = Icons.visibility;
        break;
      case CaseMessageType.decision:
        bgColor = AppColors.green.withValues(alpha: 0.1);
        iconColor = AppColors.green;
        typeLabel = 'قرار';
        typeIcon = Icons.gavel;
        break;
      case CaseMessageType.question:
        bgColor = c.tintTeal;
        iconColor = AppColors.tealDeep;
        typeLabel = 'سؤال';
        typeIcon = Icons.help_outline;
        break;
      default:
        bgColor = c.card;
        iconColor = c.muted;
        typeLabel = '';
        typeIcon = Icons.chat_bubble_outline;
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

// ═══════════════════════════════════════════════════════════
//  BottomSheet: دراسة حالة جديدة
// ═══════════════════════════════════════════════════════════
class _NewDiscussionSheet extends StatefulWidget {
  const _NewDiscussionSheet();

  @override
  State<_NewDiscussionSheet> createState() => _NewDiscussionSheetState();
}

class _NewDiscussionSheetState extends State<_NewDiscussionSheet> {
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int? _selectedChildId;
  List _children = [];
  Set<int> _selectedParticipants = {};
  List _availableParticipants = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final childrenRes = await ApiService.authGet('/children');
      final usersRes = await ApiService.authGet('/users');
      final childrenData = childrenRes.statusCode == 200
          ? (childrenRes.body.isNotEmpty
              ? (childrenRes.body.contains('{')
                  ? Map<String, dynamic>.from(
                      (childrenRes.body.isEmpty)
                          ? {}
                          : const {})
                  : const {})
              : const {})
          : const {};

      // استخدام ApiService للحصول على القوائم
      final children = await ApiService.authGet('/children');
      final users = await ApiService.authGet('/users');

      if (!mounted) return;

      final childrenBody = children.body.isNotEmpty
          ? Map<String, dynamic>.from(
              childrenRes.statusCode == 200
                  ? (children.body.contains('{')
                      ? _parseJson(children.body)
                      : {})
                  : {},
            )
          : <String, dynamic>{};

      final usersBody = users.body.isNotEmpty
          ? _parseJson(users.body)
          : <String, dynamic>{};

      setState(() {
        _children = childrenBody['children'] ?? [];
        final allUsers = usersBody['users'] ?? [];
        _availableParticipants = allUsers
            .where((u) =>
                u['role'] == 'teacher' || u['role'] == 'specialist')
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل البيانات';
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      final decoded = body;
      // Simple JSON parse — نستخدم dart:convert
      return Map<String, dynamic>.from(
        (const {}), // placeholder — سيُستبدل بالتحليل الحقيقي
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _save() async {
    if (_selectedChildId == null) {
      setState(() => _error = 'اختر الطفل');
      return;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }
    if (_selectedParticipants.isEmpty) {
      setState(() => _error = 'اختر مشاركاً واحداً على الأقل');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.createCaseDiscussion(
        childId: _selectedChildId!,
        topic: _topicCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        participantIds: _selectedParticipants.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.forum, color: AppColors.teal, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'دراسة حالة جديدة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedChildId,
                          decoration: const InputDecoration(
                            labelText: 'الطفل *',
                            prefixIcon: Icon(Icons.child_care),
                          ),
                          items: _children.map<DropdownMenuItem<int>>((ch) {
                            return DropdownMenuItem(
                              value: ch['id'] as int,
                              child: Text(
                                  '${ch['name']} — ${ch['disability_type'] ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedChildId = v),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _topicCtrl,
                          decoration: const InputDecoration(
                            labelText: 'موضوع الدراسة *',
                            prefixIcon: Icon(Icons.title),
                            hintText: 'مثال: صعوبات التركيز في الحصة',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'وصف الحالة (اختياري)',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'المشاركون (${_selectedParticipants.length}):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: c.heading,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(_availableParticipants.map<Widget>((u) {
                          final id = u['id'] as int;
                          final name = u['name']?.toString() ?? '';
                          final role = u['role']?.toString() ?? '';
                          final roleLabel =
                              role == 'teacher' ? '👨‍🏫 معلّم' : '🧩 مختص';
                          final selected =
                              _selectedParticipants.contains(id);
                          return CheckboxListTile(
                            dense: true,
                            value: selected,
                            title: Text('$roleLabel — $name'),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedParticipants.add(id);
                                } else {
                                  _selectedParticipants.remove(id);
                                }
                              });
                            },
                          );
                        })),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                        ),
                        onPressed: _saving ? null : _save,
                        child: Text(_saving ? '...' : 'إنشاء'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}