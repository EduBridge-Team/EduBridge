// Meeting list body and filter widgets.
part of 'learning_support_meetings_screen.dart';

extension _LearningSupportMeetingsWidgets on _LearningSupportMeetingsScreenState {
  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final sessions = _filtered;
    if (sessions.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, i) => _SessionCard(session: sessions[i]),
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    String message;
    switch (_filter) {
      case 'scheduled':
        message = 'لا توجد جلسات مجدولة';
        break;
      case 'completed':
        message = 'لا توجد جلسات منتهية';
        break;
      default:
        message = 'لا توجد جلسات بعد';
    }

    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(AppIcons.event, size: 80, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.muted,
            ),
          ),
        ),
        if (_filter == 'all') ...[
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'ستظهر الجلسات هنا عند موافقة المختص على طلبات الدعم التعليمي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.muted, height: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
