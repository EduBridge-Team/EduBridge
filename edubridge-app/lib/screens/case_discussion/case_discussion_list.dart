// lib/screens/case_discussion/case_discussion_list.dart
part of 'case_discussion_screen.dart';

class _CaseDiscussionList extends StatefulWidget {
  final int? filterChildId;
  const _CaseDiscussionList({this.filterChildId});

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(
        title: 'دراسات الحالة',
        actions: [
          IconButton(icon: const Icon(AppIcons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewDiscussion,
        icon: const Icon(AppIcons.add),
        label: const Text('دراسة جديدة'),
        backgroundColor: AppColors.brandTeal,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _items.isEmpty
                    ? _buildEmpty(c)
                    : _buildList(c),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 12),
            const Text('تعذّر التحميل',
                style: TextStyle(fontSize: 16, color: AppColors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );

  Widget _buildEmpty(JisrColors c) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(AppIcons.forum, size: 80, color: c.muted),
          const SizedBox(height: 16),
          Center(
            child: Text('لا توجد دراسات حالة بعد',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                )),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('اضغط + لبدء دراسة حالة جديدة',
                style: TextStyle(fontSize: 13, color: c.muted)),
          ),
        ],
      );

  Widget _buildList(JisrColors c) {
    final open =
        _items.where((d) => d.status != CaseDiscussionStatus.resolved).toList();
    final resolved =
        _items.where((d) => d.status == CaseDiscussionStatus.resolved).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (open.isNotEmpty) ...[
          _sectionHeader('نشطة', open.length, AppColors.brandBlue),
          ...open.map((d) => _DiscussionTile(discussion: d)),
          const SizedBox(height: 16),
        ],
        if (resolved.isNotEmpty) ...[
          _sectionHeader('محلولة', resolved.length, AppColors.green),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    fontWeight: FontWeight.bold,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: isResolved
                        ? AppColors.green.withValues(alpha: 0.15)
                        : AppColors.brandTeal.withValues(alpha: 0.15),
                    child: Icon(
                      AppIcons.child,
                      color: isResolved ? AppColors.green : AppColors.brandBlue,
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
                              fontWeight: FontWeight.bold,
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
                            fontWeight: FontWeight.bold,
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