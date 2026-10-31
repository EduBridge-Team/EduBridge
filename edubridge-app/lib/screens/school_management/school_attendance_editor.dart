import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolAttendanceEditor extends StatefulWidget {
  const SchoolAttendanceEditor({super.key,required this.repository,this.sessionId,this.date});
  final SchoolManagementRepository repository;
  final int? sessionId;
  final String? date;
  @override
  State<SchoolAttendanceEditor> createState()=>_SchoolAttendanceEditorState();
}
class _SchoolAttendanceEditorState extends State<SchoolAttendanceEditor> {
  Map<String,dynamic>? _data;
  final _statuses=<int,String>{};
  bool _busy=false;
  EnrollmentFailure? _failure;
  @override
  void initState(){super.initState();_load();}
  Future<void> _load() async {
    setState(()=>_busy=true);
    try {
      final data=await widget.repository.operation(widget.sessionId==null?'staff-attendance':'attendance-session',query:widget.sessionId==null?{'date':widget.date!}:{'session_id':'${widget.sessionId}'});
      if(mounted)setState(()=>_data=data);
    }on EnrollmentApiException catch(error){if(mounted)setState(()=>_failure=error.failure);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _save() async {
    if(_busy||_data==null)return;
    final student=widget.sessionId!=null;
    final rows=(_data![student?'records':'staff'] as List).whereType<Map>();
    final records=<Map<String,dynamic>>[];
    for(final row in rows){final id=row[student?'child_id':'id'] as int;final value=_statuses[id] ?? (student?row['status'] as String? : (_data!['records'] as List).whereType<Map>().where((record)=>record['user_id']==id).firstOrNull?['status'] as String?);if(value!=null)records.add({(student?'child_id':'user_id'):id,'status':value});}
    if(records.isEmpty)return;
    setState((){_busy=true;_failure=null;});
    try {
      await widget.repository.mutate('/school/operations/${student?'attendance-mark':'staff-attendance-mark'}','PUT',{'records':records,if(student)'session_id':widget.sessionId,if(!student)'date':widget.date});
      if(mounted)Navigator.of(context).pop();
    }on EnrollmentApiException catch(error){if(mounted)setState(()=>_failure=error.failure);}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final en=Localizations.localeOf(context).languageCode=='en';String t(String ar,String english)=>en?english:ar;
    final student=widget.sessionId!=null;
    final statuses={'present':t('حاضر','Present'),'absent':t('غائب','Absent'),'late':t('متأخر','Late'),'excused':t('بعذر','Excused')};
    return PopScope(canPop:!_busy,child:Scaffold(appBar:BrandAppBar(leading:const BackButton(),title:Text(t('تسجيل الحضور','Record attendance'))),
      body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:ListView(padding:const EdgeInsets.all(16),children:[
        if(_busy)const LinearProgressIndicator(),if(_failure!=null)Text(enrollmentFailureMessage(context.l10n,_failure!)),
        if(_data!=null)for(final row in (_data![student?'records':'staff'] as List).whereType<Map>())DropdownButtonFormField<String>(isExpanded:true,
          initialValue:_statuses[row[student?'child_id':'id']] ?? (student?row['status'] as String? : (_data!['records'] as List).whereType<Map>().where((record)=>record['user_id']==row['id']).firstOrNull?['status'] as String?),
          decoration:InputDecoration(labelText:'${row[student?'child_name':'name']}'),items:statuses.entries.map((entry)=>DropdownMenuItem(value:entry.key,child:Text(entry.value))).toList(),onChanged:_busy?null:(value)=>setState(()=>_statuses[row[student?'child_id':'id'] as int]=value!)),
        if(_data!=null)FilledButton(onPressed:_busy?null:_save,child:Text(t('حفظ الحضور','Save attendance'))),
      ])))),
    ));
  }
}
