import 'package:edubridge_app/screens/specialist_schools/independent_specialist_employment_screen.dart';
import 'package:edubridge_app/services/schools/independent_specialist_employment_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'curriculum_ui_support.dart';

class _FakeEmploymentGateway implements IndependentSpecialistEmploymentGateway {
  _FakeEmploymentGateway({this.accepted = false});

  bool accepted;
  bool ended = false;
  final invitedEmails = <String>[];
  final acceptedEmploymentIds = <int>[];
  final endedEmployments = <int>[];
  final openedSchoolIds = <int>[];

  IndependentSpecialistEmployment get record => IndependentSpecialistEmployment(
        id: 91,
        schoolId: 17,
        schoolName: 'مدرسة أ',
        specialistId: 42,
        specialistName: 'الأخصائي أحمد',
        email: 'specialist@example.test',
        accepted: accepted,
        ended: ended,
      );

  @override
  Future<List<IndependentSpecialistEmployment>> directorRoster(int schoolId) async {
    openedSchoolIds.add(schoolId);
    if (schoolId != 17) throw StateError('Unexpected school');
    return [record];
  }

  @override
  Future<List<IndependentSpecialistEmployment>> myOffers() async => [record];

  @override
  Future<void> invite(int schoolId, String email) async {
    if (schoolId != 17) throw StateError('Unexpected school');
    invitedEmails.add(email);
  }

  @override
  Future<void> accept(int employmentId) async {
    acceptedEmploymentIds.add(employmentId);
    accepted = true;
  }

  @override
  Future<void> end(int schoolId, int employmentId) async {
    if (schoolId != 17) throw StateError('Unexpected school');
    endedEmployments.add(employmentId);
    ended = true;
  }
}

void main() {
  testWidgets('director can invite by email from the employment screen', (tester) async {
    final gateway = _FakeEmploymentGateway();
    await tester.pumpWidget(curriculumHost(
      SchoolSpecialistEmploymentScreen(schoolId: 17, gateway: gateway), 'ar'));
    await tester.pumpAndSettle();
    expect(find.text('الأخصائي أحمد'), findsOneWidget);
    expect(gateway.openedSchoolIds, [17]);
    await tester.tap(find.byKey(const ValueKey('specialist-employment-invite')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('specialist-employment-email')),
        'specialist@example.test');
    await tester.tap(find.text('إرسال العرض'));
    await tester.pumpAndSettle();
    expect(gateway.invitedEmails, ['specialist@example.test']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('specialist explicitly accepts the school offer', (tester) async {
    final gateway = _FakeEmploymentGateway();
    await tester.pumpWidget(curriculumHost(
      SpecialistEmploymentOffersScreen(gateway: gateway), 'ar'));
    await tester.pumpAndSettle();
    expect(find.text('مدرسة أ'), findsOneWidget);
    expect(gateway.acceptedEmploymentIds, isEmpty);
    await tester.tap(
        find.byKey(const ValueKey('specialist-employment-accept-91')));
    await tester.pumpAndSettle();
    expect(gateway.acceptedEmploymentIds, isEmpty);
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(gateway.acceptedEmploymentIds, [91]);
    expect(find.text('تم القبول'), findsOneWidget);
    expect(find.byKey(const ValueKey('specialist-employment-accept-91')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('director ends school employment only after confirmation', (tester) async {
    final gateway = _FakeEmploymentGateway(accepted: true);
    await tester.pumpWidget(curriculumHost(
      SchoolSpecialistEmploymentScreen(schoolId: 17, gateway: gateway), 'ar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(
        const ValueKey('specialist-employment-end-91')));
    await tester.pumpAndSettle();
    expect(gateway.endedEmployments, isEmpty);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(gateway.endedEmployments, isEmpty);
    await tester.tap(find.byKey(
        const ValueKey('specialist-employment-end-91')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد'));
    await tester.pumpAndSettle();
    expect(gateway.endedEmployments, [91]);
    expect(find.byKey(const ValueKey('specialist-employment-end-91')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable roster shows an error without inventing employees', (tester) async {
    final gateway = _UnavailableEmploymentGateway();
    await tester.pumpWidget(curriculumHost(
      SchoolSpecialistEmploymentScreen(schoolId: 17, gateway: gateway), 'ar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('specialist-employment-91')), findsNothing);
    expect(find.byKey(const ValueKey('specialist-employment-invite')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _UnavailableEmploymentGateway extends _FakeEmploymentGateway {
  @override
  Future<List<IndependentSpecialistEmployment>> directorRoster(int schoolId) async {
    throw const FormatException('Backend contract not available');
  }
}
