import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/features/notifications/domain/notification_destination.dart';
import 'package:edubridge_app/features/notifications/presentation/notification_child_destination_screen.dart';
import 'curriculum_ui_support.dart';
import 'notification_destination_fixture.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';

void main() {
  testWidgets('refresh hides old names until an authorized directory is confirmed', (tester) async {
    final f = NotificationDestinationFixture(), pending = Completer<void>();
    final gateway = f.repository;
    await tester.pumpWidget(curriculumHost(NotificationChildDestinationScreen(
      destination: NotificationChildDestination.enrollment, gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    expect(find.text('نور'), findsOneWidget);
    f.beforeList = () => pending.future;
    await tester.tap(find.byIcon(Icons.refresh)); await tester.pump();
    expect(find.text('نور'), findsNothing);
    expect(find.byKey(const ValueKey('notification-child-9')), findsNothing);
    f.listStatus = 403; pending.complete(); await tester.pumpAndSettle();
    expect(find.text('نور'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('background invalidates a pending successful open and refreshes on resume', (tester) async {
    final f = NotificationDestinationFixture(), pending = Completer<void>();
    final gateway = f.repository;
    await tester.pumpWidget(curriculumHost(NotificationChildDestinationScreen(
      destination: NotificationChildDestination.enrollment, gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    f.beforeDetail = () => pending.future;
    await tester.tap(find.byKey(const ValueKey('notification-child-9')));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(find.text('نور'), findsNothing);
    pending.complete(); await tester.pumpAndSettle();
    expect(find.byType(ParentEnrollmentScreen), findsNothing);
    await resumeCurriculum(tester);
    expect(find.text('نور'), findsOneWidget);
    expect(f.paths.where((p) => p == '/children/9'), hasLength(1));
    expect(f.paths.where((p) => p == '/children'), hasLength(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('background clears a pending directory and ignores its late completion', (tester) async {
    final f = NotificationDestinationFixture(), pending = Completer<void>();
    f.beforeList = () => pending.future;
    await tester.pumpWidget(curriculumHost(NotificationChildDestinationScreen(
      destination: NotificationChildDestination.enrollment, gateway: f.repository), 'en'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    pending.complete(); await tester.pumpAndSettle();
    expect(find.text('نور'), findsNothing);
    f.role = 'teacher'; await resumeCurriculum(tester);
    expect(find.text('نور'), findsNothing);
    expect(find.byType(ParentEnrollmentScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
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
