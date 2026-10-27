import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/features/notifications/domain/notification_destination.dart';
import 'package:edubridge_app/features/notifications/presentation/notification_child_destination_screen.dart';
import 'curriculum_ui_support.dart';
import 'notification_destination_fixture.dart';

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('guardian selection and denied child $language $width', (tester) async {
        tester.view.physicalSize = Size(width, 1200); tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        final f = NotificationDestinationFixture()..detailStatus = 403;
        await tester.pumpWidget(curriculumHost(NotificationChildDestinationScreen(
          destination: NotificationChildDestination.enrollment, gateway: f.repository), language));
        await tester.pumpAndSettle();
        expect(find.text('نور'), findsOneWidget); expect(find.text('أحمد'), findsOneWidget);
        expect(f.paths.where((p) => p == '/children/9'), isEmpty);
        await tapCurriculum(tester, 'notification-child-9');
        expect(f.paths.where((p) => p == '/children/9'), hasLength(1));
        expect(find.byKey(const ValueKey('notification-child-9')), findsNothing);
        await resumeCurriculum(tester); expect(find.text('نور'), findsOneWidget);
        expect(f.paths.where((p) => p == '/children/9'), hasLength(1));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
