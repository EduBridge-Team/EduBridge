import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:edubridge_app/features/students/data/student_profile_repository.dart';
import 'package:edubridge_app/features/students/domain/student_profile.dart';
import 'package:edubridge_app/features/students/presentation/student_profile_labels.dart';

void main() {
  test('profile preserves callback fields and display conventions', () {
    final input = <String, dynamic>{
      'id': 8, 'name': 'طالب', 'age': 9,
      'assigned_teacher_name': ' ', 'teacher_name': ' معلم ',
      'guardians': [{'name': ' ولي '}, '', 'آخر'],
      'strengths': [' قراءة ', '', '  '],
      'current_plan': {'educational_plan': ' خطة '},
      'current_plan_id': 12, 'custom_field': 'keep',
    };
    final profile = StudentProfile.fromJson(input);
    input['custom_field'] = 'changed';
    expect(profile.teacherName, 'معلم');
    expect(profile.guardianNames, 'ولي، آخر');
    expect(profile.age, 9);
    expect(profile.educationalPlan, 'خطة');
    expect(profile.currentPlanId, 12);
    expect(profile.strengths, [' قراءة ', '', '  ']);
    expect(StudentProfileLabels.teacherList(profile.strengths), ['قراءة']);
    expect(() => profile.strengths.add('x'), throwsUnsupportedError);
    final output = profile.toJson();
    expect(output['custom_field'], 'keep');
    output['custom_field'] = 'edited';
    expect(profile.toJson()['custom_field'], 'keep');
  });

  test('preview and plan IDs retain strict API types', () {
    final profile = StudentProfile.fromJson({
      'assignment_preview': 'true', 'current_plan_id': '12',
      'medical_report_url': ' report ',
    });
    expect(profile.isAssignmentPreview, isFalse);
    expect(profile.currentPlanId, isNull);
    expect(profile.hasDocuments, isTrue);
    expect(StudentProfile.fromJson({}).hasDocuments, isFalse);
    expect(StudentProfile.fromJson({}).guardianNames, isEmpty);
  });

  test('specialist and teacher status labels remain distinct', () {
    final assigned = StudentProfile.fromJson({'status': ' assigned '});
    expect(StudentProfileLabels.specialistStatus(assigned), 'assigned');
    expect(StudentProfileLabels.teacherStatus(assigned), 'قيد المتابعة');
    final preview = StudentProfile.fromJson({
      'assignment_preview': true, 'status': 'active',
    });
    expect(StudentProfileLabels.specialistStatus(preview), 'قبل التعيين');
    expect(StudentProfileLabels.teacherStatus(preview), 'قيد المتابعة');
    expect(StudentProfileLabels.specialistStatus(StudentProfile.fromJson({})),
        'قيد المتابعة');
  });

  test('successful profile fetch uses only the child endpoint', () async {
    final calls = <String>[];
    final repository = StudentProfileRepository(get: (path) async {
      calls.add(path);
      return http.Response(jsonEncode({'child': {'age': 10}}), 200);
    });
    final profile = await repository.load(8, allowAssignmentPreview: true);
    expect(profile.age, 10);
    expect(calls, ['/children/8']);
  });

  test('only opted-in specialists retry forbidden responses as preview', () async {
    final calls = <String>[];
    final repository = StudentProfileRepository(get: (path) async {
      calls.add(path);
      return path.endsWith('assignment-preview')
          ? http.Response(jsonEncode({'child': {'assignment_preview': true}}), 200)
          : http.Response('{}', 403);
    });
    await expectLater(repository.load(8), throwsA(isA<StudentProfileLoadException>()));
    expect(calls, ['/children/8']);
    calls.clear();
    final preview = await repository.load(8, allowAssignmentPreview: true);
    expect(preview.isAssignmentPreview, isTrue);
    expect(calls, ['/children/8', '/children/8/assignment-preview']);
  });

  for (final status in [401, 404, 500]) {
    test('status $status never falls back to assignment preview', () async {
      final calls = <String>[];
      final repository = StudentProfileRepository(get: (path) async {
        calls.add(path);
        return http.Response('{}', status);
      });
      await expectLater(repository.load(8, allowAssignmentPreview: true),
          throwsA(isA<StudentProfileLoadException>()));
      expect(calls, ['/children/8']);
    });
  }

  for (final body in ['{}', '{"child":[]}', 'invalid']) {
    test('invalid child response is rejected: $body', () async {
      final repository = StudentProfileRepository(
          get: (_) async => http.Response(body, 200));
      await expectLater(repository.load(8), throwsA(isA<StudentProfileLoadException>()));
    });
  }
}
