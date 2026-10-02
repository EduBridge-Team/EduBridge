import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../child_progress_screen.dart';
import '../child_lessons/child_lessons_screen.dart';
import '../weekly_report_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../plan_evaluation_screen.dart';
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
      if (response.statusCode == 403) response = await ApiService.authGet('/children/$_childId/assignment-preview');
      final data = ApiService.decodeMap(response.body);
      if (response.statusCode != 200 || data['child'] is! Map) {
        throw Exception('تعذّر تحميل معلومات الطالب');
      }
      if (!mounted) return;
      setState(() => _child = Map<String, dynamic>.from(data['child'] as Map));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر تحديث معلومات الطالب. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _loading = false);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _childName.isEmpty ? 'ملف الطالب' : _childName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      bottomNavigationBar: const TeacherNavigationBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            ListTile(
              title: Text(_error!),
              trailing: TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
            ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.headerGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    _childName.isNotEmpty ? _childName.characters.first : '؟',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
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
                        _childName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        age == null ? 'العمر غير محدد' : '$age سنة',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            c,
            title: 'معلومات الطالب',
            children: [
              _row(c, 'ولي الأمر', (child['guardians'] as List? ?? []).map((guardian) => guardian['name']).join('، '), AppIcons.parent),
              if (_text(child['birth_date']).isNotEmpty)
                _row(c, 'تاريخ الميلاد', _text(child['birth_date']), Icons.cake_outlined),
              if (_text(child['gender']).isNotEmpty)
                _row(c, 'الجنس', switch (_text(child['gender'])) {
                  'male' => 'ذكر',
                  'female' => 'أنثى',
                  final value => value,
                }, Icons.person_outline),
              if (disability.isNotEmpty)
                _row(c, 'نوع الإعاقة', disability, Icons.accessibility_new),
              if (description.isNotEmpty)
                _row(c, 'وصف الإعاقة', description, AppIcons.info),
              if (preferredStyle.isNotEmpty)
                _row(c, 'أسلوب التعلم المفضّل', preferredStyle, AppIcons.lesson),
              if (specialNeeds.isNotEmpty)
                _row(c, 'الاحتياجات الخاصة', specialNeeds, AppIcons.support),
            ],
          ),
          if (notes.isNotEmpty || educationalPlan.isNotEmpty ||
              _text(child['assigned_teacher_name']).isNotEmpty ||
              _text(child['organization_name']).isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              c,
              title: 'فريق المتابعة والخطة التعليمية',
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
              children: [
                if (strengths.isNotEmpty)
                  _chips(c, 'نقاط القوة', strengths, AppColors.greenDeep),
                if (challenges.isNotEmpty)
                  _chips(c, 'التحديات', challenges, AppColors.orangeDeep),
              ],
            ),
          ],
          const SizedBox(height: 18),
          if (!_loading && _error == null && child['assignment_preview'] != true) ...[
          FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChildProgressScreen(
                  childId: _childId,
                  childName: _childName,
                ),
              ),
            ),
            icon: const Icon(AppIcons.progress),
            label: const Text('عرض التقدّم'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(icon: const Icon(AppIcons.lesson), label: const Text('دروس الطالب'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChildLessonsScreen(childId: _childId, childName: _childName)))),
          OutlinedButton.icon(icon: const Icon(AppIcons.progress), label: const Text('التقدم الأسبوعي وتقارير المعلم'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WeeklyReportScreen(childId: _childId, childName: _childName)))),
          OutlinedButton.icon(icon: const Icon(AppIcons.forum), label: const Text('مناقشة الحالة'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CaseDiscussionScreen(filterChildId: _childId)))),
          if (widget.onEvaluate != null) OutlinedButton.icon(icon: const Icon(AppIcons.evaluate), label: const Text('تقييم الطالب والخطة'),
            onPressed: () => widget.onEvaluate!(_child)),
          if (child['current_plan_id'] is int) OutlinedButton.icon(icon: const Icon(AppIcons.evaluate), label: const Text('تقييم الخطة الحالية'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlanEvaluationScreen(childId: _childId, childName: _childName, planId: child['current_plan_id'] as int)))),
          ],
          if (!_loading && _error == null && child['assignment_preview'] == true && widget.onAccept != null)
            FilledButton(onPressed: () async { await widget.onAccept!(_child); if (mounted) await _load(); }, child: const Text('قبول متابعة الطفل')),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _section(
    JisrColors c, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.heading,
            ),
          ),
          const SizedBox(height: 12),
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
          Icon(icon, size: 20, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: c.body, height: 1.5),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
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
