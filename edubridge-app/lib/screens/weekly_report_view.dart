part of 'weekly_report_screen.dart';

extension _WeeklyReportScreenStateView on _WeeklyReportScreenState {
  Widget buildView(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: 'تقرير ${widget.childName} الأسبوعي'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _report == null
                    ? _buildEmpty()
                    : _buildReport(),
      ),
    );
  
  }
}
