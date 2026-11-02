import 'dart:convert';

import 'package:edubridge_app/screens/school_management/school_identity_settings_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/schools/school_management_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'school_account_form_test.dart' show host;

void main() {
  testWidgets('director enters only a prefix and API receives the prefix with school scope', (tester) async {
    var confirmed = false;
    Map<String, dynamic>? submitted;
    final client = EnrollmentApiClient(
      get: (path) async {
        if (path == '/school/internal-domain') {
          return http.Response(jsonEncode({
            'internal_domain': confirmed ? 'alreyada.edubridge' : null,
            'confirmed_at': confirmed ? '2026-11-03T00:00:00Z' : null,
          }), 200);
        }
        if (path == '/school/deputies') {
          return http.Response(jsonEncode({'deputies': []}), 200);
        }
        return http.Response('{}', 404);
      },
      post: (path, body) async {
        expect(path, '/school/internal-domain/confirm');
        submitted = body;
        confirmed = true;
        return http.Response(jsonEncode({'confirmed': true, 'internal_domain': 'alreyada.edubridge'}), 200);
      },
    );

    await tester.pumpWidget(host(SchoolIdentitySettingsScreen(
      repository: SchoolManagementRepository(client: client).scoped(10),
    ), 'en'));
    await tester.pumpAndSettle();

    final prefixField = find.byType(TextField).first;
    await tester.enterText(prefixField, 'ab');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirm namespace')).onPressed, isNull);

    await tester.enterText(prefixField, 'alreyada');
    await tester.pump();
    expect(find.text('Resulting namespace: alreyada.edubridge'), findsOneWidget);
    await tester.tap(find.text('I understand that the namespace is permanent.'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm namespace'));
    await tester.pumpAndSettle();

    expect(submitted, {'internal_domain': 'alreyada', 'expected_school_id': 10});
    expect(find.text('alreyada.edubridge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
