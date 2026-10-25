import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../features/case_discussions/data/case_creation_repository.dart';
import '../../features/case_discussions/domain/case_team_policy.dart';
import 'case_discussion_s21.dart';

class NewCaseDiscussionSheet extends StatefulWidget {
  const NewCaseDiscussionSheet({super.key});

  @override
  State<NewCaseDiscussionSheet> createState() => _NewCaseDiscussionSheetState();
}

class _NewCaseDiscussionSheetState extends State<NewCaseDiscussionSheet> {
  final _repository = CaseCreationRepository();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<Map<String, dynamic>> _myChildren = []; // الأطفال الذين أتابعهم فقط
  List<Map<String, dynamic>> _allUsers = []; // كل المعلّمين والمختصين
  List<Map<String, dynamic>> _childTeam = []; // فريق الطفل المختار

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
      final directory = await _repository.loadDirectory();
      final meId = directory.currentUserId;
      if (!mounted) return;
      setState(() {
        _myChildren = directory.children;
        _allUsers = directory.users;
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

    final team = CaseTeamPolicy.teamFor(child, _allUsers);

    setState(() {
      _selectedChildId = childId;
      _selectedParticipants.clear();
      if (_myUserId != null) {
        _selectedParticipants.add(_myUserId!); // أنا مشارك دائماً
      }
      _childTeam = team;
    });
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
      final created = await _repository.create(
        childId: _selectedChildId!,
        topic: _topicCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        participantIds: participants.toList(),
      );
      if (!mounted) return;
      if (!created) {
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
  Widget build(BuildContext context) => NewCaseStudyDialogS21(
    children: _myChildren,
    team: _childTeam,
    selectedChildId: _selectedChildId,
    selectedParticipants: _selectedParticipants,
    myUserId: _myUserId,
    topicController: _topicCtrl,
    descriptionController: _descCtrl,
    loading: _loading,
    saving: _saving,
    error: _error,
    onChildSelected: _onChildSelected,
    onParticipantToggled: _toggleS21Participant,
    onSave: _save,
    onCancel: () => Navigator.of(context).pop(),
    onRetry: _load,
  );
}
