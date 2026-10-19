part of 'weekly_report_screen.dart';

extension _WeeklyReportScreenStateView on _WeeklyReportScreenState {
  Widget buildView(BuildContext context) {
    final hasReport = _report != null;

    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.reportWeeklyTitle(widget.childName)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedWeek == null ? '' : _weekKey(_selectedWeek!)),
              initialValue: _selectedWeek == null ? '' : _weekKey(_selectedWeek!),
              decoration: InputDecoration(labelText: context.l10n.reportWeekLabel),
              isExpanded: true,
              items: [
                DropdownMenuItem(value: '', child: Text(context.l10n.reportCurrentWeek)),
                for (final week in {
                  if (_selectedWeek != null) _weekKey(_selectedWeek!),
                  ..._history.map((report) => _weekKey(report.weekStart)),
                })
                  DropdownMenuItem(value: week, child: Text(context.l10n.reportWeekBeginning(MaterialLocalizations.of(context).formatShortDate(DateTime.parse(week))))),
              ],
              onChanged: _loading ? null : (value) {
                _selectedWeek = value == null || value.isEmpty ? null : DateTime.parse(value);
                _load();
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : !hasReport
                          ? _buildEmpty()
                          : _buildReport(),
            ),
          ),
        ],
      ),
    );
  }

  String _weekKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
