// Specialist S20: exact empty case-study layout from the supplied reference.
// Render only after a successful, empty API response. Non-empty lists retain S07.
part of 'case_discussion_screen.dart';

/// S20 visual empty state, separated so it can be widget-tested without API data.
class CaseDiscussionEmptyS20 extends StatelessWidget {
  const CaseDiscussionEmptyS20({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 132,
            height: 132,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFD9F3F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 47,
              color: Color(0xFF196BC6),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'لا توجد دراسات حالة بعد',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF112F4B),
          ),
        ),
        const SizedBox(height: 23),
        const Text(
          'ابدأ دراسة جديدة للتعاون مع المختصين حول\nحالة الطفل.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.85,
            color: Color(0xFF617D99),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

extension _S20CaseDiscussionLayout on _CaseDiscussionListState {
  Widget _s20Header() {
    return Container(
      height: 116,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF23B7C6), Color(0xFF1968C7)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -55,
            bottom: -84,
            child: IgnorePointer(
              child: Container(
                width: 165,
                height: 165,
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
            left: -16,
            bottom: -90,
            child: IgnorePointer(
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.17),
                    width: 11,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'رجوع',
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SpecialistDashboardScreen(),
                        ),
                      );
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Directionality(
                    textDirection: TextDirection.ltr,
                    child: Icon(Icons.arrow_forward_rounded, size: 23),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'دراسات الحالة',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'تحديث دراسات الحالة',
                  onPressed: _refresh,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildS20Empty() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: Column(
        children: [
          _s20Header(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: const CaseDiscussionEmptyS20(),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 's20_new_case_study',
        onPressed: _openNewDiscussion,
        backgroundColor: const Color(0xFF176BC7),
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 23),
        label: const Text(
          'دراسة جديدة',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
