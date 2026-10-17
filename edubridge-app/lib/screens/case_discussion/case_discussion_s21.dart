// Figma S21: centered specialist-only "new case study" dialog.
// All children and team members are supplied by the existing API state.
part of 'case_discussion_screen.dart';

class NewCaseStudyDialogS21 extends StatelessWidget {
  const NewCaseStudyDialogS21({
    super.key,
    required this.children,
    required this.team,
    required this.selectedChildId,
    required this.selectedParticipants,
    required this.myUserId,
    required this.topicController,
    required this.descriptionController,
    required this.loading,
    required this.saving,
    required this.error,
    required this.onChildSelected,
    required this.onParticipantToggled,
    required this.onSave,
    required this.onCancel,
    required this.onRetry,
  });

  final List children;
  final List team;
  final int? selectedChildId;
  final Set<int> selectedParticipants;
  final int? myUserId;
  final TextEditingController topicController;
  final TextEditingController descriptionController;
  final bool loading;
  final bool saving;
  final String? error;
  final ValueChanged<int?> onChildSelected;
  final ValueChanged<int> onParticipantToggled;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  static const Color _blue = Color(0xFF196BC6);
  static const Color _ink = Color(0xFF102F4B);
  static const Color _muted = Color(0xFF6C859F);
  static const Color _border = Color(0xFFD8E7F4);

  InputDecoration _fieldDecoration(String hint, {bool icon = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _muted, fontSize: 14),
      prefixIcon: icon
          ? const Icon(Icons.edit_outlined, color: _blue, size: 20)
          : null,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }

  Widget _childField() {
    return DropdownButtonFormField<int>(
      key: const ValueKey('s21_child_selector'),
      initialValue: selectedChildId,
      isExpanded: true,
      hint: const Text('الطفل *', style: TextStyle(
        color: _muted, fontSize: 14)),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _blue),
      decoration: _fieldDecoration('', icon: true),
      items: [
        for (final item in children)
          if (item is Map && item['id'] is int)
            DropdownMenuItem<int>(
              value: item['id'] as int,
              child: Text(
                (item['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
      ],
      onChanged: saving ? null : onChildSelected,
    );
  }

  Widget _participantOptions() {
    if (selectedChildId == null || team.isEmpty) {
      if (selectedChildId == null) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.only(top: 9),
        child: Text('لا يوجد أعضاء إضافيون في فريق هذا الطفل',
          textAlign: TextAlign.right,
          style: TextStyle(color: _muted, fontSize: 12)),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        for (final user in team)
          if (user is Map && user['id'] is int &&
              user['id'] != myUserId)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: selectedParticipants.contains(user['id']),
              onChanged: saving
                  ? null : (_) => onParticipantToggled(user['id'] as int),
              title: Text(
                (user['name'] ?? '').toString(),
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
              subtitle: Text(
                user['role'] == 'teacher' ? 'معلّم' : 'مختص',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dialog creates its own route; set RTL explicitly to preserve the
    // reference's right-hand Cancel and left-hand Create positions.
    final additionalCount = selectedParticipants
        .where((id) => id != myUserId).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 620),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 21, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                      color: _blue, size: 24),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'دراسة حالة جديدة',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 19),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 45),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _childField(),
                  if (children.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Text('لا يوجد أطفال معيّنون لك حالياً',
                        style: TextStyle(color: _muted, fontSize: 12)),
                    ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 53,
                    child: TextField(
                      key: const ValueKey('s21_topic'),
                      controller: topicController,
                      enabled: !saving,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      decoration: _fieldDecoration(
                        'موضوع الدراسة *', icon: true),
                    ),
                  ),
                  const SizedBox(height: 11),
                  SizedBox(
                    height: 96,
                    child: TextField(
                      key: const ValueKey('s21_description'),
                      controller: descriptionController,
                      enabled: !saving,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      decoration: _fieldDecoration(
                        'وصف الحالة (اختياري)'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'المشاركون من الفريق ($additionalCount)',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                  ),
                  _participantOptions(),
                  if (error != null) ...[
                    const SizedBox(height: 9),
                    Text(error!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFFC43A37), fontSize: 12)),
                    if (error == 'تعذّر تحميل البيانات')
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('إعادة المحاولة'),
                      ),
                  ],
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          key: const ValueKey('s21_cancel'),
                          onPressed: saving ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _blue,
                            backgroundColor: const Color(0xFFE7F1FC),
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: _blue),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('إلغاء',
                            style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: FilledButton(
                          key: const ValueKey('s21_create'),
                          onPressed: saving || loading ? null : onSave,
                          style: FilledButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _blue,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 17, height: 17,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('إنشاء',
                                  style: TextStyle(fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _CaseDiscussionS21View on _NewDiscussionSheetState {
  Widget _buildS21Dialog() => NewCaseStudyDialogS21(
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
