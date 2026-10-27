import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/features/notifications/domain/notification_destination.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'notification_destination_fixture.dart';

void main() {
  test('allowlist uses notification type only', () {
    expect(notificationChildDestination('school_enrollment'), NotificationChildDestination.enrollment);
    expect(notificationChildDestination('child_evaluated'), NotificationChildDestination.evaluations);
    expect(notificationChildDestination('weekly_report_created'), NotificationChildDestination.weeklyReports);
    for (final type in ['lesson_added', 'unknown', '/children/9', 'school_enrollment 9']) {
      expect(notificationChildDestination(type), isNull);
    }
  });
  test('guardian list and exact child are freshly authorized', () async {
    final f = NotificationDestinationFixture(), repo = NotificationDestinationFixture().repository;
    final expected = await repo.load();
    final child = await f.repository.authorize(expected, 9);
    expect(child.id, 9); expect(child.name, 'نور — سجل محدث');
    expect(f.paths, ['/me', '/children/9', '/me']);
    expect(() => expected.children.clear(), throwsUnsupportedError);
  });
  test('unknown child, nonparent, denied and foreign child cannot open', () async {
    for (final mode in ['unknown', 'role', 'denied', 'foreign', 'account']) {
      final f = NotificationDestinationFixture(); final expected = await f.repository.load();
      if (mode == 'role') f.role = 'teacher';
      if (mode == 'denied') f.detailStatus = 403;
      if (mode == 'foreign') f.childId = 88;
      if (mode == 'account') f.afterDetail = () => f.userId = 55;
      await expectLater(f.repository.authorize(expected, mode == 'unknown' ? 888 : 9), throwsA(isA<EnrollmentApiException>()));
      if (mode == 'unknown' || mode == 'role') expect(f.paths.where((p) => p == '/children/9'), isEmpty);
    }
  });
  test('account change and duplicates invalidate directory; empty is valid', () async {
    final changed = NotificationDestinationFixture()..afterList = () {};
    changed.afterList = () => changed.userId = 8;
    await expectLater(changed.repository.load(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.session)));
    final duplicate = NotificationDestinationFixture(); duplicate.children.add(Map<String, dynamic>.from(duplicate.children.first));
    await expectLater(duplicate.repository.load(), throwsA(isA<EnrollmentApiException>().having((e) => e.failure, 'failure', EnrollmentFailure.invalidResponse)));
    final empty = NotificationDestinationFixture()..children.clear();
    expect((await empty.repository.load()).children, isEmpty);
  });
}
