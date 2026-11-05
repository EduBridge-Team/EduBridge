import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/schools/school_director.dart';
import 'package:edubridge_app/screens/school_directors/school_director_appointment_screen.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';
import 'package:edubridge_app/services/schools/school_director_appointment_repository.dart';
import 'package:edubridge_app/theme.dart';

import 'curriculum_ui_support.dart';

class _Gateway implements SchoolDirectorAppointmentGateway {
  int writes = 0;

  @override
  Future<List<DirectorSchool>> schools() async => const [
        DirectorSchool(
          id: 5,
          name: 'School A',
          organizationId: 2,
          organizationSlug: 'org',
        ),
      ];

  @override
  Future<PersonalSchoolDirector?> current(DirectorSchool school) async => null;

  @override
  Future<int> appoint(DirectorSchool school, String email) async {
    writes++;
    throw const DirectorApiException(DirectorFailure.forbidden);
  }
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('director identity requires invitation $language width $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = _Gateway();
        await tester.pumpWidget(curriculumHost(SchoolDirectorAppointmentScreen(gateway: gateway), language));
        await tester.pumpAndSettle();
        expect(find.byType(BrandAppBar), findsOneWidget);
        expect(find.byKey(const ValueKey('director-profile-documents')), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(
          find.text(language == 'ar' ? 'إدارة دعوات المدير' : 'Manage director invitations'),
          findsOneWidget,
        );
        expect(gateway.writes, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
