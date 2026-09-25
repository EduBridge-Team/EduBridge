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
  int? _selectedChildId;
  List _children = [];
  final Set<int> _selectedParticipants = {};
  List _availableParticipants = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int? _myUserId;

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
      final responses = await Future.wait([
        ApiService.authGet('/children'),
        ApiService.authGet('/users'),
      ]);

      if (!mounted) return;

      final children = ApiService.extractList(responses[0].body, 'children');
      final users = ApiService.extractList(responses[1].body, 'users');

      final meId = await ApiService.getUserId();

      if (!mounted) return;

      setState(() {
        _children = children;
        _availableParticipants = users
            .where((u) =>
                u['role'] == 'teacher' || u['role'] == 'specialist')
            .toList();
        _myUserId = meId;

        if (meId != null) {
          _selectedParticipants.add(meId);
        }
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

  Future<void> _save() async {
    if (_selectedChildId == null) {
      setState(() => _error = 'اختر الطفل');
      return;
    }
    if (_topicCtrl.text.trim().isEmpty) {
      setState(() => _error = 'العنوان مطلوب');
      return;
    }

    final participantIds = Set<int>.from(_selectedParticipants);
    if (_myUserId != null) participantIds.add(_myUserId!);

    if (participantIds.isEmpty) {
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
        participantIds: participantIds.toList(),
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
    return DropdownButtonFormField<int>(
      initialValue: _selectedChildId,
      decoration: const InputDecoration(
        labelText: 'الطفل *',
        prefixIcon: Icon(AppIcons.child),
      ),
      items: _children.map<DropdownMenuItem<int>>((ch) {
        return DropdownMenuItem(
          value: ch['id'] as int,
          child: Text('${ch['name']} — ${ch['disability_type'] ?? ''}'),
        );
      }).toList(),
      onChanged: (v) => setState(() => _selectedChildId = v),
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
          'المشاركون (${_selectedParticipants.length}):',
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
    return _availableParticipants.map<Widget>((u) {
      final id = u['id'] as int;
      final name = u['name']?.toString() ?? '';
      final role = u['role']?.toString() ?? '';
      final isMe = id == _myUserId;
      final selected = _selectedParticipants.contains(id);

      final roleIcon = role == 'teacher' ? AppIcons.teacher : AppIcons.specialist;
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