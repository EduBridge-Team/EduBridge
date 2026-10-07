import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

class TeacherChildProfileScreen extends StatefulWidget {
  final Map<String, dynamic> child;

  const TeacherChildProfileScreen({
    super.key,
    required this.child,
  });

  @override
  State<TeacherChildProfileScreen> createState() => _TeacherChildProfileScreenState();
}

class _TeacherChildProfileScreenState extends State<TeacherChildProfileScreen> {
  late Map<String, dynamic> _child;
  bool _loading = true;
  String? _error;

  int get _childId => widget.child['id'] as int;
  String get _childName => (widget.child['name'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _child = Map<String, dynamic>.from(widget.child);
    _load();
  }

  String _text(dynamic value) => (value ?? '').toString().trim();

  List<String> _list(dynamic value) => value is List
      ? value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
      : const [];

  String _names(dynamic value) {
    if (value is! List) return '';
    return value
        .map((item) => item is Map ? _text(item['name']) : _text(item))
        .where((name) => name.isNotEmpty)
        .join('، ');
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await ApiService.authGet('/children/$_childId');
      final data = ApiService.decodeMap(response.body);
      if (response.statusCode != 200 || data['child'] is! Map) {
        throw Exception('تعذّر تحميل ملف الطالب');
      }
      if (!mounted) return;
      setState(() => _child = Map<String, dynamic>.from(data['child'] as Map));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر تحديث معلومات الطالب. حاول مرة أخرى.');
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
    final strengths = _list(child['strengths']);
    final challenges = _list(child['challenges']);
    final guardianNames = _names(child['guardians']);
    final specialistNames = _names(child['specialists']);
    final teacherName = _text(child['assigned_teacher_name']).isNotEmpty
        ? _text(child['assigned_teacher_name'])
        : _text(child['teacher_name']);
    final organizationName = _text(child['organization_name']);
    final plan = child['current_plan'];
    final educationalPlan = plan is Map ? _text(plan['educational_plan']) : '';
    final status = _text(child['status']);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.red.withValues(alpha: .15)),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error, color: AppColors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                    TextButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _hero(c, age: age, disability: disability),
            const SizedBox(height: 14),
            _section(
              c,
              title: 'المعلومات الأساسية',
              icon: Icons.badge_outlined,
              children: [
                _row(c, 'الاسم', _childName.isEmpty ? 'غير مضاف' : _childName, Icons.person_outline),
                if (age != null) _row(c, 'العمر', '$age سنة', Icons.cake_outlined),
                if (_text(child['birth_date']).isNotEmpty)
                  _row(c, 'تاريخ الميلاد', _text(child['birth_date']), Icons.calendar_today_outlined),
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
                _row(
                  c,
                  'نوع الإعاقة',
                  disability.isEmpty ? 'غير محدد' : disability,
                  Icons.accessibility_new_rounded,
                ),
                if (description.isNotEmpty)
                  _row(c, 'وصف الإعاقة', description, AppIcons.info),
                if (specialNeeds.isNotEmpty)
                  _row(c, 'الاحتياجات الخاصة', specialNeeds, AppIcons.support),
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
                  _row(c, 'المعلم المسؤول', teacherName, AppIcons.teacher),
                if (specialistNames.isNotEmpty)
                  _row(c, 'المختصون', specialistNames, AppIcons.specialist),
                if (organizationName.isNotEmpty)
                  _row(c, 'المؤسسة', organizationName, Icons.business_outlined),
                if (educationalPlan.isNotEmpty)
                  _row(c, 'الخطة التعليمية', educationalPlan, AppIcons.lesson),
                if (status.isNotEmpty)
                  _row(c, 'الحالة', _statusLabel(status), Icons.info_outline),
                if (notes.isNotEmpty)
                  _row(c, 'ملاحظات تعليمية', notes, AppIcons.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status.toLowerCase()) {
        'pending' => 'بانتظار التقييم',
        'assigned' || 'active' => 'قيد المتابعة',
        'evaluated' => 'تم التقييم',
        'completed' || 'done' => 'مكتمل',
        _ => status,
      };

  Widget _hero(JisrColors c, {dynamic age, required String disability}) {
    final initial = _childName.trim().isEmpty ? '؟' : _childName.trim().characters.first;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.brandBlue,
                fontSize: 30,
                fontWeight: FontWeight.w900,
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
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    if (age != null) '$age سنة',
                    if (disability.isNotEmpty) disability,
                  ].join(' • '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brandBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.heading,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(JisrColors c, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandBlue),
          const SizedBox(width: 9),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: c.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: c.heading,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips(JisrColors c, String label, List<String> items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: c.heading,
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: items
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: color.withValues(alpha: .18)),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
