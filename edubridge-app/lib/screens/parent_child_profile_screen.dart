import 'package:flutter/material.dart';

import '../app_icons.dart';
import '../l10n/l10n.dart';
import '../model/enrollment/enrollment_models.dart';
import '../services/api_service.dart';
import '../services/enrollment/enrollment_repository.dart';
import '../theme.dart';
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
      appBar: BrandAppBar(title: Text(name), leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(age == null ? l10n.notAvailable : l10n.childAgeYears(age.toString())),
                        const SizedBox(height: 8),
                        FutureBuilder<ParentEnrollmentHistory>(
                          future: _enrollment,
                          builder: (context, snapshot) {
                            final school = snapshot.data?.activeEnrollment?.schoolName;
                            final schoolLabel = school ??
                                (snapshot.connectionState == ConnectionState.waiting
                                    ? '…'
                                    : l10n.notAvailable);
                            return Text('${l10n.schoolAccountName}: $schoolLabel');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final (icon, label, builder) in actions)
                  OutlinedButton.icon(
                    onPressed: () => _open(builder),
                    icon: Icon(icon),
                    label: Text(label, textAlign: TextAlign.center),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _open((_) => ParentEnrollmentScreen(childId: id, childName: name));
                    if (mounted) setState(() => _enrollment = _loadEnrollment());
                  },
                  icon: const Icon(Icons.school_outlined),
                  label: Text(l10n.enrollmentParentTitle, textAlign: TextAlign.center),
                ),
                TextButton.icon(
                  onPressed: _editChild,
                  icon: const Icon(AppIcons.edit),
                  label: Text(l10n.editDetails),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
