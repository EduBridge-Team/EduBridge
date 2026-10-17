// Figma S21: centered "New case study" modal for the specialist role.
// The form relies on the existing child/team API and existing _save handler.
part of 'case_discussion_screen.dart';

/// Reusable modal shell so visual layout and RTL button order can be tested
/// without loading user or child records from the network.
class CaseDiscussionNewS21Dialog extends StatelessWidget {
  const CaseDiscussionNewS21Dialog({
    super.key,
    required this.fields,
    required this.onCancel,
    required this.onCreate,
    this.loading = false,
    this.saving = false,
    this.error,
  });

  final Widget fields;
  final VoidCallback onCancel;
  final VoidCallback? onCreate;
  final bool loading;
  final bool saving;
  final String? error;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF196BC5);
    const dark = Color(0xFF102F4C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'دراسة حالة جديدة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.description_outlined, size: 23, color: blue),
                  ],
                ),
                const SizedBox(height: 17),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 46),
                    child: CircularProgressIndicator(),
                  )
                else
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: fields,
                    ),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    error!,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: OutlinedButton(
                          key: const ValueKey('s21_cancel'),
                          onPressed: saving ? null : onCancel,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE4F0FC),
                            foregroundColor: blue,
                            side: const BorderSide(color: blue, width: 1),
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'إلغاء',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 35,
                        child: FilledButton(
                          key: const ValueKey('s21_create'),
                          onPressed: saving || loading ? null : onCreate,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'إنشاء',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
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

extension _S21NewCaseStudyLayout on _NewDiscussionSheetState {
  static const _s21Border = Color(0xFFD8E7F2);
  static const _s21Blue = Color(0xFF196BC5);
  static const _s21Ink = Color(0xFF102F4C);

  InputDecoration _s21InputDecoration(
    String hint, {
    IconData? icon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: _s21Border),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF69839B)),
      prefixIcon: icon == null
          ? null
          : Icon(icon, size: 20, color: _s21Blue),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 14,
      ),
      enabledBorder: border,
      border: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _s21Blue, width: 1.5),
      ),
    );
  }

  Widget _s21ChildSelector() {
    if (_myChildren.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا يوجد أطفال معيّنون لك حالياً — لا يمكن بدء دراسة حالة.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6C8499),
            fontSize: 13,
          ),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      key: const ValueKey('s21_child'),
      initialValue: _selectedChildId,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 22, color: _s21Blue),
      hint: const Text(
        'الطفل *',
        style: TextStyle(fontSize: 14, color: Color(0xFF69839B)),
      ),
      decoration: _s21InputDecoration('', icon: Icons.edit_outlined),
      items: _myChildren.map<DropdownMenuItem<int>?>((child) {
        final id = int.tryParse(child['id'].toString());
        if (id == null) return null;
        return DropdownMenuItem<int>(
          value: id,
          child: Text(
            (child['name'] ?? '').toString(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).whereType<DropdownMenuItem<int>>().toList(),
      onChanged: _saving ? null : _onChildSelected,
    );
  }

  Widget _buildS21Dialog() {
    final c = JisrColors.of(context);
    final count = _selectedParticipants
        .where((id) => id != _myUserId).length;

    return CaseDiscussionNewS21Dialog(
      loading: _loading,
      saving: _saving,
      error: _error,
      onCancel: () => Navigator.of(context).pop(),
      onCreate: _save,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _s21ChildSelector(),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('s21_topic'),
            controller: _topicCtrl,
            enabled: !_saving,
            maxLines: 1,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            textInputAction: TextInputAction.next,
            decoration: _s21InputDecoration(
              'موضوع الدراسة *',
              icon: Icons.edit_outlined,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('s21_description'),
            controller: _descCtrl,
            enabled: !_saving,
            minLines: 3,
            maxLines: 3,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            decoration: _s21InputDecoration('وصف الحالة (اختياري)'),
          ),
          const SizedBox(height: 17),
          Text(
            'المشاركون من الفريق ($count)',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _s21Ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_selectedChildId != null) ...[
            const SizedBox(height: 9),
            ..._buildParticipantTiles(c),
          ],
        ],
      ),
    );
  }
}
