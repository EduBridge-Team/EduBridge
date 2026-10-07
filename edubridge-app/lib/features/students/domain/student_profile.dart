/// Typed boundary for profile responses; unknown fields remain available to
/// existing evaluation/acceptance flows through an unchanged JSON copy.
class StudentProfile {
  StudentProfile.fromJson(Map<String, dynamic> json)
      : _json = Map.unmodifiable(Map<String, dynamic>.from(json));
  final Map<String, dynamic> _json;

  Object? get age => _json['age'];
  String get disability => _text('disability_type');
  String get description => _text('disability_description');
  String get specialNeeds => _text('special_needs');
  String get preferredStyle => _text('preferred_learning_style');
  String get notes => _text('notes');
  String get birthDate => _text('birth_date');
  String get gender => _text('gender');
  String get status => _text('status');
  bool get isAssignmentPreview => _json['assignment_preview'] == true;
  int? get currentPlanId => _json['current_plan_id'] is int
      ? _json['current_plan_id'] as int : null;
  String get educationalPlan {
    final plan = _json['current_plan'];
    return plan is Map ? _string(plan['educational_plan']) : '';
  }
  List<String> get strengths => _list('strengths');
  List<String> get challenges => _list('challenges');
  String get guardianNames => _names('guardians');
  String get specialistNames => _names('specialists');
  String get teacherName => _text('assigned_teacher_name').isNotEmpty
      ? _text('assigned_teacher_name') : _text('teacher_name');
  String get organizationName => _text('organization_name');
  String get childNationalId => _text('child_national_id');
  String get guardianNationalId => _text('guardian_national_id');
  String get guardianDocument => _text('guardian_id_document_url');
  String get kinshipDocument => _text('kinship_document_url');
  String get medicalReport => _text('medical_report_url');
  bool get hasDocuments => childNationalId.isNotEmpty || guardianNationalId.isNotEmpty ||
      guardianDocument.isNotEmpty || kinshipDocument.isNotEmpty || medicalReport.isNotEmpty;

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_json);

  String _text(String key) => _string(_json[key]);
  static String _string(Object? value) => (value ?? '').toString().trim();
  List<String> _list(String key) {
    final value = _json[key];
    return List.unmodifiable(value is List ? value.map((item) => item.toString()) : <String>[]);
  }
  String _names(String key) {
    final value = _json[key];
    if (value is! List) return '';
    return value.map((item) => item is Map ? _string(item['name']) : _string(item))
      .where((name) => name.isNotEmpty).join('، ');
  }
}
