part of 'case_discussion_screen.dart';

extension _CaseDiscussionDetailStateView on _CaseDiscussionDetailState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final d = _discussion;

    return Scaffold(
      appBar: JisrAppBar(
        title: d != null ? context.l10n.caseTitleFor(d.childName) : context.l10n.caseTitle,
        actions: [
          if (d != null && d.status != CaseDiscussionStatus.resolved)
            IconButton(
              icon: const Icon(AppIcons.check),
              tooltip: context.l10n.caseCloseAction,
              onPressed: _resolve,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : d == null
              ? Center(child: Text(context.l10n.caseLoadFailed))
              : Column(
                  children: [
                    Flexible(flex: 2, child: SingleChildScrollView(child: _buildInfoHeader(d, c))),
                    Expanded(flex: 3, child: _buildMessages(d, c)),
                    if (d.status != CaseDiscussionStatus.resolved)
                      _buildComposer(c)
                    else
                      _buildResolvedBanner(c),
                  ],
                ),
    );
  }
}
