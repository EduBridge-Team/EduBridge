// lib/screens/case_discussion/case_discussion_list.dart
part of 'case_discussion_screen.dart';

class _CaseDiscussionList extends StatefulWidget {
  final int? filterChildId;
  final bool embedded;
  final bool showBottomNavigation;

  const _CaseDiscussionList({
    this.filterChildId,
    this.embedded = false,
    this.showBottomNavigation = true,
  });

  @override
  State<_CaseDiscussionList> createState() => _CaseDiscussionListState();
}

class _CaseDiscussionListState extends State<_CaseDiscussionList> {
  List<CaseDiscussion> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }
    try {
      final raw = await ApiService.getCaseDiscussions(childId: widget.filterChildId);
      if (!mounted) return;
      setState(() {
        _items = raw
            .map((e) => CaseDiscussion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل دراسات الحالة';
        _loading = false;
      });
    }
  }

  Future<void> _openNewDiscussion() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewDiscussionSheet(),
    );
    if (created == true) _load();
  }

  Widget _body(JisrColors c) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty(c)
                  : _buildList(c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openNewDiscussion,
          icon: const Icon(AppIcons.add),
          label: const Text(
            'دراسة جديدة',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'دراسات الحالة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'تحديث',
                    icon: const Icon(AppIcons.refresh),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            Expanded(child: _body(c)),
          ],
        ),
      );
    }

    return Scaffold(
      bottomNavigationBar:
          widget.showBottomNavigation ? const TeacherNavigationBar() : null,
      appBar: JisrAppBar(
        title: 'دراسات الحالة',
        actions: [
          IconButton(icon: const Icon(AppIcons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDiscussion,
        icon: const Icon(AppIcons.add),
        label: const Text(
          'دراسة جديدة',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _body(c),
    );
  }

  Widget _buildError() => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          const Icon(AppIcons.error, size: 56, color: AppColors.red),
          const SizedBox(height: 14),
          const Text(
            'تعذّر التحميل',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: FilledButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ),
        ],
      );

  Widget _buildEmpty(JisrColors c) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Center(
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: c.tintTeal,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.forum,
                size: 40,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'لا توجد دراسات حالة بعد',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ابدأ دراسة جديدة للتعاون مع المختصين حول حالة الطفل.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: c.muted),
          ),
        ],
      );

  Widget _buildList(JisrColors c) {
    final open =
        _items.where((d) => d.status != CaseDiscussionStatus.resolved).toList();
    final resolved =
        _items.where((d) => d.status == CaseDiscussionStatus.resolved).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
      children: [
        if (open.isNotEmpty) ...[
          _sectionHeader('نشطة', open.length, AppColors.brandBlue),
          ...open.map((d) => _DiscussionTile(discussion: d)),
          const SizedBox(height: 16),
        ],
        if (resolved.isNotEmpty) ...[
          _sectionHeader('محلولة', resolved.length, AppColors.brandTealDeep),
          ...resolved.map((d) => _DiscussionTile(discussion: d)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final CaseDiscussion discussion;
  const _DiscussionTile({required this.discussion});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final isResolved = discussion.status == CaseDiscussionStatus.resolved;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _CaseDiscussionDetail(discussionId: discussion.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (isResolved
                              ? AppColors.brandBlue
                              : AppColors.brandTealDeep)
                          .withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      AppIcons.child,
                      color: isResolved
                          ? AppColors.brandBlue
                          : AppColors.brandTealDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(discussion.childName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.heading,
                            )),
                        Text(discussion.topic,
                            style: TextStyle(fontSize: 13, color: c.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (discussion.unreadCount > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${discussion.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          )),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: discussion.participants.take(4).map((p) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.tintTeal,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          p.role == 'teacher'
                              ? AppIcons.teacher
                              : AppIcons.specialist,
                          size: 12,
                          color: AppColors.brandBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(p.name,
                            style: TextStyle(fontSize: 11, color: c.onTint)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
