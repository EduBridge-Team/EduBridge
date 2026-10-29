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
        Text(
          context.l10n.caseListEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF112F4B),
          ),
        ),
        const SizedBox(height: 23),
        Text(
          context.l10n.caseListEmptyHintS20,
          textAlign: TextAlign.center,
          style: const TextStyle(
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

/// A real AppBar reserves the system status-bar inset automatically. Keeping
/// the gradient and controls in Scaffold.appBar prevents the title/back/refresh
/// buttons from being drawn underneath the Android status bar.
class CaseDiscussionHeaderS20 extends StatelessWidget
    implements PreferredSizeWidget {
  const CaseDiscussionHeaderS20({
    super.key,
    required this.onBack,
    required this.onRefresh,
  });

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  // Scaffold adds the status inset to the shared profile-sized toolbar.
  @override
  Size get preferredSize => const Size.fromHeight(BrandAppBar.standardToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BrandAppBar(
      // Keep the RTL title beside the back arrow, rather than centered
      // with a large gap on narrow mobile screens.
      centerTitle: false,
      titleSpacing: 0,
      leadingWidth: 52,
      leading: IconButton(
        tooltip: context.l10n.back,
        onPressed: onBack,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
        ),
        icon: Icon(Directionality.of(context) == TextDirection.rtl
            ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, size: 23),
      ),
      title: Text(
        context.l10n.caseStudies,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          tooltip: context.l10n.caseRefresh,
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 24),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

extension _S20CaseDiscussionLayout on _CaseDiscussionListState {
  Widget _buildS20Empty() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: CaseDiscussionHeaderS20(
        onBack: () {
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
        onRefresh: _refresh,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: const CaseDiscussionEmptyS20(),
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
        label: Text(
          context.l10n.caseNewAction,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
