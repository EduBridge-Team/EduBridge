part of 'teacher_child_details_screen.dart';

extension _LessonsTabStateView on _LessonsTabState {
  Widget buildView(BuildContext context) {
    super.build(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(AppIcons.lesson,
              size: 80, color: JisrColors.of(context).muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دروس متاحة لهذا الطفل',
              style: TextStyle(
                fontSize: 17,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          const Text(
            'تفاصيل الدروس',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._lessons.map((l) => _buildLessonCard(l)),
        ],
      ),
    );
  
  }
}
