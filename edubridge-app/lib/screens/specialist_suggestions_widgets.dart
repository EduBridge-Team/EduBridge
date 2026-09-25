part of 'specialist_suggestions_screen.dart';

extension _SpecialistSuggestionsWidgets on _SpecialistSuggestionsScreenState {
  Widget _buildBody(JisrColors c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(color: AppColors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.inbox_outlined, size: 72, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _filter == 'pending'
                  ? 'لا توجد اقتراحات معلقة'
                  : 'لا توجد اقتراحات',
              style: TextStyle(fontSize: 16, color: c.muted),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _suggestions.length,
      itemBuilder: (context, i) =>
          _buildSuggestionCard(_suggestions[i], c),
    );
  }

  Widget _buildSuggestionCard(Map s, JisrColors c) {
    final status = s['status'] ?? 'pending';
    final isLearningSupport = s['specialty'] == 'learning_support';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (status) {
      case 'accepted':
        statusColor = AppColors.green;
        statusLabel = 'مقبول';
        statusIcon = AppIcons.check;
        break;
      case 'rejected':
        statusColor = AppColors.red;
        statusLabel = 'مرفوض';
        statusIcon = AppIcons.error;
        break;
      default:
        statusColor = AppColors.orange;
        statusLabel = 'معلّق';
        statusIcon = AppIcons.clock;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isLearningSupport
                      ? AppColors.purple
                      : AppColors.brandBlue,
                  child: Text(
                    (s['child_name'] ?? '؟').toString().characters.first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['child_name'] ?? '',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        'من: ${s['suggested_by_name'] ?? ''}',
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isLearningSupport ? AppColors.purple : AppColors.brandBlue)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isLearningSupport ? AppIcons.specialist : AppIcons.lesson,
                    color: isLearningSupport
                        ? AppColors.brandTealDeep
                        : AppColors.brandBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isLearningSupport ? 'مختص دعم تعليمي' : 'مختص تعليمي',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isLearningSupport
                          ? AppColors.brandTealDeep
                          : AppColors.brandBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${s['reason'] ?? ''}',
              style: TextStyle(fontSize: 14, height: 1.5, color: c.body),
            ),

            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                      ),
                      icon: const Icon(AppIcons.close),
                      label: const Text('رفض'),
                      onPressed: () => _reject(s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        backgroundColor: AppColors.green,
                      ),
                      icon: const Icon(AppIcons.check),
                      label: const Text('قبول ومتابعة'),
                      onPressed: () => _accept(s),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
