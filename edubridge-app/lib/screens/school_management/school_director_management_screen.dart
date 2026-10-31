import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolDirectorManagementScreen extends StatefulWidget {
  const SchoolDirectorManagementScreen({super.key,required this.schoolId,required this.schoolName,this.repository});
  final int schoolId;
  final String schoolName;
  final SchoolManagementRepository? repository;
  @override
  State<SchoolDirectorManagementScreen> createState()=>_SchoolDirectorManagementScreenState();
}
class _SchoolDirectorManagementScreenState extends State<SchoolDirectorManagementScreen> {
  late SchoolManagementRepository _repository;
  final _email=TextEditingController();
  Map? _director;
  List<Map> _invitations=[],_history=[];
  bool _busy=false,_invite=false,_authorized=false;
  EnrollmentFailure? _failure;
  int _version=0;
  String get _root=>'/admin/schools/${widget.schoolId}';
  @override
  void initState(){super.initState();_repository=widget.repository??SchoolManagementRepository();_load();}
  @override
  void didUpdateWidget(covariant SchoolDirectorManagementScreen oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.schoolId!=widget.schoolId||oldWidget.repository!=widget.repository){_repository=widget.repository??SchoolManagementRepository();_email.clear();_load();}}
  @override
  void dispose(){++_version;_email.dispose();super.dispose();}
  Future<void> _load()async{
    final version=++_version;setState((){_busy=true;_authorized=false;_failure=null;_director=null;_invitations=[];_history=[];});
    try{
      final director=await _repository.client.get('$_root/director');
      final invitations=await _repository.client.get('$_root/director-invitations');
      final history=await _repository.client.get('$_root/management-history');
      if(mounted&&version==_version)setState((){_director=director['director'] as Map?;_invitations=(invitations['invitations'] as List).whereType<Map>().toList();_history=(history['assignments'] as List).whereType<Map>().toList();_authorized=true;});
    }on EnrollmentApiException catch(error){if(mounted&&version==_version)setState(()=>_failure=error.failure);}
    catch(_){if(mounted&&version==_version)setState(()=>_failure=EnrollmentFailure.invalidResponse);}
    finally{if(mounted&&version==_version)setState(()=>_busy=false);}
  }
  Future<void> _write(String path,String method,Map<String,dynamic> body,{int success=201})async{
    if(_busy||!_authorized)return;
    final en=Localizations.localeOf(context).languageCode=='en';
    final confirmed=await showDialog<bool>(context:context,builder:(dialog)=>AlertDialog(title:Text(en?'Confirm school administration change?':'تأكيد تغيير إدارة المدرسة؟'),content:Text('${widget.schoolName}\n${body['director_email']??''}'),actions:[TextButton(onPressed:()=>Navigator.pop(dialog,false),child:Text(en?'Cancel':'إلغاء')),FilledButton(onPressed:()=>Navigator.pop(dialog,true),child:Text(en?'Confirm':'تأكيد'))]));
    if(!mounted||confirmed!=true)return;
    final version=_version;setState((){_busy=true;_failure=null;});
    try{await _repository.mutate(path,method,body,success:success);if(mounted&&version==_version){_email.clear();await _load();}}
    on EnrollmentApiException catch(error){if(mounted&&version==_version)setState(()=>_failure=error.failure);}
    finally{if(mounted&&version==_version)setState(()=>_busy=false);}
  }
  @override
  Widget build(BuildContext context){
    final en=Localizations.localeOf(context).languageCode=='en';String t(String ar,String english)=>en?english:ar;
    return PopScope(canPop:!_busy,child:Scaffold(appBar:BrandAppBar(leading:const BackButton(),title:Text(t('مدير المدرسة والدعوات','School director and invitations')),actions:[IconButton(onPressed:_busy?null:_load,tooltip:t('تحديث','Refresh'),icon:const Icon(Icons.refresh))]),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:720),child:ListView(padding:const EdgeInsets.all(16),children:[
      Text(widget.schoolName),if(_busy)const LinearProgressIndicator(),if(_failure!=null)Text(enrollmentFailureMessage(context.l10n,_failure!)),
      if(_authorized)...[
        Text(_director==null?t('لم يُكلّف مدير بعد.','No director appointed yet.'):'${_director!['name']} — ${_director!['email']}'),
        TextField(controller:_email,enabled:!_busy,keyboardType:TextInputType.emailAddress,decoration:InputDecoration(labelText:t('البريد الشخصي للمدير','Director personal email'))),
        CheckboxListTile(value:_invite,onChanged:_busy?null:(value)=>setState(()=>_invite=value==true),title:Text(t('دعوة بدل التعيين المباشر','Invite instead of direct appointment'))),
        FilledButton(onPressed:_busy?null:(){if(RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())&&!_email.text.trim().toLowerCase().endsWith('.edubridge'))_write('$_root/${_invite?'director-invitations':'director'}','POST',{'director_email':_email.text.trim().toLowerCase()},success:_invite?201:200);},child:Text(t('مراجعة وحفظ','Review and save'))),
        Text(t('الدعوة تتطلب قبول صاحب البريد المؤكّد. إنشاء دعوة جديدة يلغي السابقة.','The invited verified mailbox owner must accept. A new invitation revokes earlier invitations.')),
        for(final invitation in _invitations)Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          Text('${invitation['email']} — ${invitation['expires_at']}'),
          Text(invitation['accepted_at']!=null?t('مقبولة','Accepted'):invitation['revoked_at']!=null?t('ملغاة','Revoked'):t('بانتظار القبول أو منتهية','Pending or expired')),
          if(invitation['accepted_at']==null)...[
            OutlinedButton(onPressed:_busy?null:()=>_write('$_root/director-invitations','POST',{'director_email':invitation['email']}),child:Text(t('إعادة إرسال بدعوة جديدة','Resend as a new invitation'))),
            if(invitation['revoked_at']==null)TextButton(onPressed:_busy?null:()=>_write('$_root/director-invitations/${invitation['id']}','DELETE',{}),child:Text(t('إلغاء الدعوة','Revoke invitation'))),
          ],
        ]))),
        Text(t('سجل التكليفات','Appointment history')),
        for(final row in _history)Text('${row['name']} — ${row['starts_at']} — ${row['ends_at']??t('نشط','Active')}'),
      ],
    ]))))));
  }
}
