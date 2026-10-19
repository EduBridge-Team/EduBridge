part of 'create_specialist_progress_screen.dart';

const _s25Blue = Color(0xFF1769C2);
const _s25Teal = Color(0xFF12AEC0);

extension _CreateSpecialistProgressScreenStateView
    on _CreateSpecialistProgressScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
        backgroundColor: dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF5F9FC),
        appBar: BrandAppBar(
          toolbarHeight: 96,
          centerTitle: false,
          titleSpacing: 0,
          leadingWidth: 56,
          leading: IconButton(
            tooltip: context.l10n.back,
            onPressed: () => Navigator.maybePop(context),
            icon: const CircleAvatar(
              radius: 19,
              backgroundColor: Color(0x33FFFFFF),
              child: Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          title: Text(
            context.l10n.progressEvaluationFor(widget.childName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              children: [
                Text(context.l10n.reportTeacherReference, style: TextStyle(
                  color: c.heading, fontSize: 16, fontWeight: FontWeight.w800,
                )),
                const SizedBox(height: 12),
                if (_loadingReport)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_teacherReport != null)
                  _teacherSummary(_teacherReport!, c)
                else
                  _buildNoReportCard(c),
                const SizedBox(height: 12),
                _notesField(c, _notesCtrl, context.l10n.reportProgressNotes,
                    isRequired: true),
                const SizedBox(height: 12),
                _notesField(c, _recommendationsCtrl, context.l10n.reportRecommendationsForTeacher),
                const SizedBox(height: 12),
                _surface(c, Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _question(c, context.l10n.reportPlanAppropriateQuestion),
                    const SizedBox(height: 12),
                    // Keep the reference order: modification on the right.
                    Row(children: [
                      Expanded(child: _planChoice(c, false, context.l10n.planNeedsChanges)),
                      const SizedBox(width: 8),
                      Expanded(child: _planChoice(c, true, context.l10n.planSuitable)),
                    ]),
                    if (!_planAppropriate) ...[
                      const SizedBox(height: 12),
                      _notesField(c, _planEvalCtrl, context.l10n.reportProposedChanges),
                    ],
                  ],
                )),
                const SizedBox(height: 12),
                _surface(c, Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _question(c, context.l10n.reportParticipationQuestion),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      // Highest rating is on the right; persisted values stay 1–5.
                      children: List.generate(5, (index) => _moodChoice(c, 5 - index)),
                    ),
                  ],
                )),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(context.sharedMessage(_error), style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _s25Blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_saving)
                          const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                        if (!_saving) const Icon(Icons.check_rounded, size: 20),
                        const SizedBox(width: 10),
                        Flexible(child: Text(_saving ? context.l10n.saving : context.l10n.saveEvaluation,
                          textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _surface(JisrColors c, Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [BoxShadow(
        color: Color(0x060F3658), blurRadius: 16, offset: Offset(0, 4),
      )],
    ),
    child: child,
  );

  Widget _teacherSummary(WeeklyReport report, JisrColors c) => _surface(c,
    Column(children: [
      IntrinsicHeight(child: Row(children: [
        _reportMetric(c, Icons.task_alt_rounded,
            '${report.progressPercentage.round()}%', context.l10n.achievement,
            const Color(0xFF69D78B)),
        VerticalDivider(color: c.line, width: 1, indent: 26, endIndent: 18),
        _reportMetric(c, Icons.menu_book_outlined,
            '${report.lessonsCompleted}/${report.lessonsTotal}', context.l10n.lessons, _s25Teal),
        VerticalDivider(color: c.line, width: 1, indent: 26, endIndent: 18),
        _reportMetric(c, Icons.description_outlined,
            '${report.homeworkSubmitted}/${report.homeworkAssigned}', context.l10n.homeworks, _s25Teal),
      ])),
      if (report.teacherNotes?.trim().isNotEmpty ?? false) ...[
        const SizedBox(height: 12),
        Align(alignment: AlignmentDirectional.centerStart,
          child: Text(context.l10n.reportTeacherNotesValue(report.teacherNotes!),
            style: TextStyle(color: c.heading, fontSize: 13, height: 1.5))),
      ],
    ]),
  );

  Widget _reportMetric(JisrColors c, IconData icon, String value,
      String label, Color accent) => Expanded(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Column(children: [
      _iconBadge(icon, accent),
      const SizedBox(height: 10),
      Text(value, textDirection: TextDirection.ltr,
        style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      Text(label, style: TextStyle(color: c.muted, fontSize: 12)),
    ]),
  ));

  Widget _iconBadge(IconData icon, Color accent) => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(
      color: accent.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(icon, color: accent, size: 21),
  );

  Widget _notesField(JisrColors c, TextEditingController controller,
      String label, {bool isRequired = false}) => TextFormField(
    controller: controller,
    minLines: 4,
    maxLines: null,
    style: TextStyle(color: c.heading, fontSize: 14, height: 1.5),
    validator: isRequired
        ? (value) => value == null || value.trim().isEmpty ? context.l10n.fieldRequired : null
        : null,
    decoration: InputDecoration(
      hintText: label,
      hintStyle: TextStyle(color: c.muted, fontSize: 14),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? c.tintTeal : const Color(0xFFEEF6FB),
      contentPadding: const EdgeInsets.all(14),
      prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
      prefixIcon: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, end: 6, bottom: 56),
        child: _iconBadge(Icons.description_outlined, _s25Blue),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _s25Blue)),
    ),
  );

  Widget _question(JisrColors c, String title) => Row(children: [
    _iconBadge(Icons.people_outline_rounded, _s25Teal),
    const SizedBox(width: 10),
    Expanded(child: Text(title, style: TextStyle(
      color: c.heading, fontWeight: FontWeight.w800, fontSize: 16, height: 1.7,
    ))),
  ]);

  Widget _planChoice(JisrColors c, bool value, String label) {
    final selected = _planAppropriate == value;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? _s25Blue : c.card,
          foregroundColor: selected ? Colors.white : c.heading,
          side: BorderSide(color: selected ? _s25Blue : c.line),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        onPressed: _saving ? null : () => _refreshState(() => _planAppropriate = value),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _moodChoice(JisrColors c, int rating) {
    const icons = [Icons.sentiment_very_dissatisfied_outlined,
      Icons.sentiment_dissatisfied, Icons.sentiment_neutral,
      Icons.sentiment_satisfied_outlined, Icons.sentiment_very_satisfied_outlined];
    final labels = [context.l10n.reportRatingVeryLow, context.l10n.reportRatingLow, context.l10n.reportRatingAverage, context.l10n.reportRatingGood, context.l10n.reportRatingExcellent];
    final selected = _moodRating == rating;
    return Semantics(
      label: context.l10n.reportParticipationValue(labels[rating - 1]),
      selected: selected,
      button: true,
      child: Tooltip(
        message: labels[rating - 1],
        child: SizedBox(width: 48, height: 48,
          child: Center(child: SizedBox(width: 42, height: 42,
            child: Material(
              color: selected ? _s25Blue : c.card,
              shape: CircleBorder(side: BorderSide(
                color: selected ? _s25Blue : c.line)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _saving ? null : () => _refreshState(() => _moodRating = rating),
                child: Icon(icons[rating - 1], size: 23,
                    color: selected ? Colors.white : _s25Teal),
              ),
            ),
          )),
        ),
      ),
    );
  }
}
