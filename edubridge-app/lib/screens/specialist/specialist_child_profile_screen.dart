import '../../utils/presentation_text.dart';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../features/students/data/student_profile_repository.dart';
import '../../features/students/domain/student_profile.dart';
import '../../features/students/presentation/student_profile_labels.dart';
import '../../theme.dart';
import '../child_progress_screen.dart';
import '../child_lessons/child_lessons_screen.dart';
import '../weekly_report_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../plan_evaluation_screen.dart';
import '../evaluation/evaluation_sheet.dart';

class SpecialistChildProfileScreen extends StatefulWidget {
  final Map<String, dynamic> child;
  final Future<void> Function(Map<String, dynamic>)? onEvaluate;
  final Future<void> Function(Map<String, dynamic>)? onAccept;

  const SpecialistChildProfileScreen({
    super.key,
    required this.child,
    this.onEvaluate,
    this.onAccept,
  });

  @override
  State<SpecialistChildProfileScreen> createState() =>
      _SpecialistChildProfileScreenState();
}

class _SpecialistChildProfileScreenState
    extends State<SpecialistChildProfileScreen> {
  late final int _childId;
  late final String _childName;
  final _repository = StudentProfileRepository();
  late StudentProfile _profile;
  Map<String, dynamic> get _child => _profile.toJson();
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _childId = widget.child['id'] as int;
    _childName = (widget.child['name'] ?? '').toString();
    _profile = StudentProfile.fromJson(widget.child);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _repository.load(_childId, allowAssignmentPreview: true);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = 'تعذّر تحديث معلومات الطالب. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _evaluate() async {
    if (widget.onEvaluate != null) {
      await widget.onEvaluate!(_child);
      return;
    }
    try {
      final teachers = await ApiService.getUsers(role: 'teacher');
      if (!mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => EvaluationSheet(
          child: _child,
          teachers: teachers,
          onSaved: (_) => _load(),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final child = _profile;
    final age = child.age;
    final disability = child.disability;
    final description = child.description;
    final specialNeeds = child.specialNeeds;
    final preferredStyle = child.preferredStyle;
    final notes = child.notes;
    final educationalPlan = child.educationalPlan;
    final strengths = child.strengths;
    final challenges = child.challenges;
    final guardianNames = child.guardianNames;
    final specialistNames = child.specialistNames;
    final teacherName = child.teacherName;
    final organizationName = child.organizationName;
    final isPreview = child.isAssignmentPreview;
    final childNationalId = child.childNationalId;
    final guardianNationalId = child.guardianNationalId;
    final guardianDocument = child.guardianDocument;
    final kinshipDocument = child.kinshipDocument;
    final medicalReport = child.medicalReport;
    final hasDocuments = child.hasDocuments;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 74,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _childName.isEmpty ? 'ملف الطالب' : 'ملف $_childName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_loading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                    ),
                    TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _heroCard(
              c,
              age: age,
              disability: disability,
              isPreview: isPreview,
            ),
            if (isPreview) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.brandBlue.withValues(alpha: .16),
                  ),
                ),
                child: const Text(
                  'هذه معلومات الحالة المتاحة قبل قبول المتابعة. بيانات الهوية والمستندات والتقرير الطبي تظهر للمختص بعد التعيين فقط.',
                  style: TextStyle(height: 1.5, fontSize: 12.5),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _section(
              c,
              title: 'معلومات الطالب',
              icon: Icons.badge_outlined,
              children: [
                _row(c, 'الاسم', _childName.isEmpty ? 'غير مضاف' : _childName,
                    Icons.person_outline),
                if (age != null) _row(c, 'العمر', '$age سنة', Icons.cake_outlined),
                if (child.birthDate.isNotEmpty)
                  _row(c, 'تاريخ الميلاد', child.birthDate, Icons.cake_outlined),
                if (child.gender.isNotEmpty)
                  _row(
                    c,
                    'الجنس',
                    switch (child.gender) {
                      'male' => 'ذكر',
                      'female' => 'أنثى',
                      final value => value,
                    },
                    Icons.person_outline,
                  ),
                _row(
                  c,
                  'نوع الإعاقة',
                  disability.isEmpty ? 'غير محدد' : disability,
                  Icons.accessibility_new,
                ),
                if (description.isNotEmpty)
                  _row(c, 'وصف الإعاقة', description, AppIcons.info),
                if (specialNeeds.isNotEmpty)
                  _row(c, 'احتياجات خاصة', specialNeeds, AppIcons.support),
                if (preferredStyle.isNotEmpty)
                  _row(c, 'أسلوب التعلم المفضّل', preferredStyle, AppIcons.lesson),
              ],
            ),
            if (strengths.isNotEmpty || challenges.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(
                c,
                title: 'نقاط القوة والتحديات',
                icon: Icons.auto_awesome_outlined,
                children: [
                  if (strengths.isNotEmpty)
                    _chips(c, 'نقاط القوة', strengths, AppColors.greenDeep),
                  if (challenges.isNotEmpty)
                    _chips(c, 'التحديات', challenges, AppColors.orangeDeep),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _section(
              c,
              title: 'فريق المتابعة والخطة',
              icon: Icons.groups_outlined,
              children: [
                if (guardianNames.isNotEmpty)
                  _row(c, 'ولي الأمر', guardianNames, AppIcons.parent),
                if (teacherName.isNotEmpty)
                  _row(c, 'المعلم المسؤول', teacherName, Icons.school_outlined),
                if (specialistNames.isNotEmpty)
                  _row(c, 'المختصون', specialistNames, AppIcons.specialist),
                if (organizationName.isNotEmpty)
                  _row(c, 'المؤسسة', organizationName, Icons.business_outlined),
                if (educationalPlan.isNotEmpty)
                  _row(c, 'الخطة التعليمية', educationalPlan, AppIcons.lesson),
                _row(c, 'الحالة', StudentProfileLabels.specialistStatus(child), Icons.info_outline),
                if (notes.isNotEmpty)
                  _row(c, 'ملاحظات', notes, AppIcons.info),
              ],
            ),
            if (hasDocuments && !isPreview) ...[
              const SizedBox(height: 14),
              _section(
                c,
                title: 'بيانات التوثيق والمستندات',
                icon: Icons.badge_outlined,
                children: [
                  if (childNationalId.isNotEmpty)
                    _row(c, 'رقم هوية الطفل', childNationalId, Icons.badge_outlined),
                  if (guardianNationalId.isNotEmpty)
                    _row(c, 'رقم هوية ولي الأمر', guardianNationalId, Icons.badge_outlined),
                  if (guardianDocument.isNotEmpty)
                    _row(c, 'صورة هوية ولي الأمر', 'مرفقة', Icons.attachment_outlined),
                  if (kinshipDocument.isNotEmpty)
                    _row(c, 'مستند صلة القرابة', 'مرفق', Icons.attachment_outlined),
                  if (medicalReport.isNotEmpty)
                    _row(c, 'التقرير الطبي', 'مرفق ومتاح للمختص المعيّن', Icons.description_outlined),
                ],
              ),
            ],
            if (!_loading && _error == null && !isPreview) ...[
              const SizedBox(height: 18),
              Text(
                'متابعة الطالب',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: c.heading,
                ),
              ),
              const SizedBox(height: 10),
              _actionTile(
                c,
                icon: AppIcons.progress,
                title: 'عرض التقدّم',
                subtitle: 'متابعة إنجاز الطالب وتطوره',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildProgressScreen(
                      childId: _childId,
                      childName: _childName,
                    ),
                  ),
                ),
              ),
              _actionTile(
                c,
                icon: AppIcons.lesson,
                title: 'دروس الطالب',
                subtitle: 'عرض الدروس والمواد التعليمية',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildLessonsScreen(
                      childId: _childId,
                      childName: _childName,
                    ),
                  ),
                ),
              ),
              _actionTile(
                c,
                icon: AppIcons.report,
                title: 'التقدم الأسبوعي وتقارير المعلم',
                subtitle: 'تقارير المعلم وسجل التقدم في مكان واحد',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyReportScreen(
                      childId: _childId,
                      childName: _childName,
                    ),
                  ),
                ),
              ),
              _actionTile(
                c,
                icon: AppIcons.forum,
                title: 'مناقشة الحالة',
                subtitle: 'التواصل مع فريق متابعة الطالب',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CaseDiscussionScreen(filterChildId: _childId),
                  ),
                ),
              ),
              _actionTile(
                c,
                icon: AppIcons.evaluate,
                title: 'تقييم الطالب والخطة',
                subtitle: 'إضافة أو مراجعة تقييم الطالب',
                onTap: _evaluate,
              ),
              if (child.currentPlanId != null)
                _actionTile(
                  c,
                  icon: Icons.fact_check_outlined,
                  title: 'تقييم الخطة الحالية',
                  subtitle: 'قياس فعالية الخطة التعليمية الحالية',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanEvaluationScreen(
                        childId: _childId,
                        childName: _childName,
                        planId: child.currentPlanId!,
                      ),
                    ),
                  ),
                ),
            ],
            if (!_loading &&
                _error == null &&
                isPreview &&
                widget.onAccept != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  await widget.onAccept!(_child);
                  if (mounted) await _load();
                },
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text(
                  'قبول متابعة الطفل',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _heroCard(
    JisrColors c, {
    required dynamic age,
    required String disability,
    required bool isPreview,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: .14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: Text(
              PresentationText.initial(_childName, fallback: '؟'),
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: AppColors.brandBlue,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _childName.isEmpty ? 'طالب' : _childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (age != null) '$age سنة',
                    if (disability.isNotEmpty) disability,
                  ].join(' • ').isEmpty
                      ? 'معلومات الطالب'
                      : [
                          if (age != null) '$age سنة',
                          if (disability.isNotEmpty) disability,
                        ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .88),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPreview ? 'قبل التعيين' : 'قيد المتابعة',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    JisrColors c, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: AppColors.brandBlue),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: c.heading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(JisrColors c, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: c.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: c.body,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    JisrColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: c.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: .09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.brandBlue, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: c.heading,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left_rounded, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chips(
    JisrColors c,
    String label,
    List<String> values,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values
                .map(
                  (value) => Chip(
                    label: Text(value),
                    side: BorderSide(color: color.withValues(alpha: .25)),
                    backgroundColor: color.withValues(alpha: .08),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
