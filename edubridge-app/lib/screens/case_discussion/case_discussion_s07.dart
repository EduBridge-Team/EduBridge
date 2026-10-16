// Specialist-only case study catalogue matching the S07 reference.
// Preserve the existing teacher list, detail screen, creation and API flows.
part of 'case_discussion_screen.dart';

extension _S07CaseDiscussionLayout on _CaseDiscussionListState {
  Widget _s07Header() => Container(
        height: 116,
        decoration: const BoxDecoration(
          gradient: AppColors.appBarGradient,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -65,
              bottom: -90,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .19),
                      width: 14,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -33,
              bottom: -95,
              child: IgnorePointer(
                child: Container(
                  width: 125,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .16),
                      width: 12,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const ProfileAvatarButton(
                    size: 48,
                    showVerificationBadge: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Color(0xFF1768C5),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'دراسات الحالة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'الإشعارات',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notifications_none_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'القائمة',
                    color: Theme.of(context).colorScheme.surface,
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (key) {
                      if (key == 'lessons') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SpecialistDashboardScreen(initialTab: 1),
                          ),
                        );
                      } else if (key == 'profile') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'lessons',
                        child: Text('الدروس'),
                      ),
                      PopupMenuItem(
                        value: 'profile',
                        child: Text('الملف الشخصي'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _s07Navigation(JisrColors c) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFF8FA5B5), width: 1.5),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: c.card,
            indicatorColor: const Color(0xFFE1F0FF),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? AppColors.brandBlue : c.muted,
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          child: NavigationBar(
            height: 76,
            selectedIndex: 1,
            onDestinationSelected: (index) {
              final Widget destination;
              switch (index) {
                case 0:
                  destination = const SpecialistDashboardScreen();
                  break;
                case 1:
                  return;
                case 2:
                  destination = const ChatsScreen();
                  break;
                case 3:
                  destination = const LearningSupportRequestsScreen();
                  break;
                default:
                  return;
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => destination),
              );
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                label: 'الأطفال',
              ),
              NavigationDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded),
                label: 'دراسات الحالة',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
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

  Widget _s07Body(JisrColors c) {
    final active = _items
        .where((d) => d.status != CaseDiscussionStatus.resolved)
        .toList();
    final completed = _items
        .where((d) => d.status == CaseDiscussionStatus.resolved)
        .toList();
    final displayed = _s07Completed ? completed : active;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 120),
        children: [
          Row(
            children: [
              Expanded(
                child: _s07Filter(
                  c,
                  'نشطة (' + active.length.toString() + ')',
                  !_s07Completed,
                  () => _refreshS07State(() => _s07Completed = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _s07Filter(
                  c,
                  'مكتملة (' + completed.length.toString() + ')',
                  _s07Completed,
                  () => _refreshS07State(() => _s07Completed = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.red, size: 42),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _load,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          else if (displayed.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 76),
              child: Column(
                children: [
                  Icon(Icons.folder_open_outlined, color: c.muted, size: 52),
                  const SizedBox(height: 14),
                  Text(
                    'لا توجد دراسات حالة في هذا القسم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: c.heading,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final item in displayed) _s07Card(c, item),
        ],
      ),
    );
  }

  Widget _s07Filter(
    JisrColors c, String label, bool selected, VoidCallback onTap,
  ) => Material(
        color: selected ? const Color(0xFF1969C8) : c.tintTeal,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 47,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: selected ? Colors.white : c.muted,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _s07Card(JisrColors c, CaseDiscussion discussion) {
    final teacher = discussion.participants
        .where((p) => p.role == 'teacher').toList();
    final specialists = discussion.participants
        .where((p) => p.role == 'specialist').toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.card,
        elevation: 1,
        shadowColor: AppColors.brandBlue.withValues(alpha: .10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(23),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    _CaseDiscussionDetail(discussionId: discussion.id),
              ),
            );
            if (mounted) _refresh();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 14, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 49,
                      height: 49,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF7F9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.sentiment_satisfied_alt_outlined,
                        color: Color(0xFF0BAEBD),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            discussion.childName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.heading,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            discussion.topic,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    if (discussion.unreadCount > 0)
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.red,
                        child: Text(
                          discussion.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (teacher.isNotEmpty || specialists.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final participant in teacher.take(1))
                        _s07PersonTag(
                          participant.name,
                          Icons.school_outlined,
                        ),
                      for (final participant in specialists.take(2))
                        _s07PersonTag(
                          participant.name,
                          Icons.lightbulb_outline,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _s07PersonTag(String name, IconData icon) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11, vertical: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F6F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF1798B9)),
            const SizedBox(width: 5),
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF183F57),
              ),
            ),
          ],
        ),
      );
}
