// Specialist S06 lesson catalogue. Keep all lessons/types API-driven.
part of 'specialist_screen.dart';

extension _LessonsTabExtension on _SpecialistDashboardScreenState {
  Widget buildLessonsTab(BuildContext context, JisrColors c) {
    final filtered = _selectedLessonTypeId == null
        ? _lessons
        : _lessons.where((lesson) =>
            lesson['disability_type_id']?.toString() ==
            _selectedLessonTypeId.toString()).toList();

    return SliverMainAxisGroup(
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
          sliver: SliverToBoxAdapter(child: StarterLessonLibraryEntry()),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 65,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
              children: [
                _lessonTypeChip(c, null, context.l10n.all),
                for (final type in _types)
                  if (type is Map &&
                      type['id'] != null &&
                      (type['name'] ?? '').toString().trim().isNotEmpty)
                    _lessonTypeChip(
                      c,
                      int.tryParse(type['id'].toString()),
                      (type['name'] ?? '').toString(),
                    ),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 120),
            sliver: SliverList.list(children: [
              Icon(AppIcons.lesson, size: 62, color: c.muted),
              const SizedBox(height: 16),
              Text(
                _lessons.isEmpty
                    ? context.l10n.noLessonsYet
                    : context.l10n.noLessonsInCategory,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 8),
              if (_lessons.isEmpty)
                Text(
                  context.l10n.addLessonUsingSuggestion,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.muted),
                ),
            ]),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 1, 12, 166),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) => _buildLessonCard(filtered[i], c),
            ),
          ),
      ],
    );
  }

  Widget _lessonTypeChip(JisrColors c, int? id, String label) {
    final selected = _selectedLessonTypeId == id;
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: ChoiceChip(
        label: Text(label, maxLines: 1),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => _refreshState(() => _selectedLessonTypeId = id),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? const Color(0xFF1968C5) : c.line,
          ),
        ),
        backgroundColor: c.card,
        selectedColor: const Color(0xFF1968C5),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : c.body,
        ),
      ),
    );
  }

  Widget _buildLessonCard(Map lesson, JisrColors c) {
    final title = (lesson['title'] ?? '').toString();
    final type = _typeName(lesson['disability_type_id']);
    final targetType = (lesson['target_type'] ?? 'everyone').toString();
    final targetedChildren = (lesson['target_child_ids'] as List?)?.length;

    String targetText;
    switch (targetType) {
      case 'specificChildren':
        targetText = context.l10n.dashboardChildCount(targetedChildren ?? 0);
        break;
      case 'byDisability':
        targetText = context.l10n.byDisability;
        break;
      case 'parents':
        targetText = context.l10n.forParents;
        break;
      default:
        targetText = context.l10n.forEveryone;
    }

    // Only show completion if provided by the API; the lessons endpoint
    // does not calculate progress for an individual child by default.
    final rawCompletion = lesson['completion_percentage'] ??
        lesson['completion_percent'];
    final completion = rawCompletion is num
        ? rawCompletion.clamp(0, 100).round()
        : num.tryParse(rawCompletion?.toString() ?? '')?.clamp(0, 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      elevation: 1,
      shadowColor: const Color(0xFF245B85).withValues(alpha: .08),
      color: c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(23),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewLessonDetail(lesson),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 18, 13, 13),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 63),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.heading,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDF5F7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 29,
                      color: Color(0xFF0AAEBC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (type != null && type.isNotEmpty)
                          Text(
                            type,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: c.muted,
                            ),
                          ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFF6F8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 14, color: Color(0xFF099DAD)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  completion == null
                                      ? targetText
                                      : context.l10n.lessonTargetCompletion(targetText, completion),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF099DAD),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Transform.flip(
                    flipX: true,
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF1767C3),
                      size: 23,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.only(right: 60, left: 63),
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1767C3),
                      backgroundColor: const Color(0xFFE1EFFD),
                      side: const BorderSide(color: Color(0xFF1767C3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    onPressed: () => _recommendLessonToChild(lesson),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: Text(
                      context.l10n.recommendToChild,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _typeName(dynamic id) {
    if (id == null) return null;
    for (final type in _types) {
      if (type is Map && type['id']?.toString() == id.toString()) {
        return (type['name'] ?? '').toString();
      }
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
