// S24: specialist notifications layout, using the existing live notifications.
part of 'notifications_screen.dart';

extension _SpecialistNotificationsS24 on _NotificationsScreenState {
  static const _blue = Color(0xFF196AC5);
  static const _ink = Color(0xFF102F4B);

  PreferredSizeWidget _s24AppBar() => BrandAppBar(
    toolbarHeight: 92,
    centerTitle: false,
    titleSpacing: 0,
    leadingWidth: 52,
    leading: IconButton(
      tooltip: 'رجوع', onPressed: () => Navigator.maybePop(context),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x33FFFFFF)),
      icon: const Directionality(textDirection: TextDirection.ltr,
        child: Icon(Icons.arrow_forward_rounded, size: 23))),
    title: const Text('الإشعارات', style: TextStyle(
      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    actions: [
      IconButton(
        tooltip: 'تحديث الإشعارات',
        onPressed: _loading ? null : _load,
        style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
        icon: const Icon(Icons.refresh_rounded, size: 23)),
      ValueListenableBuilder<int>(
        valueListenable: NotificationListenerService.instance.unreadCount,
        builder: (context, count, _) => TextButton(
          onPressed: count == 0 || _markingAll || _loadingMore
              ? null : _markAllRead,
          child: Text('قراءة الكل', style: TextStyle(
            color: count == 0 ? const Color(0x99FFFFFF) : Colors.white,
            fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(width: 4),
    ],
  );

  Widget _s24Tile(Map notification, JisrColors colors) {
    final unread = notification['is_read'] != true;
    final type = (notification['type'] ?? '').toString();
    final title = (notification['title'] ?? '').toString();
    final message = (notification['body'] ?? notification['message'] ?? '').toString();
    final date = notification['created_at'] == null
        ? null : DateTime.tryParse(notification['created_at'].toString());
    final accent = _getIconColor(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: unread ? const Color(0xFFD3EDF1) : Colors.white,
        elevation: unread ? 0 : 1,
        borderRadius: BorderRadius.circular(17),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openNotificationDetails(notification, colors),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: unread
                    ? const Color(0xFFBDE2EF)
                    : accent.withValues(alpha: 0.12),
                child: Icon(_getIcon(type), color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w800, color: _ink)),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(message, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5,
                        color: Color(0xFF52708D))),
                  ],
                  if (date != null) ...[
                    const SizedBox(height: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time_rounded, size: 13,
                        color: colors.muted),
                      const SizedBox(width: 4),
                      Flexible(child: Text(_formatDate(date),
                        style: TextStyle(fontSize: 11, color: colors.muted))),
                    ]),
                  ],
                ],
              )),
              if (unread) ...[
                const SizedBox(width: 7),
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: CircleAvatar(radius: 4,
                    backgroundColor: _blue)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _s24Body(JisrColors colors) {
    if (_loading || _error != null) return _buildBody(colors);
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: NotificationListenerService.instance.notifications,
      builder: (context, list, _) {
        if (list.isEmpty) return _buildBody(colors);
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
            itemCount: list.length + 1,
            itemBuilder: (context, index) {
              if (index < list.length) {
                final entry = list[index];
                return entry is Map ? _s24Tile(entry, colors)
                    : const SizedBox.shrink();
              }
              return ValueListenableBuilder<bool>(
                valueListenable: NotificationListenerService.instance.hasMore,
                builder: (context, more, _) => more
                    ? TextButton(
                        onPressed: _loadingMore || _markingAll ? null : _loadMore,
                        child: Text(_loadingMore
                            ? 'جارِ التحميل...' : 'تحميل إشعارات أقدم'))
                    : const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _s24Navigation(JisrColors colors) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFD9E7F2), width: 1),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE2EDF8),
          iconTheme: WidgetStateProperty.resolveWith((states) =>
              IconThemeData(
                size: 23,
                color: states.contains(WidgetState.selected)
                    ? _blue : const Color(0xFF587895),
              )),
          labelTextStyle: WidgetStateProperty.resolveWith((states) =>
              TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800 : FontWeight.w600,
                color: states.contains(WidgetState.selected)
                    ? _blue : colors.muted,
              )),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 0,
          onDestinationSelected: (index) {
            final Widget screen;
            switch (index) {
              case 0: screen = const SpecialistDashboardScreen(); break;
              case 1: screen = const CaseDiscussionScreen(
                showBottomNavigation: true); break;
              case 2: screen = const ChatsScreen(); break;
              case 3: screen = const LearningSupportRequestsScreen(); break;
              default: return;
            }
            Navigator.pushReplacement(context,
              MaterialPageRoute<void>(builder: (_) => screen));
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'الأطفال',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: 'دراسات الحالة',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'المحادثات',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: 'طلبات الدعم',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistS24(BuildContext context) {
    final colors = JisrColors.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: _s24AppBar(),
      body: _s24Body(colors),
      bottomNavigationBar: _s24Navigation(colors),
    );
  }
}
