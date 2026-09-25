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
      color: c.tintTeal,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.users, color: AppColors.brandBlue, size: 24),
            const SizedBox(width: 8),
            Text(
              'من سيستفيد من الدرس؟',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.onTint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RadioGroup<LessonTarget>(
          groupValue: target,
          onChanged: (v) {
            if (v != null) onTargetChanged(v);
          },
          child: const Column(
            children: [
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('كل الطلاب'),
                value: LessonTarget.everyone,
              ),
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('حسب نوع الإعاقة'),
                value: LessonTarget.byDisability,
              ),
              RadioListTile<LessonTarget>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text('طلاب محدّدون'),
                value: LessonTarget.specificChildren,
              ),
            ],
          ),
        ),
        if (target == LessonTarget.byDisability) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: typeId,
            decoration: const InputDecoration(
              labelText: 'نوع الإعاقة',
              filled: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('— عام —')),
              ...types.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text((t['name'] ?? '').toString()),
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
            const Text('لا يوجد طلاب مسجّلون')
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allChildren.length,
                itemBuilder: (context, i) {
                  final child = allChildren[i];
                  final id = child['id'] as int;
                  final selected = selectedChildIds.contains(id);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(child['name']?.toString() ?? ''),
                    subtitle: Text(
                      child['disability_type']?.toString() ?? 'غير محدد',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: selected,
                    onChanged: (v) => onChildToggle(id, v == true),
                  );
                },
              ),
            ),
        ],
      ],
    ),
  );
}