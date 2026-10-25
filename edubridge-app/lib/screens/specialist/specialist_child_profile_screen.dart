import '../../l10n/l10n.dart';
import '../../utils/presentation_text.dart';

import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../features/adaptation/data/adaptation_permission_repository.dart';
import '../child_accessibility/child_accessibility_settings_screen.dart';
import '../../features/students/data/student_profile_repository.dart';
import '../../features/students/data/student_learning_metrics_repository.dart';
import '../../features/students/presentation/student_learning_metrics_cards.dart';
import '../../features/students/presentation/student_profile_action_card.dart';
import '../../features/students/presentation/student_profile_details_section.dart';
import '../../features/students/domain/student_profile.dart';
import '../../features/students/presentation/student_profile_labels.dart';
import '../../theme.dart';
import '../child_progress_screen.dart';
import '../child_lessons/child_lessons_screen.dart';
import '../weekly_report_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../plan_evaluation_screen.dart';
import '../evaluation/evaluation_sheet.dart';
import '../student_noor_screen.dart';
import 'specialist_screen.dart';

part 'specialist_child_profile_s08.dart';

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
  bool _canAdapt = false;
  bool _loading = true;
  Object? _error;
  int? _s08LessonsCount;
  int? _s08CompletionPct;

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
      _canAdapt = false;
      _error = null;
    });
    try {
      final profile = await _repository.load(
        _childId,
        allowAssignmentPreview: true,
      );
      final canAdapt =
          !profile.isAssignmentPreview &&
          await AdaptationPermissionRepository().canEdit(_childId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _canAdapt = canAdapt;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = SharedUiMessage.studentProfileRefreshFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted && _error == null && !_profile.isAssignmentPreview) {
      await _loadS08Metrics();
    }
  }

  Future<void> _loadS08Metrics() async {
    try {
      final metrics = await StudentLearningMetricsRepository().load(_childId);
      if (!mounted) return;
      setState(() {
        _s08LessonsCount = metrics.lessonsCount;
        _s08CompletionPct = metrics.completionPercent;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _s08LessonsCount = null;
        _s08CompletionPct = null;
      });
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
  Widget build(BuildContext context) =>
      _buildS08Scaffold(context, JisrColors.of(context));

  Widget _heroCard(
    JisrColors c, {
    required dynamic age,
    required String disability,
    required bool isPreview,
  }) {
    return Container(
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
                  _childName.isEmpty ? context.l10n.student : _childName,
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
                        if (age != null)
                          context.l10n.childAgeYears(age.toString()),
                        if (disability.isNotEmpty) disability,
                      ].join(' • ').isEmpty
                      ? context.l10n.studentInformation
                      : [
                          if (age != null)
                            context.l10n.childAgeYears(age.toString()),
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
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPreview
                    ? context.l10n.beforeAssignment
                    : context.l10n.underFollowUp,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Kept for backwards compatibility with existing child profile layout helpers.
  // ignore: unused_element
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

  Widget _chips(JisrColors c, String label, List<String> values, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w800, color: c.heading),
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
