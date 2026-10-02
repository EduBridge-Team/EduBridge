part of 'notifications_screen.dart';

extension _NotificationsScreenStateView on _NotificationsScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      bottomNavigationBar: const TeacherNavigationBar(),
      appBar: JisrAppBar(
        title: 'الإشعارات',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: 'تحديث',
            onPressed: _loading ? null : _load,
          ),
          ValueListenableBuilder<int>(
            valueListenable: NotificationListenerService.instance.unreadCount,
            builder: (context, count, _) {
              if (count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: _markingAll || _loadingMore ? null : _markAllRead,
                child: _markingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'قراءة الكل',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(c),
    );
  
  }
}
