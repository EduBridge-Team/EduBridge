import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/specialist/specialist_school_grouped_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> childRow(int id, String name, {int? schoolId,
    String? schoolName, bool includeScope = true,
    String? schoolMembershipStatus}) => {
  'child': {
    'id': id,
    'name': name,
    if (includeScope) 'school_id': schoolId,
    if (includeScope) 'school_name': schoolName,
    if (schoolMembershipStatus != null)
      'school_membership_status': schoolMembershipStatus,
  },
};

Widget host(List<Map<String, dynamic>> rows, String language,
    {bool isMyChildren = false}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(
    body: CustomScrollView(slivers: [
      SpecialistSchoolGroupedSliver(
        rows: rows,
        isMyChildren: isMyChildren,
        childBuilder: (_, row) => Card(child: ListTile(
          title: Text((row['child'] as Map)['name'] as String))),
      ),
    ]),
  ),
);

void main() {
  test('my children are grouped by stable school identity, not by child order', () {
    final rows = [
      childRow(1, 'أحمد', schoolId: 2, schoolName: 'مدرسة ب'),
      childRow(2, 'علي', schoolId: 1, schoolName: 'مدرسة أ'),
      childRow(3, 'ليلى', schoolId: 2, schoolName: 'مدرسة ب'),
      childRow(4, 'رنا', schoolId: 1, schoolName: 'مدرسة أ'),
      childRow(5, 'سارة', schoolId: 2, schoolName: 'مدرسة ب'),
    ];
    final groups = groupSpecialistChildrenBySchool(rows);
    expect(groups.map((g) => g.schoolId), [1, 2]);
    expect(groups.map((g) => g.rows.length), [2, 3]);
    expect(groups[0].rows.map((row) => (row['child'] as Map)['id']), [2, 4]);
    expect(groups[1].rows.map((row) => (row['child'] as Map)['id']), [1, 3, 5]);
    expect(() => groups.first.rows.clear(), throwsUnsupportedError);
  });

  test('waiting list groups identically and counts only its own filtered rows', () {
    final waiting = [
      childRow(8, 'سعيد', schoolId: 2, schoolName: 'مدرسة ب'),
      childRow(9, 'جود', schoolId: 2, schoolName: 'مدرسة ب'),
      childRow(10, 'ندى', schoolId: 1, schoolName: 'مدرسة أ'),
    ];
    final groups = groupSpecialistChildrenBySchool(waiting);
    expect(groups.map((g) => g.rows.length), [1, 2]);
    expect(groups.fold<int>(0, (total, g) => total + g.rows.length), waiting.length);
  });

  test('same names with different IDs are never conflated', () {
    final groups = groupSpecialistChildrenBySchool([
      childRow(1, 'أ', schoolId: 5, schoolName: 'مدرسة الأمل'),
      childRow(2, 'ب', schoolId: 6, schoolName: 'مدرسة الأمل'),
    ]);
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.schoolId), containsAll([5, 6]));
  });

  test('missing, incomplete and conflicting school identities never invent membership', () {
    final groups = groupSpecialistChildrenBySchool([
      childRow(1, 'أ', schoolId: 4, schoolName: 'مدرسة النور'),
      childRow(2, 'ب', schoolId: 4, schoolName: 'مدرسة مختلفة'),
      childRow(3, 'ج', schoolId: 7),
      childRow(4, 'د', includeScope: false),
    ]);
    expect(groups, hasLength(1));
    expect(groups.single.schoolId, isNull);
    expect(groups.single.rows.map((row) => (row['child'] as Map)['id']),
      containsAll([1, 2, 3, 4]));
  });

  test('confirmed outside-school follow-up is separate from unknown metadata', () {
    final groups = groupSpecialistChildrenBySchool([
      childRow(1, 'مدرسة أ', schoolId: 2, schoolName: 'مدرسة الأمل'),
      childRow(2, 'متابعة فردية', schoolMembershipStatus: 'not_enrolled'),
      childRow(3, 'بيانات ناقصة', includeScope: false),
      childRow(4, 'بيانات ملتبسة', schoolId: 7),
      childRow(5, 'خارج مدرسة آخر', schoolMembershipStatus: 'none'),
    ]);
    expect(groups.map((group) => group.kind), [
      SpecialistSchoolGroupKind.school,
      SpecialistSchoolGroupKind.outsideSchools,
      SpecialistSchoolGroupKind.unspecified,
    ]);
    expect(groups[1].rows.map((row) => (row['child'] as Map)['id']), [2, 5]);
    expect(groups[2].rows.map((row) => (row['child'] as Map)['id']), [3, 4]);
    expect(groups[1].schoolId, isNull);
    expect(() => groups[1].rows.clear(), throwsUnsupportedError);
  });

  test('server contradiction cannot misclassify enrolled child as outside', () {
    final groups = groupSpecialistChildrenBySchool([
      childRow(1, 'تعارض', schoolId: 3, schoolName: 'مدرسة',
          schoolMembershipStatus: 'not_enrolled'),
      childRow(2, 'حالة فقط', includeScope: false,
          schoolMembershipStatus: 'not_enrolled'),
      childRow(3, 'مدرسة غير معروفة'),
    ]);
    expect(groups, hasLength(1));
    expect(groups.single.kind, SpecialistSchoolGroupKind.unspecified);
    expect(groups.single.rows, hasLength(3));
  });

  for (final language in ['ar', 'en']) {
    testWidgets('followed non-enrolled child is named correctly in $language',
        (tester) async {
      final rows = [
        childRow(1, 'طفل مدرسة', schoolId: 2, schoolName: 'مدرسة الأمل'),
        childRow(2, 'طفل بلا مدرسة', schoolMembershipStatus: 'not_enrolled'),
        childRow(3, 'طفل بلا بيانات', includeScope: false),
      ];
      await tester.pumpWidget(host(rows, language, isMyChildren: true));
      await tester.pump();
      expect(find.text(language == 'ar'
          ? 'أطفال تحت المتابعة خارج المدارس'
          : 'Children followed outside schools'), findsOneWidget);
      expect(find.text(language == 'ar'
          ? 'المدرسة غير محددة' : 'School not specified'), findsOneWidget);
      expect(find.byKey(const ValueKey('specialist-school-count-outside')),
          findsOneWidget);
      expect(find.text('طفل بلا مدرسة'), findsOneWidget);
      expect(find.text('طفل بلا بيانات'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('waiting child has neutral non-follow-up wording in $language',
        (tester) async {
      await tester.pumpWidget(host([
        childRow(5, 'انتظار', schoolMembershipStatus: 'not_enrolled'),
      ], language));
      await tester.pump();
      expect(find.text(language == 'ar'
          ? 'أطفال خارج المدارس' : 'Children outside schools'), findsOneWidget);
      expect(find.byKey(const ValueKey('specialist-school-group-outside')),
          findsOneWidget);
    });
  }

  for (final language in ['ar', 'en']) {
    for (final width in [360.0, 720.0]) {
      testWidgets('existing child cards remain under the right school heading $language $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final rows = [
          childRow(1, 'آدم', schoolId: 2, schoolName: 'مدرسة ب'),
          childRow(2, 'سارة', schoolId: 2, schoolName: 'مدرسة ب'),
          childRow(3, 'محمود', schoolId: 1, schoolName: 'مدرسة أ'),
        ];
        await tester.pumpWidget(host(rows, language));
        await tester.pumpAndSettle();
        expect(find.text('مدرسة أ'), findsOneWidget);
        expect(find.text('مدرسة ب'), findsOneWidget);
        expect(find.byKey(const ValueKey('specialist-school-count-1')), findsOneWidget);
        expect(find.byKey(const ValueKey('specialist-school-count-2')), findsOneWidget);
        expect(find.text('آدم'), findsOneWidget);
        expect(find.text('محمود'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
