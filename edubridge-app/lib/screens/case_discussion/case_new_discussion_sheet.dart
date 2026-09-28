// lib/screens/case_discussion/case_new_discussion_sheet.dart
part of 'case_discussion_screen.dart';

class _NewDiscussionSheet extends StatefulWidget {
  const _NewDiscussionSheet();

  @override
  State<_NewDiscussionSheet> createState() => _NewDiscussionSheetState();
}

class _NewDiscussionSheetState extends State<_NewDiscussionSheet> {
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List _myChildren = []; // الأطفال الذين أتابعهم فقط
  List _allUsers = []; // كل المعلّمين والمختصين
  List _childTeam = []; // فريق الطفل المختار

  int? _selectedChildId;
  final Set<int> _selectedParticipants = {};
  int? _myUserId;

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

  // ═══════════════════════════════════════════════════════
  //  تحميل البيانات — مع فلترة الأطفال حسب متابعة المستخدم
  // ═══════════════════════════════════════════════════════
  Future<void> _load() async {
    try {
      final role = await ApiService.getRole();
      final meId = await ApiService.getUserId();

      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/users'),
      ]);

      if (!mounted) return;

      final allChildren =
          ApiService.extractList(responses[0].body, 'children');
      final allUsers = ApiService.extractList(responses[1].body, 'users');

      // ✅ فلترة الأطفال: فقط الذين أتابعهم
      final myChildren = allChildren.where((c) {
        if (role == 'teacher') {
          return c['assigned_teacher_id']?.toString() == meId?.toString();
        }
        if (role == 'specialist') {
          return _specialistIdsOf(c).contains(meId);
        }
        if (role == 'admin') return true; // الأدمن يرى الكل
        return false;
      }).toList();

      if (!mounted) return;
      setState(() {
        _myChildren = myChildren;
        _allUsers = allUsers
            .where((u) =>
                u['role'] == 'teacher' || u['role'] == 'specialist')
            .toList();
        _myUserId = meId;
        if (meId != null) _selectedParticipants.add(meId);
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

  // ═══════════════════════════════════════════════════════
  //  عند اختيار طفل → فلترة الفريق
  // ═══════════════════════════════════════════════════════
  void _onChildSelected(int? childId) {
    if (childId == null) return;

    final child = _myChildren.firstWhere(
      (c) => c['id'] == childId,
      orElse: () => <String, dynamic>{},
    );

    final teamIds = _teamIdsOf(child);
    final team = _allUsers
        .where((u) =>
            teamIds.contains(u['id']) &&
            (u['role'] == 'teacher' || u['role'] == 'specialist'))
        .toList();

    setState(() {
      _selectedChildId = childId;
      _selectedParticipants
        ..clear()
        ..add(_myUserId!); // أنا مشارك دائماً
      _childTeam = team;
    });
  }

  // ═══════════════════════════════════════════════════════
  //  استخراج مُعرّفات المختصين من بيانات الطفل
  // ═══════════════════════════════════════════════════════
  Set<int> _specialistIdsOf(Map child) {
    final ids = <int>{};
    void add(dynamic v) {
      if (v is int) ids.add(v);
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) ids.add(p);
      }
    }

    add(child['specialist_id']);
    add(child['assigned_specialist_id']);
    for (final key in ['specialist_ids', 'assigned_specialist_ids']) {
      final list = child[key];
      if (list is List) list.forEach(add);
    }
    return ids;
  }

  // ═══════════════════════════════════════════════════════
  //  استخراج فريق الطفل (معلم + مختصين)
  // ═══════════════════════════════════════════════════════
  Set<int> _teamIdsOf(Map child) {
    final ids = <int>{};
    void add(dynamic v) {
      if (v is int) ids.add(v);
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) ids.add(p);
      }
    }

    add(child['assigned_teacher_id']);
    add(child['specialist_id']);
    add(child['assigned_specialist_id']);

    for (final key in [
      'teacher_ids',
      'assigned_teacher_ids',
      'specialist_ids',
      'assigned_specialist_ids',
    ]) {
      final list = child[key];
      if (list is List) list.forEach(add);
    }
    return ids;
  }

  // ═══════════════════════════════════════════════════════
  //  حفظ
  // ═══════════════════════════════════════════════════════
  Future<void> _save() async {
    if (_selectedChildId == null) {
      setState(() => _error = 'اختر الطفل');
      return;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }

    final participants = Set<int>.from(_selectedParticipants);
    if (_myUserId != null) participants.add(_myUserId!);

    if (participants.length < 2) {
      setState(() => _error = 'اختر مشاركاً واحداً على الأقل من الفريق');
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
        participantIds: participants.toList(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════
  //  Build
  // ═══════════════════════════════════════════════════════
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
                _buildHeader(c),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildChildDropdown(),
                        const SizedBox(height: 12),
                        _buildTopicField(),
                        const SizedBox(height: 12),
                        _buildDescField(),
                        const SizedBox(height: 16),
                        _buildParticipantsHeader(c),
                        const SizedBox(height: 8),
                        ..._buildParticipantTiles(c),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ),
    );
  }

  Widget _buildHeader(JisrColors c) {
    return Row(
      children: [
        const Icon(AppIcons.forum, color: AppColors.brandTeal, size: 28),
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
          icon: const Icon(AppIcons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildChildDropdown() {
    if (_myChildren.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(AppIcons.info, color: AppColors.orangeDeep, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'لا يوجد أطفال معيّنون لك حالياً — لا يمكن بدء دراسة حالة.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedChildId,
      decoration: const InputDecoration(
        labelText: 'الطفل *',
        prefixIcon: Icon(AppIcons.child),
      ),
      items: _myChildren.map<DropdownMenuItem<int>>((ch) {
        return DropdownMenuItem(
          value: ch['id'] as int,
          child: Text(
            '${ch['name']} — ${ch['disability_type'] ?? ''}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _onChildSelected,
    );
  }

  Widget _buildTopicField() {
    return TextField(
      controller: _topicCtrl,
      decoration: const InputDecoration(
        labelText: 'موضوع الدراسة *',
        prefixIcon: Icon(AppIcons.edit),
        hintText: 'مثال: صعوبات التركيز في الحصة',
      ),
    );
  }

  Widget _buildDescField() {
    return TextField(
      controller: _descCtrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'وصف الحالة (اختياري)',
        alignLabelWithHint: true,
        prefixIcon: Icon(AppIcons.info),
      ),
    );
  }

  Widget _buildParticipantsHeader(JisrColors c) {
    return Row(
      children: [
        Text(
          'المشاركون من الفريق (${_selectedParticipants.length}):',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: c.heading,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.brandTeal.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'أنت مشارك تلقائياً',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.brandBlue,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildParticipantTiles(JisrColors c) {
    if (_selectedChildId == null) {
      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.tintTeal,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'اختر طفلاً أولاً لعرض أعضاء فريقه',
            style: TextStyle(fontSize: 13, color: c.onTint),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    if (_childTeam.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'لا يوجد أعضاء آخرون في فريق هذا الطفل حالياً',
            style: TextStyle(fontSize: 13, color: AppColors.orangeDeep),
            textAlign: TextAlign.center,
          ),
        ),
      ];
    }

    return _childTeam.map<Widget>((u) {
      final id = u['id'] as int;
      final name = u['name']?.toString() ?? '';
      final role = u['role']?.toString() ?? '';
      final isMe = id == _myUserId;
      final selected = _selectedParticipants.contains(id);

      final roleIcon =
          role == 'teacher' ? AppIcons.teacher : AppIcons.specialist;
      final roleLabel = role == 'teacher' ? 'معلّم' : 'مختص';

      return CheckboxListTile(
        dense: true,
        value: selected,
        enabled: !isMe,
        secondary: Icon(
          roleIcon,
          size: 22,
          color: isMe ? AppColors.brandBlue : AppColors.muted,
        ),
        title: Text(
          '$roleLabel — $name${isMe ? ' (أنت)' : ''}',
          style: TextStyle(
            fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
            color: isMe ? AppColors.brandBlue : null,
          ),
        ),
        onChanged: isMe
            ? null
            : (v) {
                setState(() {
                  if (v == true) {
                    _selectedParticipants.add(id);
                  } else {
                    _selectedParticipants.remove(id);
                  }
                });
              },
      );
    }).toList();
  }

  Widget _buildActions() {
    return Row(
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
    );
  }
}