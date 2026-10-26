import 'package:edubridge_app/model/schools/teacher_assignment.dart';
import 'package:edubridge_app/screens/institution_teacher_assignments/institution_teacher_assignments_controller.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'institution_teacher_assignments_fixture.dart';

const draft = TeacherAssignmentDraft(teacherId: 7, sectionId: 30, subjectId: 50);
void main() {
  test('exact institution POST confirmed by scoped participants read', () async {
    final fixture = InstitutionAssignmentsFixture();
    final repository = fixture.repository;
    await repository.create(draft);
    expect(fixture.writes.single, draft.toJson());
    final data = await repository.load();
    expect(data.assignments.single.draft.identity, draft.identity);
    expect(data.sectionLabel(30), contains('الصف الثاني'));
    await expectLater(repository.create(draft), throwsA(isA<EnrollmentApiException>()));
    expect(fixture.writes, hasLength(1));
  });
  for (final failure in ['context', 'teacher', 'section', 'subject', 'receipt', 'foreign', 'status']) {
    test('$failure cannot confirm a save or replay POST', () async {
      final fixture = InstitutionAssignmentsFixture();
      final controller = InstitutionTeacherAssignmentsController(fixture.repository);
      addTearDown(controller.dispose);
      await controller.reload();
      switch (failure) {
        case 'context': fixture.academic.slug = 'other-institution'; break;
        case 'teacher': fixture.teachers.clear(); break;
        case 'section': fixture.academic.data['sections'] = []; break;
        case 'subject':
          fixture.academic.data['subjects'] = [];
          break;
        case 'receipt': fixture.confirm = false; break;
        case 'foreign': fixture.tamper = true; break;
        case 'status': fixture.status = 503; break;
      }
      expect(await controller.create(draft), isFalse);
      expect(controller.saved, isFalse);
      expect(controller.snapshot, isNull);
      final count = fixture.writes.length;
      expect(count, failure == 'receipt' || failure == 'foreign' || failure == 'status' ? 1 : 0);
      await controller.reload();
      expect(fixture.writes, hasLength(count));
    });
  }
}
