part of 'case_discussion_screen.dart';

extension _CaseDiscussionDetailStateView on _CaseDiscussionDetailState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final d = _discussion;

    return Scaffold(
      appBar: JisrAppBar(
        title: d != null ? 'دراسة حالة — ${d.childName}' : 'دراسة حالة',
        actions: [
          if (d != null && d.status != CaseDiscussionStatus.resolved)
            IconButton(
              icon: const Icon(AppIcons.check),
              tooltip: 'إغلاق الدراسة',
              onPressed: _resolve,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? const Center(child: Text('تعذّر التحميل'))
              : Column(
                  children: [
                    _buildInfoHeader(d, c),
                    Expanded(child: _buildMessages(d, c)),
                    if (d.status != CaseDiscussionStatus.resolved)
                      _buildComposer(c)
                    else
                      _buildResolvedBanner(c),
                  ],
                ),
    );
  
  }
}
