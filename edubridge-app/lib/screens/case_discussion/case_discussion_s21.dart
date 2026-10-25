// Figma S21: centered specialist-only "new case study" dialog.
// All children and team members are supplied by the existing API state.
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

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
  final Object? error;
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
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

  Widget _childField(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const ValueKey('s21_child_selector'),
      initialValue: selectedChildId,
      isExpanded: true,
      hint: Text(
        context.l10n.caseChildField,
        style: const TextStyle(color: _muted, fontSize: 14),
      ),
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

  Widget _participantOptions(BuildContext context) {
    if (selectedChildId == null || team.isEmpty) {
      if (selectedChildId == null) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: 9),
        child: Text(
          context.l10n.caseNoExtraTeam,
          textAlign: TextAlign.start,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 8),
        for (final user in team)
          if (user is Map && user['id'] is int && user['id'] != myUserId)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: selectedParticipants.contains(user['id']),
              onChanged: saving
                  ? null
                  : (_) => onParticipantToggled(user['id'] as int),
              title: Text(
                (user['name'] ?? '').toString(),
                style: const TextStyle(color: _ink, fontSize: 13),
              ),
              subtitle: Text(
                user['role'] == 'teacher'
                    ? context.l10n.teacherRole
                    : context.l10n.specialistRole,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Inherit the application locale across the dialog route.
    final additionalCount = selectedParticipants
        .where((id) => id != myUserId)
        .length;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 21, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description_outlined, color: _blue, size: 24),
                  const SizedBox(width: 9),
                  Flexible(
                    child: Text(
                      context.l10n.caseNewTitle,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
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
                _childField(context),
                if (children.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      context.l10n.noAssignedChildren,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 11),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 53),
                  child: TextField(
                    key: const ValueKey('s21_topic'),
                    controller: topicController,
                    enabled: !saving,
                    textDirection: Directionality.of(context),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    decoration: _fieldDecoration(
                      context.l10n.caseTopicField,
                      icon: true,
                    ),
                  ),
                ),
                const SizedBox(height: 11),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 96),
                  child: TextField(
                    key: const ValueKey('s21_description'),
                    controller: descriptionController,
                    enabled: !saving,
                    maxLines: null,
                    minLines: 3,
                    textAlignVertical: TextAlignVertical.top,
                    textDirection: Directionality.of(context),
                    textAlign: TextAlign.start,
                    decoration: _fieldDecoration(
                      context.l10n.caseDescriptionField,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.caseExtraTeamCount(additionalCount),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _participantOptions(context),
                if (error != null) ...[
                  const SizedBox(height: 9),
                  Text(
                    context.sharedMessage(error),
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Color(0xFFC43A37),
                      fontSize: 12,
                    ),
                  ),
                  if (error == SharedUiMessage.caseDataLoadFailed)
                    TextButton(
                      onPressed: onRetry,
                      child: Text(context.l10n.retryAction),
                    ),
                ],
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
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
                        child: Text(
                          context.l10n.cancel,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 34),
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
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.l10n.caseCreate,
                                style: const TextStyle(fontSize: 14),
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
    );
  }
}
