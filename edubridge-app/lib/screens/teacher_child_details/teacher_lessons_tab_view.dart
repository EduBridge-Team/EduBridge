part of 'teacher_child_details_screen.dart';

extension _LessonsTabStateView on _LessonsTabState {
  Widget buildView(BuildContext context) {
    Widget body;

    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          const SizedBox(height: 90),
          const Icon(AppIcons.error, size: 54, color: AppColors.red),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ),
        ],
      );
    } else if (_lessons.isEmpty) {
      final c = JisrColors.of(context);
      body = ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        children: [
          const SizedBox(height: 100),
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
            'لا توجد دروس متاحة لهذا الطفل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            const Text(
              'تفاصيل الدروس',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ..._lessons.map((l) => _buildLessonCard(l)),
          ],
        ),
      );
    }

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(child: body),
        PositionedDirectional(
          start: 20,
          bottom: 24 + bottomInset,
          child: FloatingActionButton.extended(
            heroTag: 'add-lesson-${widget.childId}',
            onPressed: _addLesson,
            icon: const Icon(AppIcons.add),
            label: const Text(
              'إضافة درس',
              style: TextStyle(fontWeight: FontWeight.w800, height: 1.15),
            ),
          ),
        ),
      ],
    );
  }
}
