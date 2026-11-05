import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/model/statistics/ministry_statistics.dart';
import 'package:edubridge_app/screens/ministry_statistics_screen.dart';
import 'package:edubridge_app/services/ministry_statistics_repository.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'curriculum_ui_support.dart';

class StatisticsFake implements MinistryStatisticsGateway {
  bool fail = true;
  Completer<MinistryStatistics>? pending;
  @override
  Future<MinistryStatistics> load() async {
    if (pending != null) return pending!.future;
    if (fail) throw const EnrollmentApiException(EnrollmentFailure.server);
    return MinistryStatistics.fromJson({
      'total_children': 0,
      'by_age_group': {'6-9': 0},
      'by_disability_type': {}
    });
  }
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('ministry failure retry missing and zero $language $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final f = StatisticsFake();
        await tester.pumpWidget(
            curriculumHost(MinistryStatisticsScreen(gateway: f), language));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ministry-statistics-error')),
            findsOneWidget);
        expect(find.byKey(const ValueKey('ministry-value-total_children')),
            findsNothing);
        f.fail = false;
        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('ministry-statistics-error')),
            findsNothing);
        expect(
            tester
                .widget<Text>(
                    find.byKey(const ValueKey('ministry-value-total_children')))
                .data,
            '0');
        expect(
            tester
                .widget<Text>(find
                    .byKey(const ValueKey('ministry-value-active_children')))
                .data,
            language == 'en' ? 'Unavailable' : 'غير متاح');
        final group = find.byKey(const ValueKey('ministry-group-age'));
        await tester.scrollUntilVisible(group, 200,
            scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(group);
        await tester.pumpAndSettle();
        await tester.tap(group);
        await tester.pumpAndSettle();
        expect(find.text('6-9'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('old account statistics cannot overwrite replacement',
      (tester) async {
    final first = StatisticsFake()..pending = Completer<MinistryStatistics>();
    final second = StatisticsFake()..fail = false;
    await tester.pumpWidget(
        curriculumHost(MinistryStatisticsScreen(gateway: first), 'en'));
    await tester.pump();
    await tester.pumpWidget(
        curriculumHost(MinistryStatisticsScreen(gateway: second), 'en'));
    await tester.pumpAndSettle();
    first.pending!
        .complete(MinistryStatistics.fromJson({'total_children': 99}));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('ministry-value-total_children')))
            .data,
        '0');
  });
}
