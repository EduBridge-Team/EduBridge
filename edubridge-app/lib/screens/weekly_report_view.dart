part of 'weekly_report_screen.dart';

extension _WeeklyReportScreenStateView on _WeeklyReportScreenState {
  Widget buildView(BuildContext context) {
    final hasReport = _report != null;

    return Scaffold(
      appBar: JisrAppBar(title: 'تقرير ${widget.childName} الأسبوعي'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && !hasReport
            ? const Center(child: CircularProgressIndicator())
            : _error != null && !hasReport
                ? _buildError()
                : !hasReport
                    ? _buildEmpty()
                    : _buildReport(),
      ),
    );
  }
}
