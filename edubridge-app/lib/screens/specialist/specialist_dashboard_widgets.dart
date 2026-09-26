// Specialist dashboard view helpers extracted from specialist_screen.dart.
part of 'specialist_screen.dart';

extension _SpecialistDashboardWidgetsExtension on _SpecialistDashboardScreenState {
  Widget _buildNotificationBell() {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationListenerService.instance.unreadCount,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(AppIcons.notifications),
              onPressed: _openNotifications,
              tooltip: 'الإشعارات',
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard(JisrColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _showOnlyMine
              ? AppColors.brandBlue.withValues(alpha: 0.1)
              : AppColors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                _showOnlyMine ? AppColors.brandBlue : AppColors.orangeDeep,
            width: 1.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _showOnlyMine
                    ? AppColors.brandBlue
                    : AppColors.orangeDeep,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                _showOnlyMine ? AppIcons.profile : AppIcons.clock,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _showOnlyMine ? 'أطفالي فقط' : 'قائمة الانتظار',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _showOnlyMine
                              ? AppColors.brandBlue
                              : AppColors.orangeDeep,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _showOnlyMine
                              ? AppColors.brandBlue
                              : AppColors.orangeDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_filteredChildren.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showOnlyMine
                        ? 'الأطفال المعيّنون لك'
                        : 'أطفال يحتاجون مختص',
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
            Switch(
              value: _showOnlyMine,
              activeThumbColor: AppColors.brandBlue,
              inactiveThumbColor: AppColors.orangeDeep,
              inactiveTrackColor:
                  AppColors.orange.withValues(alpha: 0.35),
              onChanged: (v) => _refreshState(() => _showOnlyMine = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Text(_error!,
                  style:
                      const TextStyle(fontSize: 16, color: AppColors.red)),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.refresh, size: 28),
                  label: const Text('إعادة المحاولة',
                      style: TextStyle(fontSize: 18)),
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddModal() {
    return Positioned.fill(
      child: AddLessonSheet(
        types: _types,
        onClose: () => _setAdding(false),
        onCreated: (lesson) {
          inlineModalOpen.value = false;
          _refreshState(() {
            _lessons = [lesson, ..._lessons];
            _adding = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إضافة الدرس بنجاح'),
              backgroundColor: AppColors.green,
            ),
          );
        },
      ),
    );
  }
}
