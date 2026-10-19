// lib/screens/case_discussion/case_new_discussion_sheet.dart
part of 'case_discussion_screen.dart';

class _NewDiscussionSheet extends StatefulWidget {
  const _NewDiscussionSheet({this.figmaS21 = false});

  final bool figmaS21;

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
  Object? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role = await ApiService.getRole();
      final meId = await ApiService.getUserId();

      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/users'),
      ]);

      if (!mounted) return;

      if (responses.any((response) => response.statusCode != 200)) {
        throw StateError('Case team data could not be loaded');
      }
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
        _error = SharedUiMessage.caseDataLoadFailed;
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
      _selectedParticipants.clear();
      if (_myUserId != null) {
        _selectedParticipants.add(_myUserId!); // أنا مشارك دائماً
      }
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

  // Keep UI state mutations in the State class, not in an extension.
  void _toggleS21Participant(int id) {
    if (_saving || id == _myUserId) return;
    setState(() {
      if (!_selectedParticipants.add(id)) {
        _selectedParticipants.remove(id);
      }
    });
  }

  // ═══════════════════════════════════════════════════════
  //  حفظ
  // ═══════════════════════════════════════════════════════
  Future<void> _save() async {
    if (_selectedChildId == null) {
      setState(() => _error = SharedUiMessage.caseChooseChild);
      return;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _error = SharedUiMessage.homeworkTitleRequired);
      return;
    }

    final participants = Set<int>.from(_selectedParticipants);
    if (_myUserId != null) participants.add(_myUserId!);

    if (participants.length < 2) {
      setState(() => _error = SharedUiMessage.caseChooseParticipant);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final created = await ApiService.createCaseDiscussion(
        childId: _selectedChildId!,
        topic: _topicCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        participantIds: participants.toList(),
      );
      if (!mounted) return;
      if (created == null) {
        setState(() {
          _error = SharedUiMessage.caseCreateFailed;
          _saving = false;
        });
        return;
      }
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
    if (widget.figmaS21) return _buildS21Dialog();
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 56, 12, 12),
      padding: const EdgeInsets.all(18),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
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
                  Text(context.sharedMessage(_error),
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
            context.l10n.caseNewTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.info, color: AppColors.orangeDeep, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.caseNoAssignedChildrenHint,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: _selectedChildId,
      decoration: InputDecoration(
        labelText: context.l10n.caseChildField,
        prefixIcon: const Icon(AppIcons.child),
      ),
      items: _myChildren.map<DropdownMenuItem<int>>((ch) {
        return DropdownMenuItem(
          value: ch['id'] as int,
          child: Text(
            "${ch['name']} — ${DisabilityDisplay.label(ch['disability_type']?.toString() ?? '', context.l10n)}",
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
      decoration: InputDecoration(
        labelText: context.l10n.caseTopicField,
        prefixIcon: const Icon(AppIcons.edit),
        hintText: context.l10n.caseTopicHint,
      ),
    );
  }

  Widget _buildDescField() {
    return TextField(
      controller: _descCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: context.l10n.caseDescriptionField,
        alignLabelWithHint: true,
        prefixIcon: const Icon(AppIcons.info),
      ),
    );
  }

  Widget _buildParticipantsHeader(JisrColors c) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Text(
          context.l10n.caseTeamCount(_selectedParticipants.length),
          style: TextStyle(
            fontWeight: FontWeight.w800,
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
          child: Text(
            context.l10n.caseAutomaticParticipant,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            context.l10n.caseChooseChildForTeam,
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            context.l10n.caseNoOtherTeam,
            style: const TextStyle(fontSize: 13, color: AppColors.orangeDeep),
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
      final roleLabel = role == 'teacher' ? context.l10n.teacherRole : context.l10n.specialistRole;

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
          isMe ? context.l10n.caseParticipantMe(roleLabel, name) : context.l10n.caseParticipant(roleLabel, name),
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
            child: Text(context.l10n.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '...' : context.l10n.caseCreate),
          ),
        ),
      ],
    );
  }
}