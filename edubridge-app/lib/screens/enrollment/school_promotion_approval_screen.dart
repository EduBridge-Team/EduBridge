import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/schools/promotion_roster.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_promotion_operation_repository.dart';
import '../../theme.dart';
import 'enrollment_labels.dart';

class SchoolPromotionApprovalScreen extends StatefulWidget {
  const SchoolPromotionApprovalScreen({super.key, required this.draft, this.gateway});
  final PromotionDraft draft;
  final SchoolPromotionOperationGateway? gateway;
  @override
  State<SchoolPromotionApprovalScreen> createState() => _SchoolPromotionApprovalScreenState();
}
class _SchoolPromotionApprovalScreenState extends State<SchoolPromotionApprovalScreen> with WidgetsBindingObserver {
  late SchoolPromotionOperationGateway _gateway;
  SchoolPromotionServerPreview? _preview;
  SchoolPromotionReceipt? _receipt;
  EnrollmentFailure? _failure;
  bool _busy = false, _approving = false, _confirmed = false, _uncertain = false;
  int _version = 0;
  late final String _key;
  @override
  void initState() {
    super.initState(); WidgetsBinding.instance.addObserver(this);
    _gateway = widget.gateway ?? SchoolPromotionOperationRepository();
    final random = Random.secure();
    _key = base64UrlEncode(List<int>.generate(24, (_) => random.nextInt(256))).replaceAll('=', '');
    _load();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed && !_busy && !_uncertain && _receipt == null) _load(); }
  @override
  void dispose() { ++_version; WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _load() async {
    final version = ++_version;
    setState(() { _busy = true; _preview = null; _confirmed = false; _failure = null; });
    try { final preview = await _gateway.preview(widget.draft); if (mounted && version == _version) setState(() => _preview = preview); }
    on EnrollmentApiException catch (error) { if (mounted && version == _version) setState(() => _failure = error.failure); }
    finally { if (mounted && version == _version) setState(() => _busy = false); }
  }
  Future<void> _approve() async {
    if (_busy || !_confirmed || _preview == null || _uncertain) return;
    setState(() { _busy = true; _approving = true; _failure = null; });
    try { final receipt = await _gateway.approve(widget.draft, _preview!, _key); _verifyReceipt(receipt); if (mounted) setState(() => _receipt = receipt); }
    on EnrollmentApiException catch (error) {
      if (mounted) setState(() { _failure = error.failure; _uncertain = error.failure == EnrollmentFailure.uncertain || error.failure == EnrollmentFailure.invalidResponse || error.failure == EnrollmentFailure.server; _preview = null; _confirmed = false; });
    } finally { if (mounted) setState(() { _busy = false; _approving = false; }); }
  }
  Future<void> _recover() async {
    if (_busy) return;
    setState(() { _busy = true; _failure = null; });
    try { final receipt = await _gateway.operation(_key, schoolId: widget.draft.roster.schoolId); _verifyReceipt(receipt); if (mounted) setState(() { _receipt = receipt; _uncertain = false; }); }
    on EnrollmentApiException catch (error) { if (mounted) setState(() => _failure = error.failure); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  void _verifyReceipt(SchoolPromotionReceipt receipt) {
    final roster = widget.draft.roster;
    if (!receipt.completed || receipt.schoolId != roster.schoolId ||
        receipt.sourceYearId != roster.sourceYearId || receipt.targetYearId != roster.targetYearId ||
        receipt.promoted + receipt.repeating + receipt.transferred != roster.students.length) {
      throw const EnrollmentApiException(EnrollmentFailure.uncertain);
    }
  }
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    final labels = {PromotionOutcome.promoted:t('ناجح','Promoted'),PromotionOutcome.repeating:t('معيد','Repeating'),PromotionOutcome.transferred:t('خروج من المدرسة','Leaving this school')};
    return PopScope(canPop: !_approving, child: Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(t('اعتماد الترفيع السنوي','Approve annual progression'))),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth:840),child:ListView(padding:const EdgeInsets.all(16),children:[
        if(_busy)const LinearProgressIndicator(),
        if(_failure!=null)Text(enrollmentFailureMessage(context.l10n,_failure!)),
        for(final student in widget.draft.roster.students)Text('${student.name} — ${labels[widget.draft.selections[student.enrollmentId]!.outcome]}'),
        const SizedBox(height:16),
        Text(t('النقل خارج المدرسة يحفظ قرار الخروج فقط. موافقة ولي الأمر وقبول المدرسة المستقبلة وتسجيل الطالب فيها إجراءات منفصلة.', 'A transfer records the source-school exit only. Guardian consent and destination-school acceptance/enrollment are separate steps.')),
        if(_receipt!=null)...[
          Text(t('اكتملت العملية وحُفظ السجل السابق.','Operation completed and previous records preserved.'),key:const ValueKey('promotion-server-success')),
          Text('${t('ناجح','Promoted')}: ${_receipt!.promoted} — ${t('معيد','Repeating')}: ${_receipt!.repeating} — ${t('خروج','Leaving')}: ${_receipt!.transferred}'),
          SelectableText(_receipt!.operationId),
          FilledButton(onPressed:()=>Navigator.pop(context,_receipt),child:Text(t('عودة إلى السجل','Return to roster'))),
        ]else if(_uncertain)...[
          Text(t('نتيجة الاعتماد غير مؤكدة. تحقق من العملية أو السجل قبل أي محاولة جديدة.', 'Approval outcome is uncertain. Check the operation or history before any new attempt.')),
          OutlinedButton(onPressed:_busy?null:_recover,child:Text(t('التحقق من النتيجة','Check outcome'))),
        ]else if(_preview!=null)...[
          CheckboxListTile(key:const ValueKey('promotion-confirm-review'),value:_confirmed,onChanged:_busy?null:(value)=>setState(()=>_confirmed=value==true),title:Text(t('راجعت كل الطلاب والوجهات وأوافق على الاعتماد.', 'I reviewed every student and destination and approve these decisions.'))),
          FilledButton(key:const ValueKey('promotion-server-approve'),onPressed:_busy||!_confirmed?null:_approve,child:Text(t('اعتماد نهائي','Final approval'))),
        ]else OutlinedButton(onPressed:_busy?null:_load,child:Text(t('إعادة معاينة الخادم','Refresh server preview'))),
      ])))),
    ));
  }
}
