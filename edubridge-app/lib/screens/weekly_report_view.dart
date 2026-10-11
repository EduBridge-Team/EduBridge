part of 'weekly_report_screen.dart';

extension _WeeklyReportScreenStateView on _WeeklyReportScreenState {
  Widget buildView(BuildContext context) {
    final hasReport = _report != null;

    return Scaffold(
      appBar: JisrAppBar(title: 'تقرير ${widget.childName} الأسبوعي'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              key: ValueKey(_selectedWeek == null ? '' : _weekKey(_selectedWeek!)),
              initialValue: _selectedWeek == null ? '' : _weekKey(_selectedWeek!),
              decoration: const InputDecoration(labelText: 'أسبوع التقرير'),
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('الأسبوع الحالي')),
                for (final week in {
                  if (_selectedWeek != null) _weekKey(_selectedWeek!),
                  ..._history.map((report) => _weekKey(report.weekStart)),
                })
                  DropdownMenuItem(value: week, child: Text('الأسبوع الذي يبدأ في $week')),
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
