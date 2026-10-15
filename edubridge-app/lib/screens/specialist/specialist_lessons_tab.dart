// lib/screens/specialist/specialist_lessons_tab.dart
part of 'specialist_screen.dart';

extension _LessonsTabExtension on _SpecialistDashboardScreenState {
  Widget buildLessonsTab(BuildContext context, JisrColors c) {
    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(AppIcons.lesson, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text('لا توجد دروس بعد',
                style: TextStyle(fontSize: 18, color: c.muted)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('أضف درساً جديداً باستخدام زر +',
                style: TextStyle(fontSize: 14, color: c.muted)),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: _lessons.length,
      itemBuilder: (context, i) => _buildLessonCard(_lessons[i], c),
    );
  }

  Widget _buildLessonCard(Map lesson, JisrColors c) {
    final title = (lesson['title'] ?? '').toString();
    final tag = _typeName(lesson['disability_type_id']);
    final targetType = lesson['target_type']?.toString() ?? 'everyone';

    String targetBadge;
    Color targetColor;
    IconData targetIcon;
    switch (targetType) {
      case 'parents':
        targetBadge = 'لأولياء الأمور';
        targetColor = AppColors.brandTealDeep;
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFFDDF5F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            hasVideo
                ? AppIcons.play
                : hasAudio
                    ? AppIcons.volumeUp
                    : AppIcons.lesson,
            size: 27,
            color: const Color(0xFF0AABBA),
          ),
        ),
        title: Text(title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.heading,
            )),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag != null) Text(tag, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 9),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDDF5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(targetIcon, size: 11, color: targetColor),
                  const SizedBox(width: 4),
                  Text(targetBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: targetColor,
                      )),
                ],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_left, color: Color(0xFF186CC8)),
        onTap: () => _viewLessonDetail(lesson),
      ),
    );
  }

  String? _typeName(int? id) {
    if (id == null) return null;
    for (final t in _types) {
      if (t['id'] == id) return (t['name'] ?? '').toString();
    }
    return null;
  }

  void _viewLessonDetail(Map lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LessonDetailSheet(lesson: lesson),
    );
  }
}