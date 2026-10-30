import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/class_lessons/class_lesson_assignment.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'class_assignment_fixture.dart';

const assignmentKey = '0123456789abcdef0123456789abcdef';
Matcher assignmentFailure(EnrollmentFailure failure) => isA<EnrollmentApiException>().having((e) => e.failure, 'failure', failure);
void main() {
  test('assigns whole roster with independent optional goal/adaptation and verifies read', () async {
    final f = ClassAssignmentFixture();
    final gateway = f.repository, options = await gateway.load();
    expect(await gateway.assign(options, f.draft(options), assignmentKey), 77);
    expect(f.posts, 1); expect(f.reads, 2);
    expect(f.body!['expected_revision'], 'r1');
    final students = f.body!['students'] as List;
    expect(students[0]['iep_goal']['goal_id'], 103); expect(students[0]['adaptation'], 'وقت إضافي');
    expect(students[1]['iep_goal'], isNull); expect(students[1]['adaptation'], '');
    expect(() => options.students.clear(), throwsUnsupportedError);
    expect(() => options.lessons.clear(), throwsUnsupportedError);
  });
  for (final mode in ['foreign', 'draft', 'old', 'duplicate-child', 'duplicate-lesson', 'wrong-scope', 'contract', 'incomplete']) {
    test('rejects invalid options $mode', () async {
      final f = ClassAssignmentFixture();
      final student = (f.data['students'] as List).first as Map, goal = ((f.data['students'] as List).first['goals'] as List).first as Map;
      if (mode == 'foreign') goal['child_id'] = 200;
      if (mode == 'draft') goal['version_status'] = 'draft';
      if (mode == 'old') goal['is_current_approved'] = false;
      if (mode == 'duplicate-child') (f.data['students'] as List).add(assignmentJson(student));
      if (mode == 'duplicate-lesson') (f.data['lessons'] as List).add(assignmentJson((f.data['lessons'] as List).first));
      if (mode == 'wrong-scope') f.data['school_id'] = 2;
      if (mode == 'contract') f.data['contract_version'] = 2;
      if (mode == 'incomplete') f.data['complete'] = false;
      await expectLater(f.repository.load(), throwsA(assignmentFailure(EnrollmentFailure.invalidResponse)));
      expect(f.posts, 0);
    });
  }
  for (final mode in ['revision', 'roster', 'goal', 'permission']) {
    test('preflight change prevents post $mode', () async {
      final f = ClassAssignmentFixture();
      final expected = f.options, draft = f.draft(expected);
      if (mode == 'revision') f.data['revision'] = 'r2';
      if (mode == 'roster') (f.data['students'] as List).removeLast();
      if (mode == 'goal') ((f.data['students'] as List).first['goals'] as List).clear();
      if (mode == 'permission') f.data['can_assign'] = false;
      await expectLater(f.repository.assign(expected, draft, assignmentKey), throwsA(assignmentFailure(EnrollmentFailure.conflict)));
      expect(f.posts, 0);
    });
  }
  test('subset and foreign student/goal never post', () async {
    final f = ClassAssignmentFixture(), o = ClassAssignmentFixture().options;
    for (final choices in [
      [const ClassAssignmentChoice(childId: 100)],
      [const ClassAssignmentChoice(childId: 100), const ClassAssignmentChoice(childId: 999)],
      [ClassAssignmentChoice(childId: 100, goal: o.students.last.goals.single), const ClassAssignmentChoice(childId: 200)],
    ]) {
      await expectLater(f.repository.assign(o, ClassAssignmentDraft(10, choices), assignmentKey), throwsA(assignmentFailure(EnrollmentFailure.validation)));
    }
    expect(f.posts, 0);
  });
  for (final mode in ['foreign', 'missing-student', 'goal', 'adaptation', 'request-key', 'follow-denied', 'follow-changed', 'lost', 'server']) {
    test('cannot confirm mismatched or uncertain mutation $mode', () async {
      final f = ClassAssignmentFixture();
      f.changeReceipt = (value) {
        if (mode == 'foreign') value['section_id'] = 2;
        if (mode == 'missing-student') (value['students'] as List).removeLast();
        if (mode == 'goal') (value['students'] as List).first['iep_goal'] = null;
        if (mode == 'adaptation') (value['students'] as List).last['adaptation'] = 'copied';
        if (mode == 'request-key') value['request_key'] = 'other';
      };
      if (mode == 'follow-denied') f.followStatus = 403;
      if (mode == 'follow-changed') f.changeFollow = (v) => v['lesson_id'] = 999;
      if (mode == 'lost') f.throwPost = true;
      if (mode == 'server') f.postStatus = 500;
      await expectLater(f.repository.assign(f.options, f.draft(), assignmentKey), throwsA(assignmentFailure(EnrollmentFailure.uncertain)));
      expect(f.posts, 1);
    });
  }
  test('unsupported service never posts', () async {
    final f = ClassAssignmentFixture()..status = 404;
    await expectLater(f.repository.load(), throwsA(assignmentFailure(EnrollmentFailure.unavailable)));
    expect(f.posts, 0);
  });
}
