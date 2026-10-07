import '../domain/student_profile.dart';

/// Keep the existing specialist and teacher display conventions explicit.
class StudentProfileLabels {
  static String specialistStatus(StudentProfile profile) {
    if (profile.isAssignmentPreview) return 'قبل التعيين';
    return switch (profile.status.toLowerCase()) {
      'pending' => 'بانتظار التقييم',
      'active' => 'قيد المتابعة',
      'completed' || 'done' => 'مكتمل',
      _ => profile.status.isEmpty ? 'قيد المتابعة' : profile.status,
    };
  }
  static String teacherStatus(StudentProfile profile) => switch (profile.status.toLowerCase()) {
    'pending' => 'بانتظار التقييم',
    'assigned' || 'active' => 'قيد المتابعة',
    'evaluated' => 'تم التقييم',
    'completed' || 'done' => 'مكتمل',
    _ => profile.status,
  };
  static List<String> teacherList(List<String> values) => List.unmodifiable(
    values.map((value) => value.trim()).where((value) => value.isNotEmpty));
}
