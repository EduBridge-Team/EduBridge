import 'dart:convert';
import 'package:edubridge_app/screens/school_management/school_management_screen.dart';
import 'package:edubridge_app/services/schools/school_management_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'school_account_form_test.dart' show host;

void main() {
  test('scope is enforced on reads and injected into mutations', () async {
    Map<String,dynamic>? written;
    final repository = SchoolManagementRepository(client: EnrollmentApiClient(
      get: (_) async => http.Response(jsonEncode({'school_id': 9}), 200),
      post: (_, body) async { written = body; return http.Response('{}', 201); },
    )).scoped(5);
    await expectLater(repository.operation('academic'), throwsA(isA<EnrollmentApiException>()));
    await repository.mutate('/school/operations/years', 'POST', {'name':'Year', 'expected_school_id':9});
    expect(written!['expected_school_id'], 5);
  });
  for (final language in ['ar','en']) {
    for (final width in [320.0,720.0,1280.0]) {
      testWidgets('deputy sees only delegated operations at $width in $language with large text', (tester) async {
        tester.view.physicalSize=Size(width,900);
        tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository=SchoolManagementRepository(client:EnrollmentApiClient(get:(_) async=>http.Response(jsonEncode({
          'school':{'id':5,'name':'School'},'role':'deputy_director','permissions':['attendance'],
        }),200)));
        await tester.pumpWidget(host(SchoolManagementScreen(repository:repository),language,scale:2));
        await tester.pumpAndSettle();
        expect(find.text(language=='en'?'Attendance':'الحضور'),findsOneWidget);
        expect(find.text(language=='en'?'Namespace and deputies':'النطاق والنواب'),findsNothing);
        expect(find.text(language=='en'?'Annual progression':'الترفيع السنوي'),findsNothing);
        expect(tester.takeException(),isNull);
      });
    }
  }
}
