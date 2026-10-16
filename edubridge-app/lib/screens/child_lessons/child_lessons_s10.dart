// S10: specialist-only view of a child's real lessons.
// Kept separate from the accessibility-adapted lesson experience for families.
part of 'child_lessons_screen.dart';

extension _ChildLessonsS10 on _ChildLessonsScreenState {
  static const _s10Blue = Color(0xFF196AC7);
  static const _s10Ink = Color(0xFF112E49);
  static const _s10Border = Color(0xFFD8E6F2);
  static const _s10Green = Color(0xFF46B453);

  PreferredSizeWidget _s10AppBar() {
    return AppBar(
      toolbarHeight: 96,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 7,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(23)),
      ),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
        child: Stack(fit: StackFit.expand, children: [
          const DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF20B6C6), Color(0xFF1769C2)],
            ),
          )),
          Positioned(
            left: -56, bottom: -92,
            child: IgnorePointer(child: Container(
              width: 190, height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .19), width: 17),
              ),
            )),
          ),
          Positioned(
            left: -30, bottom: -94,
            child: IgnorePointer(child: Container(
              width: 138, height: 142,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: .17), width: 14),
              ),
            )),
          ),
        ]),
      ),
      leading: IconButton(
        tooltip: 'رجوع',
        onPressed: () => Navigator.maybePop(context),
        icon: const CircleAvatar(
          radius: 21,
          backgroundColor: Color(0x33FFFFFF),
          child: Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white),
        ),
      ),
      title: Text(
        'دروس ${widget.childName}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(left: 27),
          child: Icon(Icons.auto_awesome_outlined, size: 23, color: Colors.white),
        ),
      ],
    );
  }

  Widget _s10Body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 90),
          Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.red)),
          const SizedBox(height: 12),
          Center(child: FilledButton(
            onPressed: _loadLessons,
            child: const Text('إعادة المحاولة'),
          )),
        ],
      );
    }

    final lessons = List<Map>.from(_lessons);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        if (lessons.isEmpty)
          _s10Card(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: Text('لا توجد دروس مخصصة لهذا الطفل بعد',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF637F98), fontSize: 14)),
            ),
          )
        else
          for (final lesson in lessons) _s10LessonCard(lesson),
      ],
    );
  }

  Widget _s10Card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _s10Border),
        borderRadius: BorderRadius.circular(23),
      ),
      child: child,
    );
  }

  Widget _s10LessonCard(Map lesson) {
    final lessonId = int.tryParse((lesson['id'] ?? '').toString());
    final isDone = lessonId != null && _doneLessonIds.contains(lessonId);
    final title = (lesson['title'] ?? '').toString();
    final content = (lesson['content'] ?? '').toString().trim();

    return _s10Card(Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFE5F4E8)
                  : const Color(0xFFE7F1FA),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                isDone ? Icons.check_circle_outline_rounded
                  : Icons.menu_book_outlined,
                size: 29,
                color: isDone ? _s10Green : _s10Blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _openLesson(lesson),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _s10Ink, fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Text(
          content.isEmpty ? 'لا يوجد وصف لهذا الدرس' : content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFF57738C), fontSize: 14.5, height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFE6F5E8)
              : const Color(0xFFE9F3FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Icon(
              isDone ? Icons.check_circle_outline_rounded
                : Icons.access_time_rounded,
              color: isDone ? const Color(0xFF30863F) : _s10Blue,
              size: 21,
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(
              isDone ? 'تم إكمال هذا الدرس' : 'لم يكتمل الدرس بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: isDone ? const Color(0xFF30863F) : _s10Blue,
              ),
            )),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: lessonId == null ? null
              : () => _s10ActionSheet(lessonId, title),
            style: OutlinedButton.styleFrom(
              foregroundColor: _s10Blue,
              side: const BorderSide(color: _s10Blue, width: 1.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 21),
            label: const Text(
              'توصية / ملاحظة',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ));
  }

  Future<void> _s10ActionSheet(int lessonId, String title) async {
    var sending = false;
    String? error;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) {
          Future<void> recommend() async {
            if (sending) return;
            update(() { sending = true; error = null; });
            try {
              final response = await ApiService.authPost(
                '/lessons/$lessonId/recommend',
                {'child_id': widget.childId},
              );
              final body = ApiService.decodeMap(response.body);
              if (response.statusCode != 200 && response.statusCode != 201) {
                if (!sheetContext.mounted) return;
                update(() {
                  sending = false;
                  error = (body['error'] ?? 'تعذّر إرسال التوصية').toString();
                });
                return;
              }
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text((body['message'] ?? 'تم إرسال التوصية لولي الأمر').toString()),
              ));
            } catch (_) {
              if (!sheetContext.mounted) return;
              update(() { sending = false; error = 'تعذّر الاتصال بالسيرفر'; });
            }
          }

          return SafeArea(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 9, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w800, color: _s10Ink)),
                const SizedBox(height: 9),
                const Text('اختر الإجراء المناسب للدرس:',
                  style: TextStyle(color: Color(0xFF637F98))),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: sending ? null : recommend,
                  icon: sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                  label: Text(sending ? 'جارٍ الإرسال...' : 'إرسال توصية إلى ولي الأمر'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: sending ? null : () {
                    Navigator.pop(sheetContext);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CaseDiscussionScreen(
                        filterChildId: widget.childId),
                    ));
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('كتابة ملاحظة في مناقشة الحالة'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: AppColors.red)),
                ],
              ],
            ),
          ));
        },
      ),
    );
  }
}
