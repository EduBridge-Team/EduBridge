import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/school_operation_specs.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'school_operation_form.dart';
import 'school_attendance_editor.dart';

class SchoolOperationsScreen extends StatefulWidget {
  const SchoolOperationsScreen({super.key, required this.repository, required this.category, required this.schoolId});
  final SchoolManagementRepository repository;
  final String category;
  final int schoolId;
  @override
  State<SchoolOperationsScreen> createState() => _SchoolOperationsScreenState();
}
class _SchoolOperationsScreenState extends State<SchoolOperationsScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? _data, _references;
  String? _action;
  bool _loading = false;
  int _version = 0;
  EnrollmentFailure? _failure;
  static const _read = {'academic':'academic','enrollment':'students','attendance':'attendance','timetable':'timetable','curriculum':'curriculum','reports':'reports'};
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _load(); }
  @override
  void didUpdateWidget(covariant SchoolOperationsScreen oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.repository != widget.repository || oldWidget.category != widget.category || oldWidget.schoolId != widget.schoolId) _load(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _load(); }
  @override
  void dispose() { ++_version; WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _load() async {
    final version = ++_version;
    setState(() { _data = null; _references = null; _failure = null; _loading = true; });
    try {
      final authority = await widget.repository.context();
      if ((authority['school'] as Map)['id'] != widget.schoolId || !(authority['permissions'] as List).contains(widget.category)) throw const EnrollmentApiException(EnrollmentFailure.forbidden);
      final references = await widget.repository.operation('academic');
      final data = await widget.repository.operation(_read[widget.category]!);
      if (widget.category == 'academic' || widget.category == 'timetable') references.addAll(await widget.repository.operation('teachers'));
      if (widget.category == 'academic') references.addAll(await widget.repository.operation('participants'));
      references.addAll(data);
      if (!mounted || version != _version) return;
      setState(() { _data = data; _references = references; });
    } on EnrollmentApiException catch (error) { if (mounted && version == _version) setState(() => _failure = error.failure); }
    catch (_) { if (mounted && version == _version) setState(() => _failure = EnrollmentFailure.invalidResponse); }
    finally { if (mounted && version == _version) setState(() => _loading = false); }
  }
  void _editAttendance({int? sessionId, String? date}) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SchoolAttendanceEditor(repository: widget.repository, sessionId: sessionId, date: date))).then((_) { if (mounted) _load(); });
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    final labels = {'academic':t('الهيكل والمعلمون','Structure and teachers'),'enrollment':t('الطلاب','Students'),'attendance':t('الحضور','Attendance'),'timetable':t('الجدول','Timetable'),'curriculum':t('المنهاج','Curriculum'),'reports':t('التقارير','Reports')};
    final definitions = schoolOperationSpecs.where((row) => row['category'] == widget.category).toList();
    final selected = definitions.where((row) => row['action'] == _action).firstOrNull ?? definitions.firstOrNull;
    final references = <String, dynamic>{...?_references,
      'weekdays': [for (var i=0;i<7;i++) {'id':i+1,'label':[t('الاثنين','Monday'),t('الثلاثاء','Tuesday'),t('الأربعاء','Wednesday'),t('الخميس','Thursday'),t('الجمعة','Friday'),t('السبت','Saturday'),t('الأحد','Sunday')][i]}],
      'closure_statuses':[{'id':'withdrawn','label':t('منسحب','Withdrawn')},{'id':'transferred','label':t('منقول','Transferred')}],
    };
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(labels[widget.category] ?? ''), actions: [IconButton(onPressed: _loading ? null : _load, tooltip: t('تحديث','Refresh'), icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840), child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_loading) const LinearProgressIndicator(), if (_failure != null) Text(enrollmentFailureMessage(context.l10n,_failure!)),
        if (_data != null) ...[
          if (selected != null) ...[
            DropdownButtonFormField<String>(key: ValueKey('operation-select-$_version'), isExpanded: true, initialValue: selected['action'] as String, decoration: InputDecoration(labelText:t('الإجراء','Action')),
              items: definitions.map((row)=>DropdownMenuItem(value:row['action'] as String,child:Text(row[en?'en':'ar'] as String))).toList(),onChanged:(value)=>setState(()=>_action=value)),
            const SizedBox(height:16),
            SchoolOperationForm(key:ValueKey('${selected['action']}-$_version'),definition:selected,references:references,repository:widget.repository,onSaved:_load),
          ],
          if (widget.category=='attendance') ...[
            OutlinedButton(onPressed:() async { final date=await showDatePicker(context:context,firstDate:DateTime(2000),lastDate:DateTime(2100),initialDate:DateTime.now()); if(mounted && date!=null) _editAttendance(date:date.toIso8601String().substring(0,10)); },child:Text(t('حضور الموظفين','Staff attendance'))),
            for(final session in (_data!['attendance_sessions'] as List? ?? []).whereType<Map>()) OutlinedButton(onPressed:()=>_editAttendance(sessionId:session['id'] as int),child:Text('${session['attendance_date']} — ${session['section_name']}')),
          ],
          if (_data!['statistics'] is Map) for(final row in (_data!['statistics'] as Map).entries) Text('${({'students':t('الطلاب','Students'),'teachers':t('المعلمون','Teachers'),'grades':t('الصفوف','Grades'),'lessons':t('حصص الجدول','Timetable lessons'),'books':t('الكتب','Books')})[row.key] ?? ''}: ${row.value}'),
          for(final entry in _data!.entries.where((entry)=>entry.value is List)) ...[
            const Divider(),
            Text('${t('عدد السجلات','Record count')}: ${(entry.value as List).length}'),
            for(final row in (entry.value as List).whereType<Map>()) Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Text([row['child_name'] ?? row['name'] ?? row['title'] ?? row['attendance_date'] ?? row['subject_name'],row['grade_name'],row['section_name'],row['teacher_name'],row['academic_year_name'],row['starts_on'],row['ends_on'],row['starts_at'],row['ends_at']].where((value)=>value!=null).join(' — '))),
          ],
        ],
      ])))),
    );
  }
}
