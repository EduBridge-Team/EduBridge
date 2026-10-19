part of 'create_weekly_report_screen.dart';

extension _CreateWeeklyReportScreenStateView on _CreateWeeklyReportScreenState {
  Widget buildView(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.weeklyReportFor(widget.childName)),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(
          _saving ? context.l10n.saving : context.l10n.weeklySaveReport,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _weekStart,
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) {
                  _refreshState(() => _weekStart = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.reportWeekStart, style: const TextStyle(fontSize: 12)),
                          Text(
                            MaterialLocalizations.of(context).formatMediumDate(_weekStart),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lessonsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.reportCompletedLessons,
                prefixIcon: const Icon(Icons.menu_book),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.tealDeep),
                      const SizedBox(width: 8),
                      Expanded(child: Text(context.l10n.reportChildProgress, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                      const SizedBox(width: 8),
                      Text('$_progressPercent%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.tealDeep)),
                    ],
                  ),
                  Slider(
                    value: _progressPercent.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '$_progressPercent%',
                    activeColor: AppColors.tealDeep,
                    onChanged: (v) => _refreshState(() => _progressPercent = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherNotesCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.reportTeacherNotesLabel,
                prefixIcon: const Icon(Icons.note),
                alignLabelWithHint: true,
                hintText: context.l10n.reportTeacherNotesHint,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? context.l10n.fieldRequired : null,
            ),
            const SizedBox(height: 20),
            Text(context.l10n.reportAchievementsHeading, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.heading)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _achievementsCtrl,
                    decoration: InputDecoration(
                      hintText: context.l10n.reportAchievementHint,
                      prefixIcon: const Icon(Icons.star, color: AppColors.yellow),
                    ),
                    onSubmitted: (_) => _addAchievement(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.green),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: context.l10n.reportAddAchievement,
                  onPressed: _addAchievement,
                ),
              ],
            ),
            if (_achievements.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _achievements.asMap().entries.map((e) {
                  return Chip(
                    label: Text(e.value),
                    backgroundColor: c.tintGreen,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _refreshState(() => _achievements.removeAt(e.key)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),
            Text(context.l10n.reportConcernsHeading, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.heading)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _concernsCtrl,
                    decoration: InputDecoration(
                      hintText: context.l10n.reportConcernHint,
                      prefixIcon: const Icon(Icons.warning, color: AppColors.orange),
                    ),
                    onSubmitted: (_) => _addConcern(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: AppColors.orange),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: context.l10n.reportAddConcern,
                  onPressed: _addConcern,
                ),
              ],
            ),
            if (_concerns.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _concerns.asMap().entries.map((e) {
                  return Chip(
                    label: Text(e.value),
                    backgroundColor: c.tintOrange,
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _refreshState(() => _concerns.removeAt(e.key)),
                  );
                }).toList(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(context.sharedMessage(_error), style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
