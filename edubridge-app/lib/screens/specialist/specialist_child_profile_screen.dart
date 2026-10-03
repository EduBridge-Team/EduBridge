import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../child_progress_screen.dart';
import '../child_lessons/child_lessons_screen.dart';
import '../weekly_report_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../plan_evaluation_screen.dart';
import '../evaluation/evaluation_sheet.dart';
import '../../widgets/teacher_navigation_bar.dart';

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
  late Map<String, dynamic> _child;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _childId = widget.child['id'] as int;
    _childName = (widget.child['name'] ?? '').toString();
    _child = Map<String, dynamic>.from(widget.child);
    _load();
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  List<String> _list(dynamic value) =>
      value is List ? value.map((e) => e.toString()).toList() : [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var response = await ApiService.authGet('/children/$_childId');
      if (response.statusCode == 403) {
        response = await ApiService.authGet('/children/$_childId/assignment-preview');
      }
      final data = ApiService.decodeMap(response.body);
      if (response.statusCode != 200 || data['child'] is! Map) {
        throw Exception('تعذّر تحميل معلومات الطالب');
      }
      if (!mounted) return;
      setState(() => _child = Map<String, dynamic>.from(data['child'] as Map));
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
    final child = _child;
    final age = child['age'];
    final disability = _text(child['disability_type']);
    final description = _text(child['disability_description']);
    final specialNeeds = _text(child['special_needs']);
    final preferredStyle = _text(child['preferred_learning_style']);
    final notes = _text(child['notes']);
    final plan = child['current_plan'];
    final educationalPlan = plan is Map ? _text(plan['educational_plan']) : '';
    final strengths = _list(child['strengths']);
    final challenges = _list(child['challenges']);
    final isPreview = child['assignment_preview'] == true;
    final guardianNames = (child['guardians'] as List? ?? [])
        .map((guardian) => guardian['name'])
        .where((name) => name != null && name.toString().trim().isNotEmpty)
        .join('، ');
    final hasMedicalReport = _text(child['medical_report_url']).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ملف الطالب',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: const TeacherNavigationBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
            const SizedBox(height: 14),
            _section(
              c,
              title: 'المعلومات الأساسية',
              icon: Icons.badge_outlined,
              children: [
                if (guardianNames.isNotEmpty)
                  _row(c, 'ولي الأمر', guardianNames, AppIcons.parent),
                if (_text(child['birth_date']).isNotEmpty)
                  _row(c, 'تاريخ الميلاد', _text(child['birth_date']), Icons.cake_outlined),
                if (_text(child['gender']).isNotEmpty)
                  _row(
                    c,
                    'الجنس',
                    switch (_text(child['gender'])) {
                      'male' => 'ذكر',
                      'female' => 'أنثى',
                      final value => value,
                    },
                    Icons.person_outline,
                  ),
                if (disability.isNotEmpty)
                  _row(c, 'نوع الإعاقة', disability, Icons.accessibility_new),
                if (description.isNotEmpty)
                  _row(c, 'وصف الإعاقة', description, AppIcons.info),
                if (preferredStyle.isNotEmpty)
                  _row(c, 'أسلوب التعلم المفضّل', preferredStyle, AppIcons.lesson),
                if (specialNeeds.isNotEmpty)
                  _row(c, 'الاحتياجات الخاصة', specialNeeds, AppIcons.support),
                if (hasMedicalReport)
                  _row(c, 'التقرير الطبي', 'مرفق مع ملف الطالب', Icons.description_outlined),
              ],
            ),
            if (notes.isNotEmpty ||
                educationalPlan.isNotEmpty ||
                _text(child['assigned_teacher_name']).isNotEmpty ||
                _text(child['organization_name']).isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(
                c,
                title: 'فريق المتابعة والخطة',
                icon: Icons.groups_outlined,
                children: [
                  if (_text(child['assigned_teacher_name']).isNotEmpty)
                    _row(c, 'المعلم', _text(child['assigned_teacher_name']), Icons.school_outlined),
                  if (_text(child['organization_name']).isNotEmpty)
                    _row(c, 'المؤسسة', _text(child['organization_name']), Icons.business_outlined),
                  if (educationalPlan.isNotEmpty)
                    _row(c, 'الخطة التعليمية', educationalPlan, AppIcons.lesson),
                  if (notes.isNotEmpty)
                    _row(c, 'ملاحظات', notes, AppIcons.info),
                ],
              ),
            ],
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
              if (child['current_plan_id'] is int)
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
                        planId: child['current_plan_id'] as int,
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
              _childName.isNotEmpty ? _childName.characters.first : '؟',
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
