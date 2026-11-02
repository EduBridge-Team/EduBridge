import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

/// Real, read-only attendance summaries from the current school scope.
class SchoolAttendanceReportScreen extends StatefulWidget {
  const SchoolAttendanceReportScreen({
    super.key, required this.repository, required this.schoolId, this.sections = const [],
  });
  final SchoolManagementRepository repository;
  final int schoolId;
  final List<Map<String, dynamic>> sections;

  @override
  State<SchoolAttendanceReportScreen> createState() => _SchoolAttendanceReportScreenState();
}

class _SchoolAttendanceReportScreenState extends State<SchoolAttendanceReportScreen> {
  DateTime? _from, _to;
  int? _sectionId;
  Map<String, dynamic>? _report;
  EnrollmentFailure? _failure;
  bool _busy = false;
  int _revision = 0;

  @override
  void dispose() { ++_revision; super.dispose(); }

  String _format(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    if (_busy) return;
    final date = await showDatePicker(
      context: context, initialDate: start ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2000), lastDate: DateTime(2100),
    );
    if (!mounted || date == null) return;
    ++_revision;
    setState(() {
      if (start) { _from = date; } else { _to = date; }
      _report = null; _failure = null;
    });
  }

  Future<void> _load() async {
    if (_busy || _from == null || _to == null || _from!.isAfter(_to!)) return;
    final revision = ++_revision;
    setState(() { _busy = true; _report = null; _failure = null; });
    try {
      final result = await widget.repository.operation('attendance-report', query: {
        'from': _format(_from!), 'to': _format(_to!),
        if (_sectionId != null) 'section_id': '$_sectionId',
      });
      final summary = result['summary'];
      if (result['school_id'] != widget.schoolId ||
          summary is! Map || result['students'] is! List ||
          ['present', 'absent', 'late', 'excused'].any((key) =>
              summary[key] is! int || (summary[key] as int) < 0)) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      if (mounted && revision == _revision) setState(() => _report = result);
    } on EnrollmentApiException catch (error) {
      if (mounted && revision == _revision) setState(() => _failure = error.failure);
    } catch (_) {
      if (mounted && revision == _revision) setState(() => _failure = EnrollmentFailure.invalidResponse);
    } finally {
      if (mounted && revision == _revision) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    const statuses = ['present', 'absent', 'late', 'excused'];
    final labels = [t('حاضر', 'Present'), t('غائب', 'Absent'),
      t('متأخر', 'Late'), t('بعذر', 'Excused')];
    final invalidDateRange = _from != null && _to != null && _from!.isAfter(_to!);
    final rows = (_report?['students'] as List? ?? []).whereType<Map>();
    return Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(t('تقرير الحضور', 'Attendance report'))),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(t('تقرير فعلي من سجلات المدرسة؛ لا يُعدّل الحضور.', 'Read-only report using real school attendance records.')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(true), icon: const Icon(Icons.event),
            label: Text('${t('من تاريخ', 'From')}: ${_from == null ? '—' : _format(_from!)}'),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(false), icon: const Icon(Icons.event),
            label: Text('${t('إلى تاريخ', 'To')}: ${_to == null ? '—' : _format(_to!)}'),
          ),
          if (widget.sections.isNotEmpty)
            DropdownButtonFormField<int>(
              key: const ValueKey('attendance-report-section'),
              isExpanded: true,
              initialValue: _sectionId,
              decoration: InputDecoration(labelText: t('الشعبة', 'Section')),
              items: [
                DropdownMenuItem<int>(value: null, child: Text(t('جميع الشعب', 'All sections'))),
                ...widget.sections.map((row) => DropdownMenuItem<int>(
                  value: row['id'] as int,
                  child: Text('${row['grade_name'] ?? ''} — ${row['name'] ?? ''}'),
                )),
              ],
              onChanged: _busy ? null : (value) => setState(() {
                ++_revision; _sectionId = value; _report = null; _failure = null;
              }),
            ),
          if (invalidDateRange) Text(t('تاريخ النهاية يسبق البداية.', 'End date precedes start date.')),
          FilledButton(
            key: const ValueKey('attendance-report-load'),
            onPressed: _busy || _from == null || _to == null || invalidDateRange ? null : _load,
            child: Text(t('عرض التقرير', 'View report')),
          ),
          if (_busy) const LinearProgressIndicator(),
          if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!), key: const ValueKey('attendance-report-error')),
          if (_report != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 8, children: [
              for (var i = 0; i < statuses.length; i++)
                Chip(label: Text('${labels[i]}: ${(_report!['summary'] as Map)[statuses[i]]}')),
            ]),
            Text('${t('الطلاب', 'Students')}: ${rows.length}', style: Theme.of(context).textTheme.titleMedium),
            if (rows.isEmpty) Text(t('لا توجد سجلات حضور للفترة المحددة.', 'No attendance records for this period.')),
            for (final row in rows) Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${row['child_name'] ?? ''}', style: Theme.of(context).textTheme.titleSmall),
                Text('${t('نسبة الحضور', 'Attendance rate')}: ${row['attendance_rate']}%'),
                Wrap(spacing: 10, children: [
                  for (var i = 0; i < statuses.length; i++)
                    Text('${labels[i]}: ${row['${statuses[i]}_count'] ?? '—'}'),
                ]),
              ]),
            )),
          ],
        ]),
      ))),
    );
  }
}
