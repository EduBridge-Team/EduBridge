// S17: specialist learning-support requests screen from the Figma reference.
// The empty state is only displayed when the live API yields no requests.
part of 'learning_support_requests_screen.dart';

/// Empty result only; errors are shown separately and never disguised as
/// an empty response. Public so the visual state can be widget-tested.
class SpecialistSupportEmptyState extends StatelessWidget {
  const SpecialistSupportEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD6F2F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              color: Color(0xFF196BC5),
              size: 51,
            ),
          ),
        ),
        const SizedBox(height: 19),
        const Text(
          'لا توجد طلبات حالياً',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF112F4A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

extension _SpecialistSupportS17 on _LearningSupportRequestsScreenState {
  static const _s17Blue = Color(0xFF1969C6);

  PreferredSizeWidget _s17AppBar() {
    return AppBar(
      toolbarHeight: 116,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleSpacing: 4,
      centerTitle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF20B7C5), Color(0xFF1B65C0)],
                ),
              ),
            ),
            Positioned(
              left: -60,
              bottom: -92,
              child: IgnorePointer(
                child: Container(
                  width: 190,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 13,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -18,
              bottom: -90,
              child: IgnorePointer(
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        tooltip: 'رجوع',
        onPressed: () async {
          final popped = await Navigator.maybePop(context);
          if (!popped && context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SpecialistDashboardScreen(),
              ),
            );
          }
        },
        icon: const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0x33FFFFFF),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Icon(Icons.arrow_forward_rounded,
                size: 23, color: Colors.white),
          ),
        ),
      ),
      title: const Text(
        'طلبات الدعم التعليمي',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _s17Navigation(JisrColors c) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFD8E5EE), width: 1),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE3EFFB),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected)
                  ? _s17Blue : c.muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 23,
              color: states.contains(WidgetState.selected)
                  ? _s17Blue : const Color(0xFF537394),
            ),
          ),
        ),
        child: NavigationBar(
          height: 76,
          selectedIndex: 3,
          onDestinationSelected: (index) {
            final Widget destination;
            switch (index) {
              case 0:
                destination = const SpecialistDashboardScreen();
                break;
              case 1:
                destination = const CaseDiscussionScreen(
                  showBottomNavigation: true,
                );
                break;
              case 2:
                destination = const ChatsScreen();
                break;
              case 3:
                return;
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
              selectedIcon: Icon(Icons.people_rounded),
              label: 'الأطفال',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'دراسات الحالة',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded),
              label: 'المحادثات',
            ),
            NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox_rounded),
              label: 'طلبات الدعم',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistS17(BuildContext context) {
    final c = JisrColors.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: _s17AppBar(),
      bottomNavigationBar: _s17Navigation(c),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: _requests.isEmpty
                      ? const SpecialistSupportEmptyState()
                      : _buildList(),
                ),
    );
  }
}
