import '../../l10n/l10n.dart';
import '../../utils/presentation_text.dart';
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../features/students/data/student_profile_repository.dart';
import '../../features/students/domain/student_profile.dart';
import '../../features/students/presentation/student_profile_labels.dart';
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
  final _repository = StudentProfileRepository();
  late StudentProfile _profile;
  bool _loading = true;
  Object? _error;

  int get _childId => widget.child['id'] as int;
  String get _childName => (widget.child['name'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _profile = StudentProfile.fromJson(widget.child);
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final profile = await _repository.load(_childId);
      if (!mounted) return;
      setState(() => _profile = profile);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = SharedUiMessage.studentProfileRefreshFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final strengths = StudentProfileLabels.teacherList(child.strengths);
    final challenges = StudentProfileLabels.teacherList(child.challenges);
    final guardianNames = child.guardianNames;
    final specialistNames = child.specialistNames;
    final teacherName = child.teacherName;
    final organizationName = child.organizationName;
    final status = child.status;

    return Scaffold(
      appBar: BrandAppBar(
        toolbarHeight: 76,
        elevation: 0,
        title: Text(
          _childName.isEmpty ? context.l10n.studentProfile : context.l10n.studentProfileFor(_childName),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
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
                        context.sharedMessage(_error),
                        style: const TextStyle(color: AppColors.red),
                      ),
                    ),
                    TextButton(onPressed: _load, child: Text(context.l10n.retryAction)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _hero(c, age: age, disability: disability),
            const SizedBox(height: 14),
            _section(
              c,
              title: context.l10n.basicInformation,
              icon: Icons.badge_outlined,
              children: [
                _row(c, context.l10n.name, _childName.isEmpty ? context.l10n.notAdded : _childName, Icons.person_outline),
                if (age != null) _row(c, context.l10n.age, context.l10n.childAgeYears(age.toString()), Icons.cake_outlined),
                if (child.birthDate.isNotEmpty)
                  _row(c, context.l10n.birthDate, child.birthDate, Icons.calendar_today_outlined),
                if (child.gender.isNotEmpty)
                  _row(
                    c,
                    context.l10n.gender,
                    switch (child.gender) {
                      'male' => context.l10n.male,
                      'female' => context.l10n.female,
                      final value => value,
                    },
                    Icons.person_outline,
                  ),
                _row(
                  c,
                  context.l10n.disabilityType,
                  disability.isEmpty ? context.l10n.notSpecified : disability,
                  Icons.accessibility_new_rounded,
                ),
                if (description.isNotEmpty)
                  _row(c, context.l10n.disabilityDescription, description, AppIcons.info),
                if (specialNeeds.isNotEmpty)
                  _row(c, context.l10n.specialNeeds, specialNeeds, AppIcons.support),
                if (preferredStyle.isNotEmpty)
                  _row(c, context.l10n.preferredLearningStyle, preferredStyle, AppIcons.lesson),
              ],
            ),
            if (strengths.isNotEmpty || challenges.isNotEmpty) ...[
              const SizedBox(height: 14),
              _section(
                c,
                title: context.l10n.strengthsChallenges,
                icon: Icons.auto_awesome_outlined,
                children: [
                  if (strengths.isNotEmpty)
                    _chips(c, context.l10n.strengths, strengths, AppColors.greenDeep),
                  if (challenges.isNotEmpty)
                    _chips(c, context.l10n.challenges, challenges, AppColors.orangeDeep),
                ],
              ),
            ],
            const SizedBox(height: 14),
            _section(
              c,
              title: context.l10n.followUpTeamPlan,
              icon: Icons.groups_outlined,
              children: [
                if (guardianNames.isNotEmpty)
                  _row(c, context.l10n.parentRole, guardianNames, AppIcons.parent),
                if (teacherName.isNotEmpty)
                  _row(c, context.l10n.assignedTeacher, teacherName, AppIcons.teacher),
                if (specialistNames.isNotEmpty)
                  _row(c, context.l10n.specialists, specialistNames, AppIcons.specialist),
                if (organizationName.isNotEmpty)
                  _row(c, context.l10n.institutionRole, organizationName, Icons.business_outlined),
                if (educationalPlan.isNotEmpty)
                  _row(c, context.l10n.educationalPlan, educationalPlan, AppIcons.lesson),
                if (status.isNotEmpty)
                  _row(c, context.l10n.status, StudentProfileLabels.teacherStatus(child, strings: context.l10n), Icons.info_outline),
                if (notes.isNotEmpty)
                  _row(c, context.l10n.learningNotes, notes, AppIcons.info),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(JisrColors c, {dynamic age, required String disability}) {
    final initial = PresentationText.initial(_childName, trim: true, fallback: '؟');
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
                    if (age != null) context.l10n.childAgeYears(age.toString()),
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
