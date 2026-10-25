import 'package:edubridge_app/features/case_discussions/domain/case_team_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final children = <Map<String, dynamic>>[
    {
      'id': 1,
      'assigned_teacher_id': '7',
      'specialist_ids': ['8'],
    },
    {'id': 2, 'assigned_teacher_id': 99, 'assigned_specialist_id': 8},
    {'id': 3},
  ];

  test('assignment filtering preserves each role boundary', () {
    List ids(String? role, int? userId) => CaseTeamPolicy.assignedChildren(
      children,
      role: role,
      userId: userId,
    ).map((child) => child['id']).toList();
    expect(ids('teacher', 7), [1]);
    expect(ids('specialist', 8), [1, 2]);
    expect(ids('teacher', 8), isEmpty);
    expect(ids('parent', 7), isEmpty);
    expect(ids(null, 7), isEmpty);
    expect(ids('admin', 7), [1, 2, 3]);
    expect(ids('teacher', null), isEmpty);
    expect(ids('specialist', null), isEmpty);
  });

  test('team IDs merge supported integer/string fields without duplicates', () {
    final child = {
      'assigned_teacher_id': '7',
      'specialist_id': 8,
      'assigned_specialist_id': '9',
      'teacher_ids': [7, '10', null, 'invalid'],
      'assigned_teacher_ids': ['11'],
      'specialist_ids': [8, '12'],
      'assigned_specialist_ids': ['9', 13],
    };
    expect(CaseTeamPolicy.specialistIds(child), {8, 9, 12, 13});
    expect(CaseTeamPolicy.teamIds(child), {7, 8, 9, 10, 11, 12, 13});
  });

  test('team selection excludes other roles and unrelated professionals', () {
    final users = <Map<String, dynamic>>[
      {'id': 7, 'role': 'teacher'},
      {'id': 8, 'role': 'specialist'},
      {'id': 9, 'role': 'parent'},
      {'id': 99, 'role': 'teacher'},
    ];
    expect(
      CaseTeamPolicy.teamFor({
        'assigned_teacher_id': 7,
        'specialist_ids': [8, 9],
      }, users).map((user) => user['id']),
      [7, 8],
    );
    expect(CaseTeamPolicy.teamFor({}, users), isEmpty);
    expect(CaseTeamPolicy.eligibleUsers(users).map((user) => user['id']), [
      7,
      8,
      99,
    ]);
  });
}
