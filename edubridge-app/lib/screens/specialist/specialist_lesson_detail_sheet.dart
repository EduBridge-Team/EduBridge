// lib/screens/specialist/specialist_lesson_detail_sheet.dart
part of 'specialist_screen.dart';

class _LessonDetailSheet extends StatelessWidget {
  final Map lesson;
  const _LessonDetailSheet({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString();
    final targetType = lesson['target_type']?.toString() ?? 'everyone';
    final createdAt =
        lesson['created_at'] != null ? DateTime.parse(lesson['created_at']) : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (targetType == 'parents')
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.parent, color: Color.fromARGB(255, 17, 120, 180), size: 16),
                    SizedBox(width: 4),
                    Text('درس موجّه لأولياء الأمور',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 17, 120, 180),
                        )),
                  ],
                ),
              ),
            if (createdAt != null)
              Text(
                'تاريخ الإضافة: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            const SizedBox(height: 12),
            if (content.isNotEmpty)
              Text(content,
                  style: TextStyle(fontSize: 16, height: 1.5, color: c.body)),
          ],
        ),
      ),
    );
  }
}