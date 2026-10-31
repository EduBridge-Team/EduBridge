import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'school_director_management_screen.dart';

class SchoolAdminDirectoryScreen extends StatefulWidget{
  const SchoolAdminDirectoryScreen({super.key,this.repository});
  final SchoolManagementRepository? repository;
  @override
  State<SchoolAdminDirectoryScreen> createState()=>_SchoolAdminDirectoryScreenState();
}
class _SchoolAdminDirectoryScreenState extends State<SchoolAdminDirectoryScreen>{
  late SchoolManagementRepository _repository;
  List<Map> _schools=[];int? _cursor;String _search='';bool _loading=false;EnrollmentFailure? _failure;
  @override
  void initState(){super.initState();_repository=widget.repository??SchoolManagementRepository();_load();}
  Future<void> _load({bool more=false})async{
    if(_loading)return;setState((){_loading=true;_failure=null;if(!more)_schools=[];});
    try{final data=await _repository.client.get('/admin/schools${more&&_cursor!=null?'?after_id=$_cursor':''}');if(mounted)setState((){final rows=(data['schools']as List).whereType<Map>().toList();_schools=more?[..._schools,...rows]:rows;_cursor=data['has_more']==true?data['next_after_id']as int?:null;});}
    on EnrollmentApiException catch(error){if(mounted)setState(()=>_failure=error.failure);}
    catch(_){if(mounted)setState(()=>_failure=EnrollmentFailure.invalidResponse);}
    finally{if(mounted)setState(()=>_loading=false);}
  }
  @override
  Widget build(BuildContext context){final en=Localizations.localeOf(context).languageCode=='en';String t(String ar,String english)=>en?english:ar;
    return Scaffold(appBar:BrandAppBar(leading:const BackButton(),title:Text(t('مدارس النظام','System schools')),actions:[IconButton(onPressed:_loading?null:_load,tooltip:t('تحديث','Refresh'),icon:const Icon(Icons.refresh))]),body:SafeArea(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:840),child:ListView(padding:const EdgeInsets.all(16),children:[
      TextField(decoration:InputDecoration(labelText:t('البحث في المدارس المحملة','Search loaded schools')),onChanged:(value)=>setState(()=>_search=value)),
      if(_loading)const LinearProgressIndicator(),if(_failure!=null)Text(enrollmentFailureMessage(context.l10n,_failure!)),
      for(final school in _schools.where((row)=>'${row['name']}'.toLowerCase().contains(_search.trim().toLowerCase())))ListTile(title:Text('${school['name']}'),subtitle:Text(school['organization_id']==null?t('مستقلة','Independent'):t('تابعة لمؤسسة','Institution school')),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.of(context).push(MaterialPageRoute<void>(builder:(_)=>SchoolDirectorManagementScreen(schoolId:school['id']as int,schoolName:school['name']as String,repository:_repository)))),
      if(_cursor!=null)TextButton(onPressed:_loading?null:()=>_load(more:true),child:Text(t('تحميل المزيد','Load more'))),
    ])))));
  }
}
