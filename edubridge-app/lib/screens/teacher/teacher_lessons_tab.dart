// lib/screens/teacher/teacher_lessons_tab.dart
part of 'teacher_screen.dart';

Widget _buildLessonsTab(
  BuildContext context,
  JisrColors c,
  List lessons,
  List types,
  String query,
  ValueChanged<String> onQueryChanged,
  void Function(Map) onViewLesson,
) {
  final q = query.trim();
  final filtered = q.isEmpty
      ? lessons
      : lessons.where((l) {
          final title = (l['title'] ?? '').toString();
          final content = (l['content'] ?? '').toString();
          return title.contains(q) || content.contains(q);
        }).toList();

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مكتبة الدروس',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'استعرض الدروس الحالية أو ابحث عن محتوى محدد.',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              style: const TextStyle(fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'ابحث عن درس...',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: onQueryChanged,
            ),
          ],
        ),
      ),
      Expanded(
        child: filtered.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: c.tintTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.lesson,
                        size: 40,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    lessons.isEmpty
                        ? 'لا توجد دروس بعد'
                        : 'لا نتائج مطابقة لبحثك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: c.heading,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lessons.isEmpty
                        ? 'ابدأ بإضافة أول درس إلى مكتبتك.'
                        : 'جرّب كلمة بحث مختلفة.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: c.muted),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                itemCount: filtered.length,
                itemBuilder: (context, i) =>
                    _buildTeacherLessonCard(filtered[i], c, types, onViewLesson),
              ),
      ),
    ],
  );
}

Widget _buildTeacherLessonCard(
  Map lesson,
  JisrColors c,
  List types,
  void Function(Map) onViewLesson,
) {
  final title = (lesson['title'] ?? '').toString();
  String? tag;
  final dId = lesson['disability_type_id'];
  if (dId != null) {
    for (final t in types) {
      if (t['id'] == dId) tag = (t['name'] ?? '').toString();
    }
  }

  final targetType = lesson['target_type']?.toString() ?? 'everyone';

  String targetBadge;
  Color targetColor;
  IconData targetIcon;
  switch (targetType) {
    case 'parents':
      targetBadge = 'لأولياء الأمور';
      targetColor = AppColors.purple;
      targetIcon = AppIcons.parent;
      break;
    case 'byDisability':
      targetBadge = 'حسب الإعاقة';
      targetColor = AppColors.brandTeal;
      targetIcon = AppIcons.filter;
      break;
    case 'specificChildren':
      final count = (lesson['target_child_ids'] as List?)?.length ?? 0;
      targetBadge = '$count طلاب';
      targetColor = AppColors.brandTeal;
      targetIcon = AppIcons.users;
      break;
    default:
      targetBadge = 'للجميع';
      targetColor = AppColors.brandBlue;
      targetIcon = AppIcons.users;
  }

  final hasVideo = (lesson['video_url']?.toString().isNotEmpty ?? false);
  final hasAudio = (lesson['audio_url']?.toString().isNotEmpty ?? false);

  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onViewLesson(lesson),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: targetColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          hasVideo
              ? AppIcons.play
              : hasAudio
                  ? AppIcons.volumeUp
                  : AppIcons.lesson,
          size: 28,
          color: targetColor,
        ),
      ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                    if (tag != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        tag,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: targetColor.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(targetIcon, size: 12, color: targetColor),
                          const SizedBox(width: 4),
                          Text(
                            targetBadge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: targetColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_back_rounded, color: c.muted, size: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildLessonViewModal(
  BuildContext context,
  JisrColors c,
  Map lesson,
  String? Function(int?) typeName,
  VoidCallback onClose,
) {
  final title = (lesson['title'] ?? '').toString();
  final content = (lesson['content'] ?? '').toString();
  final tag = typeName(lesson['disability_type_id']);
  final videoUrl = lesson['video_url'];
  final audioUrl = lesson['audio_url'];
  final captionUrl = lesson['caption_url'];
  final signUrl = lesson['sign_language_url'];
  final audioDesc = lesson['audio_description'];

  return Positioned.fill(
    child: GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(24),
            ),
            constraints: const BoxConstraints(maxHeight: 600),
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
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            )),
                      ),
                      IconButton(
                        icon: const Icon(AppIcons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  if (tag != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(tag,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.greenDeep)),
                    ),
                  if (content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(content,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: c.body,
                          )),
                    ),
                  if (videoUrl != null) _mediaChip(
                    AppIcons.video, 'فيديو مرفق', AppColors.brandBlue, c.tintTeal),
                  if (captionUrl != null) _mediaChip(
                    AppIcons.captions,
                    'ملف ترجمات مرفق',
                    AppColors.pink,
                    AppColors.pink.withValues(alpha: 0.1)),
                  if (signUrl != null) _mediaChip(
                    AppIcons.signLanguage,
                    'فيديو لغة إشارة مرفق',
                    AppColors.purple,
                    AppColors.purple.withValues(alpha: 0.1)),
                  if (audioDesc != null && audioDesc.toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(AppIcons.speech,
                              color: AppColors.orangeDeep, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('وصف صوتي: $audioDesc',
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  if (audioUrl != null) _mediaChip(
                    AppIcons.audio,
                    'تسجيل صوتي مرفق',
                    AppColors.greenDeep,
                    c.tintGreen),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _mediaChip(IconData icon, String label, Color color, Color bg) {
  return Container(
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}