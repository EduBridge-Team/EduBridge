// lib/screens/add_lesson/add_lesson_target_selector.dart
part of 'add_lesson_sheet.dart';

Widget buildTargetSelector({
  required BuildContext context,
  required JisrColors c,
  required LessonTarget target,
  required ValueChanged<LessonTarget> onTargetChanged,
  required String? typeId,
  required ValueChanged<String?> onTypeChanged,
  required List types,
  required List allChildren,
  required Set<int> selectedChildIds,
  required bool loadingChildren,
  required void Function(int id, bool selected) onChildToggle,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: c.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.users, color: AppColors.brandBlue, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(
              context.l10n.lessonAudience,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: c.onTint,
              ),
            )),
          ],
        ),
        const SizedBox(height: 10),
        Material(type: MaterialType.transparency, child: RadioGroup<LessonTarget>(
          groupValue: target,
          onChanged: (v) {
            if (v != null) onTargetChanged(v);
          },
          child: Column(
            children: [
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(context.l10n.lessonAllStudents),
                value: LessonTarget.everyone,
              ),
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(context.l10n.lessonByDisability),
                value: LessonTarget.byDisability,
              ),
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(context.l10n.lessonSpecificStudents),
                value: LessonTarget.specificChildren,
              ),
            ],
          ),
        )),
        if (target == LessonTarget.byDisability) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: typeId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.l10n.disabilityType,
              filled: true,
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(context.l10n.lessonGeneral)),
              ...types.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(DisabilityDisplay.label((t['name'] ?? '').toString(), context.l10n)),
                  )),
            ],
            onChanged: onTypeChanged,
          ),
        ],
        if (target == LessonTarget.specificChildren) ...[
          const SizedBox(height: 12),
          if (loadingChildren)
            const Center(child: CircularProgressIndicator())
          else if (allChildren.isEmpty)
            Text(context.l10n.lessonNoStudents)
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allChildren.length,
                itemBuilder: (context, i) {
                  final child = allChildren[i];
                  final id = child['id'] as int;
                  final selected = selectedChildIds.contains(id);
                  return Material(type: MaterialType.transparency, child: CheckboxListTile(
                    dense: true,
                    title: Text(child['name']?.toString() ?? ''),
                    subtitle: Text(
                      DisabilityDisplay.label(child['disability_type']?.toString() ?? context.l10n.notSpecified, context.l10n),
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: selected,
                    onChanged: (v) => onChildToggle(id, v == true),
                  ));
                },
              ),
            ),
        ],
      ],
    ),
  );
}