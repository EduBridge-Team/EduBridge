import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../l10n/l10n.dart';
import '../model/enrollment/enrollment_models.dart';
import '../services/api_service.dart';
import '../services/enrollment/enrollment_repository.dart';
import '../theme.dart';
import '../utils/presentation_text.dart';
import 'care_team_screen.dart';
import 'child_homework/child_homework_screen.dart';
import 'child_lessons/child_lessons_screen.dart';
import 'child_progress_screen.dart';
import 'create_learning_support_request_screen.dart';
import 'edit_child_screen.dart';
import 'educational_games_screen.dart';
import 'enrollment/parent_enrollment_screen.dart';
import 'weekly_report_screen.dart';

class ParentChildProfileScreen extends StatefulWidget {
  const ParentChildProfileScreen({
    super.key,
    required this.child,
    required this.childId,
  });

  final Map<dynamic, dynamic> child;
  final int childId;

  @override
  State<ParentChildProfileScreen> createState() => _ParentChildProfileScreenState();
}

class _ParentChildProfileScreenState extends State<ParentChildProfileScreen> {
  late Map<dynamic, dynamic> _child = widget.child;
  late Future<ParentEnrollmentHistory> _enrollment = _loadEnrollment();

  Future<ParentEnrollmentHistory> _loadEnrollment() =>
      ParentEnrollmentRepository(childId: widget.childId).load();

  Future<void> _open(WidgetBuilder builder) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: builder));

  Future<void> _editChild() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditChildScreen(
          child: _child,
          currentUserRole: 'parent',
          currentUser: {},
        ),
      ),
    );
    if (saved != true || !mounted) return;
    final updated = await ApiService.getChildDetails(widget.childId);
    if (mounted && updated != null && updated['id'] == widget.childId) {
      setState(() => _child = {..._child, ...updated});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.childId;
    final name = (_child['name'] ?? '').toString();
    final age = int.tryParse(_child['age'].toString());
    final actions = <(IconData, String, WidgetBuilder)>[
      (AppIcons.users, l10n.team, (_) => CareTeamScreen(childId: id, childName: name)),
      (AppIcons.lesson, l10n.lessons, (_) => ChildLessonsScreen(
        childId: id,
        childName: name,
        age: age ?? 8,
        disabilityType: _child['disability_type']?.toString(),
        parentPhone: _child['parent_phone']?.toString(),
      )),
      (AppIcons.homework, l10n.homework, (_) => ChildHomeworkScreen(childId: id, childName: name)),
      (Icons.sports_esports_outlined, l10n.gameCatalogTitle, (_) => EducationalGamesScreen(
        childId: id,
        childName: name,
        age: age ?? 8,
      )),
      (AppIcons.report, l10n.report, (_) => WeeklyReportScreen(childId: id, childName: name)),
      (AppIcons.progress, l10n.progress, (_) => ChildProgressScreen(childId: id, childName: name)),
      (AppIcons.specialist, l10n.requestLearningSupport, (_) =>
          CreateLearningSupportRequestScreen(childId: id, childName: name)),
    ];

    return Scaffold(
      appBar: BrandAppBar(
        title: Text(
          name.isEmpty ? l10n.studentProfile : l10n.studentProfileFor(name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.appBarGradient,
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
                        radius: 30,
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.brandBlue,
                        child: Text(PresentationText.initial(name, trim: true)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.start,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                age == null
                                    ? l10n.notAvailable
                                    : l10n.childAgeYears(age.toString()),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<ParentEnrollmentHistory>(
                                future: _enrollment,
                                builder: (context, snapshot) {
                                  final school =
                                      snapshot.data?.activeEnrollment?.schoolName;
                                  final schoolLabel = school ??
                                      (snapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? '…'
                                          : l10n.notAvailable);
                                  return Text(
                                    '${l10n.schoolAccountName}: $schoolLabel',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final (icon, label, builder) in actions)
                  _ProfileActionCard(
                    onPressed: () => _open(builder),
                    icon: icon,
                    label: label,
                  ),
                _ProfileActionCard(
                  onPressed: () async {
                    await _open((_) => ParentEnrollmentScreen(childId: id, childName: name));
                    if (mounted) setState(() => _enrollment = _loadEnrollment());
                  },
                  icon: Icons.school_outlined,
                  label: l10n.enrollmentParentTitle,
                ),
                _ProfileActionCard(
                  onPressed: _editChild,
                  icon: AppIcons.edit,
                  label: l10n.editDetails,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = JisrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.card,
          foregroundColor: colors.heading,
          side: BorderSide(color: colors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.tintTeal,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.infoText, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, textAlign: TextAlign.start)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: colors.muted, size: 16),
          ],
        ),
      ),
    );
  }
}
