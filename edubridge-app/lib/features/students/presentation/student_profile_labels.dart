import 'package:flutter/widgets.dart' show Locale;
import '../../../l10n/generated/app_localizations.dart';
import '../domain/student_profile.dart';

/// Keep the existing specialist and teacher display conventions explicit.
class StudentProfileLabels {
  static String specialistStatus(StudentProfile profile, {AppLocalizations? strings}) {
    final s = strings ?? lookupAppLocalizations(const Locale('ar'));
    if (profile.isAssignmentPreview) return s.beforeAssignment;
    return switch (profile.status.toLowerCase()) {
      'pending' => s.awaitingAssessment,
      'assigned' => s.assignedStatus,
      'active' => s.underFollowUp,
      'completed' || 'done' => s.completedStatus,
      _ => profile.status.isEmpty ? s.underFollowUp : profile.status,
    };
  }
  static String teacherStatus(StudentProfile profile, {AppLocalizations? strings}) {
    final s = strings ?? lookupAppLocalizations(const Locale('ar'));
    return switch (profile.status.toLowerCase()) {
    'pending' => s.awaitingAssessment,
    'assigned' || 'active' => s.underFollowUp,
    'evaluated' => s.evaluatedStatus,
    'completed' || 'done' => s.completedStatus,
    _ => profile.status,
    };
  }
  static List<String> teacherList(List<String> values) => List.unmodifiable(
    values.map((value) => value.trim()).where((value) => value.isNotEmpty));
}
