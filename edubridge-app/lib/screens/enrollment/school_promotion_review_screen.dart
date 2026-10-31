import 'school_promotion_approval_screen.dart';
import 'package:flutter/material.dart';
import '../../model/schools/promotion_roster.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_promotion_roster_repository.dart';
import '../../theme.dart';
import 'school_promotion_history_screen.dart';

/// Local draft only. The server preview/approval flow is a separate phase.
class SchoolPromotionReviewScreen extends StatefulWidget {
  const SchoolPromotionReviewScreen({
    super.key, required this.sourceYearId, required this.targetYearId, this.gateway, this.enableApproval = false,
  });
  final int sourceYearId, targetYearId;
  final SchoolPromotionRosterGateway? gateway;
  final bool enableApproval;

  @override
  State<SchoolPromotionReviewScreen> createState() => _SchoolPromotionReviewScreenState();
}

class _SchoolPromotionReviewScreenState extends State<SchoolPromotionReviewScreen>
    with WidgetsBindingObserver {
  PromotionRoster? _roster;
  List<Map<String,dynamic>> _transferSchools = [];
  final _choices = <int, PromotionSelection>{};
  bool _loading = false;
  EnrollmentFailure? _failure;
  int _revision = 0;
  String _search = '';
  int? _sectionFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant SchoolPromotionReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway ||
        oldWidget.sourceYearId != widget.sourceYearId ||
        oldWidget.targetYearId != widget.targetYearId) _load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _failure = null;
      _roster = null;
      _choices.clear();
      _sectionFilter = null;
    });
    try {
      final gateway = widget.gateway ?? SchoolPromotionRosterRepository();
      final roster = await gateway.load(
        sourceYearId: widget.sourceYearId, targetYearId: widget.targetYearId);
      final schools = widget.enableApproval && gateway is SchoolTransferDirectoryGateway ? await (gateway as SchoolTransferDirectoryGateway).destinations() : <Map<String,dynamic>>[];
      if (!mounted || revision != _revision) return;
      setState(() { _transferSchools = schools; _roster = roster; _loading = false; });
    } on EnrollmentApiException catch (e) {
      if (!mounted || revision != _revision) return;
      setState(() { _loading = false; _failure = e.failure; });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() { _loading = false; _failure = EnrollmentFailure.network; });
    }
  }

  @override
  void dispose() {
    ++_revision;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _choose(PromotionStudent student, PromotionOutcome? outcome) {
    setState(() {
      if (outcome == null) {
        _choices.remove(student.enrollmentId);
      } else {
        _choices[student.enrollmentId] =
            PromotionSelection(student.enrollmentId, outcome, null);
      }
    });
  }

  void _transferSchool(PromotionStudent student, String value) {
    final previous = _choices[student.enrollmentId];
    if (previous == null || previous.outcome != PromotionOutcome.transferred) return;
    final school = int.tryParse(value.trim());
    setState(() {
      _choices[student.enrollmentId] = PromotionSelection(
        student.enrollmentId, previous.outcome, null, targetSchoolId: school);
    });
  }

  Future<void> _preview(PromotionDraft draft) async {
    if (!draft.ready) return;
    if (widget.enableApproval) {
      final result = await Navigator.of(context).push(MaterialPageRoute<Object?>(builder: (_) => SchoolPromotionApprovalScreen(draft: draft)));
      if (mounted && result != null) _load();
      return;
    }
    final snapshot = _roster;
    final revision = _revision;
    final payload = draft.previewJson();
    final en = Localizations.localeOf(context).languageCode == 'en';
    final counts = <PromotionOutcome, int>{
      for (final outcome in PromotionOutcome.values) outcome: 0,
    };
    for (final decision in draft.selections.values) {
      counts[decision.outcome] = counts[decision.outcome]! + 1;
    }
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(en ? 'Review decisions — not submitted' : 'معاينة القرارات — لم تُرسل'),
      content: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
          Text(en ? 'Promoted: ${counts[PromotionOutcome.promoted]}' :
              'ناجح: ${counts[PromotionOutcome.promoted]}'),
          Text(en ? 'Repeating: ${counts[PromotionOutcome.repeating]}' :
              'معيد: ${counts[PromotionOutcome.repeating]}'),
          Text(en ? 'Transferred: ${counts[PromotionOutcome.transferred]}' :
              'منقول: ${counts[PromotionOutcome.transferred]}'),
          const SizedBox(height: 8),
          for (final student in snapshot!.students)
            Text('${student.name}: ${draft.selections[student.enrollmentId]!.outcome.name}'),
          const SizedBox(height: 12),
          Text(en ? 'This is a local preview. No students have been moved or approved.' :
              'هذه معاينة محلية فقط. لم يُنقل أي طالب ولم يُعتمد الترفيع.'),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: Text(en ? 'Edit decisions' : 'تعديل القرارات')),
        FilledButton(onPressed: null, child: Text(en ? 'Final approval' : 'الاعتماد النهائي')),
      ],
    ));
    // A dialog never retains permission to act on an obsolete loaded roster.
    if (!mounted || revision != _revision || !identical(snapshot, _roster) ||
        !identical(draft.roster, _roster) || payload['roster_revision'] != _roster?.revision) return;
  }

  void _destination(PromotionStudent student, int? id) {
    final previous = _choices[student.enrollmentId];
    if (previous == null) return;
    setState(() {
      _choices[student.enrollmentId] =
          PromotionSelection(student.enrollmentId, previous.outcome, id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String tr(String ar, String english) => en ? english : ar;
    final roster = _roster;
    final draft = roster == null ? null : PromotionDraft(roster, _choices);
    final students = roster?.students.where((student) =>
      student.name.toLowerCase().contains(_search.trim().toLowerCase()) &&
      (_sectionFilter == null || student.sectionId == _sectionFilter)).toList() ?? [];
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(tr('مراجعة طلاب الترفيع', 'Review annual promotion')),
        actions: [IconButton(onPressed: _loading ? null : _load,
          tooltip: tr('تحديث', 'Refresh'), icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_loading) const LinearProgressIndicator(),
          if (_failure != null) Text(switch (_failure!) {
            EnrollmentFailure.unavailable => tr('قائمة الترفيع غير متاحة من الخادم بعد.', 'The promotion roster endpoint is not yet available.'),
            EnrollmentFailure.session => tr('انتهت الجلسة. أعد تسجيل الدخول.', 'Session expired. Sign in again.'),
            EnrollmentFailure.forbidden => tr('لا تملك صلاحية عرض طلاب المدرسة.', 'School roster access denied.'),
            EnrollmentFailure.invalidResponse => tr('قائمة الطلاب ناقصة أو غير مطابقة للمدرسة.', 'Incomplete or mismatched school roster.'),
            _ => tr('تعذر تحميل قائمة الطلاب. أعد المحاولة.', 'Unable to load student roster. Retry.'),
          }),
          if (roster != null) ...[
            OutlinedButton.icon(
              key: const ValueKey('promotion-history'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => SchoolPromotionHistoryScreen(
                  schoolId: roster.schoolId, yearId: roster.sourceYearId,
                ),
              )),
              icon: const Icon(Icons.history),
              label: Text(tr('سجل الترفيع السابق', 'Previous promotion history')),
            ),
            Text(tr('عدد الطلاب: ${roster.students.length}', 'Students: ${roster.students.length}'),
              style: Theme.of(context).textTheme.titleMedium),
            TextField(
              key: const ValueKey('promotion-search'),
              decoration: InputDecoration(labelText: tr('بحث بالاسم', 'Search by name'),
                prefixIcon: const Icon(Icons.search)),
              onChanged: (text) => setState(() => _search = text),
            ),
            DropdownButtonFormField<int>(
              key: const ValueKey('promotion-section-filter'),
              initialValue: _sectionFilter,
              decoration: InputDecoration(labelText: tr('تصفية حسب الشعبة', 'Filter by section')),
              items: [
                DropdownMenuItem(value: null, child: Text(tr('كل الشعب', 'All sections'))),
                for (final id in roster.students.map((s) => s.sectionId).toSet())
                  DropdownMenuItem(value: id, child: Text('${tr('الشعبة', 'Section')} $id')),
              ],
              onChanged: (value) => setState(() => _sectionFilter = value),
            ),
            if (students.isEmpty) Text(tr('لا يوجد طلاب مطابقون.', 'No matching students.')),
            for (final student in students)
              Card(
                key: ValueKey('promotion-student-${student.enrollmentId}'),
                child: Padding(padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text(student.name, style: Theme.of(context).textTheme.titleMedium),
                    Text('${tr('الشعبة الحالية', 'Current section')}: ${student.sectionId}'),
                    DropdownButtonFormField<PromotionOutcome>(
                      key: ValueKey('promotion-outcome-${student.enrollmentId}'),
                      initialValue: _choices[student.enrollmentId]?.outcome,
                      decoration: InputDecoration(labelText: tr('قرار الطالب', 'Student decision')),
                      items: [
                        DropdownMenuItem(value: PromotionOutcome.promoted,
                          child: Text(tr('ناجح', 'Promoted'))),
                        DropdownMenuItem(value: PromotionOutcome.repeating,
                          child: Text(tr('معيد', 'Repeating'))),
                        DropdownMenuItem(value: PromotionOutcome.transferred,
                          child: Text(tr('منقول', 'Transferred'))),
                      ],
                      onChanged: (outcome) => _choose(student, outcome),
                    ),
                    if (_choices[student.enrollmentId] != null &&
                        _choices[student.enrollmentId]!.outcome != PromotionOutcome.transferred)
                      DropdownButtonFormField<int>(
                        key: ValueKey('promotion-destination-${student.enrollmentId}-${_choices[student.enrollmentId]!.outcome.name}'),
                        initialValue: _choices[student.enrollmentId]!.targetSectionId,
                        decoration: InputDecoration(labelText: tr('الشعبة الجديدة', 'Target section')),
                        items: [
                          for (final section in roster.sections.where((section) =>
                            _choices[student.enrollmentId]!.outcome == PromotionOutcome.repeating
                              ? section.gradeId == student.gradeId
                              : section.gradeId != student.gradeId))
                            DropdownMenuItem(value: section.id, child: Text(section.name)),
                        ],
                        onChanged: (id) => _destination(student, id),
                      ),
                    if (_choices[student.enrollmentId]?.outcome == PromotionOutcome.transferred) ...[
                      if (widget.enableApproval) DropdownButtonFormField<int>(
                        key: ValueKey('promotion-transfer-school-${student.enrollmentId}'),
                        isExpanded: true, initialValue: _choices[student.enrollmentId]?.targetSchoolId,
                        decoration: InputDecoration(labelText: tr('المدرسة المقصودة', 'Intended destination school')),
                        items: _transferSchools.map((school) => DropdownMenuItem(value:school['id'] as int,child:Text(school['name'] as String))).toList(),
                        onChanged:(value)=>_transferSchool(student, '$value'),
                      ) else TextField(
                        key: ValueKey('promotion-transfer-school-${student.enrollmentId}'),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: tr(
                            'رقم المدرسة المنقول إليها', 'Destination school ID')),
                        onChanged: (value) => _transferSchool(student, value),
                      ),
                      if (!widget.enableApproval) Text(tr('رقم المدرسة مؤقت لحين توفير قائمة المدارس المصرّح بها من الخادم.',
                        'School ID is provisional until an authorized school directory is available.')),

                      if (widget.enableApproval) Text(tr('يحفظ هذا قرار الخروج من المدرسة فقط؛ قبول الوجهة وتسجيلها منفصلان.', 'This records the source-school exit only; destination acceptance and enrollment are separate.')),
                    ],
                  ])),
              ),
            const SizedBox(height: 12),
            Text(tr('قرارات مكتملة: ${_choices.length} / ${roster.students.length}',
              'Decisions selected: ${_choices.length} / ${roster.students.length}')),
            Text(draft!.ready
              ? (widget.enableApproval ? tr('القرارات جاهزة لمعاينة الخادم قبل الاعتماد.', 'Decisions are ready for server review before approval.') : tr('القرارات صالحة للمعاينة المحلية؛ الاعتماد غير متاح.', 'Local review is valid; server approval is unavailable.'))
              : tr('القرارات غير مكتملة أو تتعارض مع الوجهة أو السعة.', 'Decisions are incomplete or violate destination/capacity constraints.')),
            FilledButton.icon(
              key: const ValueKey('promotion-local-preview'),
              onPressed: draft.ready ? () => _preview(draft) : null,
              icon: const Icon(Icons.preview_outlined),
              label: Text(tr('معاينة القرارات', 'Preview decisions')),
            ),
            if (!widget.enableApproval) FilledButton(
              key: const ValueKey('promotion-approve'),
              onPressed: null,
              child: Text(tr('اعتماد الترفيع', 'Approve promotion')),
            ),
          ],
        ]),
      ))),
    );
  }
}
