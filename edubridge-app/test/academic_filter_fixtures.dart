import 'package:edubridge_app/model/schools/academic_catalog.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/academic_repository.dart';

const currentYearName = '2026/2027 — العام الدراسي الجديد';
const previousYearName = '2025/2026 — العام الدراسي السابق';
const firstGradeName = 'Grade 2 — الصف الثاني الأساسي للتعليم الدامج';
const secondGradeName = 'Grade 3 — الصف الثالث الأساسي للتعليم الدامج';

AcademicCatalog filterCatalog({bool removeYear = false, int school = 10}) =>
    AcademicCatalog.fromJson({
      'school': {'id': school, 'name': 'School A'},
      'academic_years': [
        {
          'id': 1,
          'school_id': school,
          'name': currentYearName,
          'starts_on': '2026-09-01',
          'ends_on': '2027-06-30',
          'is_current': true,
        },
        if (!removeYear)
          {
            'id': 4,
            'school_id': school,
            'name': previousYearName,
            'starts_on': '2025-09-01',
            'ends_on': '2026-06-30',
            'is_current': false,
          },
      ],
      'grades': [
        {'id': 2, 'school_id': school, 'name': firstGradeName},
        {'id': 5, 'school_id': school, 'name': secondGradeName},
      ],
      'sections': [
        for (final entry in [
          [3, 1, 2],
          if (!removeYear) ...[
            [6, 4, 2],
            [7, 4, 5],
          ],
        ])
          {
            'id': entry[0],
            'school_id': school,
            'name': 'Section ${entry[0]}',
            'academic_year_id': entry[1],
            'grade_id': entry[2],
            'capacity': 30,
          },
      ],
    });

class FilterAcademicGateway implements AcademicGateway {
  AcademicCatalog data = filterCatalog();
  int reads = 0, writes = 0;
  bool failRead = false;
  @override
  Future<AcademicCatalog> load() async {
    reads++;
    if (failRead) {
      throw const EnrollmentApiException(EnrollmentFailure.unavailable);
    }
    return data;
  }

  @override
  Future<void> create(int schoolId, AcademicDraft draft) async {
    writes++;
  }
}
