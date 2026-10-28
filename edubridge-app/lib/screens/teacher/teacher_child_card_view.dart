part of 'teacher_screen.dart';

extension _TeacherChildCardView on _TeacherChildCardState {
  Widget buildView(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final progress = _progressPercent;
    Widget action(IconData icon, String label, VoidCallback onTap) => OutlinedButton.icon(
      onPressed: onTap, icon: Icon(icon), label: Text(label));
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: .12), foregroundColor: color,
            child: Text(PresentationText.initial(name, fallback: '؟'))),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: c.heading))),
        ]),
        const SizedBox(height: 8),
        Text('${_followStatus} · ${context.l10n.progress}: ${progress == null ? '—' : '${progress.toStringAsFixed(0)}%'}'),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () => _openProfile(context), icon: const Icon(Icons.folder_open_rounded),
          label: Text(context.l10n.openStudentProfile)),
        action(AppIcons.view, context.l10n.plan, () => _openApprovedPlan(context, child)),
        TextButton.icon(onPressed: _toggleExpanded,
          icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
          label: Text(context.l10n.quickActions)),
        if (_expanded) ...[
          action(AppIcons.report, context.l10n.reports, () => _openDetailsTab(context, 2)),
          action(AppIcons.edit, context.l10n.homeworks, () => _openDetailsTab(context, 0)),
          action(AppIcons.forum, context.l10n.caseStudy, () => _openDetailsTab(context, 3)),
          action(AppIcons.lesson, context.l10n.lessons, () => _openDetailsTab(context, 1)),
          action(AppIcons.specialist, context.l10n.progress, () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => ChildProgressScreen(
              childId: child['id'] as int, childName: name)));
            if (context.mounted) await onReload();
          }),
        ],
      ],
    )));
  }
}
