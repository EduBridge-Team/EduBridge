/// Data needed to render a specialist dashboard, independent of widget state.
class SpecialistDashboardData {
  const SpecialistDashboardData({
    required this.rows,
    required this.lessons,
    required this.types,
    required this.teachers,
    required this.specialists,
    required this.specialty,
  });

  final List<Map<String, dynamic>> rows;
  final List lessons;
  final List types;
  final List teachers;
  final List specialists;
  final String? specialty;
}
