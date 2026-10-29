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
      tooltip: context.l10n.back, onPressed: () => Navigator.maybePop(context),
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x33FFFFFF)),
      icon: Directionality(textDirection: Directionality.of(context),
        child: Icon(Icons.arrow_back_rounded, size: 23))),
    title: Text(context.l10n.notifications, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
      fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
    actions: [
      IconButton(
        tooltip: context.l10n.refreshNotifications,
        onPressed: _loading ? null : _load,
        style: IconButton.styleFrom(backgroundColor: const Color(0x33FFFFFF)),
        icon: const Icon(Icons.refresh_rounded, size: 23)),
      const SizedBox(width: 4),
    ],
  );

  Widget _s24Tile(Map notification, JisrColors colors) {
    final unread = notification['is_read'] != true;
    final type = (notification['type'] ?? '').toString();
    final title = NotificationPresentation.title(notification, context.l10n);
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
                  Speakable(text: title, child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17,
                      fontWeight: FontWeight.w800, color: _ink))),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Speakable(text: message, child: Text(message, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5,
                        color: Color(0xFF52708D)))),
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
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded),
              label: context.l10n.children,
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              label: context.l10n.caseStudies,
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: context.l10n.conversations,
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              label: context.l10n.supportRequests,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistS24(BuildContext context, {required String? role}) {
    final colors = JisrColors.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: _s24AppBar(),
      body: _buildBody(colors),
      bottomNavigationBar: role == 'specialist' ? _s24Navigation(colors)
          : role == 'teacher' ? const TeacherNavigationBar() : null,
    );
  }
}
