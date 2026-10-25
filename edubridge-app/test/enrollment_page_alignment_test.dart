import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/enrollment/enrollment_models.dart';
import 'package:edubridge_app/model/enrollment/school_history.dart';
import 'package:edubridge_app/screens/enrollment/enrollment_request_card.dart';
import 'package:edubridge_app/screens/enrollment/parent_enrollment_screen.dart';
import 'package:edubridge_app/screens/enrollment/school_history_screen.dart';
import 'package:edubridge_app/services/enrollment/enrollment_api_client.dart';
import 'package:edubridge_app/services/enrollment/school_history_repository.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'enrollment_fakes.dart';

class UnavailableHistory implements SchoolHistoryGateway {
  @override
  Future<SchoolHistory> load() async =>
      throw const EnrollmentApiException(EnrollmentFailure.unavailable);
}

Widget host(Widget screen, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: screen,
);
void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'centered descriptions with original headings and bottom action in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final strings = await AppLocalizations.delegate.load(
            Locale(language),
          );
          final gateway = FakeParentEnrollment()
            ..loadFailure = EnrollmentFailure.unavailable;
          await tester.pumpWidget(
            host(
              ParentEnrollmentScreen(
                childId: 6,
                childName: 'محمود',
                gateway: gateway,
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<BrandAppBar>(find.byType(BrandAppBar)).centerTitle,
            isNot(true),
          );
          expect(
            tester.renderObject<RenderParagraph>(find.text('محمود')).textAlign,
            TextAlign.start,
          );
          expect(
            tester
                .renderObject<RenderParagraph>(
                  find.text(strings.enrollmentUnavailable),
                )
                .textAlign,
            TextAlign.center,
          );
          final footer = find.byKey(const ValueKey('open-school-history'));
          expect(tester.getBottomRight(footer).dy, closeTo(984, 1));
          expect(
            tester.getTopLeft(footer).dy,
            greaterThan(
              tester
                  .getBottomRight(
                    find.byKey(const ValueKey('parent-enrollment-error')),
                  )
                  .dy,
            ),
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            host(
              SchoolHistoryScreen(
                childId: 6,
                childName: 'محمود',
                gateway: UnavailableHistory(),
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.widget<BrandAppBar>(find.byType(BrandAppBar)).centerTitle,
            isNot(true),
          );
          for (final label in [
            strings.schoolHistoryHint,
            strings.enrollmentUnavailable,
          ]) {
            expect(
              tester.renderObject<RenderParagraph>(find.text(label)).textAlign,
              TextAlign.center,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
      testWidgets(
        'history action stays after long enrollment content in $language at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final gateway = FakeParentEnrollment()
            ..requests = [
              for (var i = 0; i < 15; i++)
                EnrollmentRequest.fromJson({
                  ...enrollmentRequestJson(status: 'cancelled'),
                  'id': 50 + i,
                }),
            ];
          await tester.pumpWidget(
            host(
              ParentEnrollmentScreen(
                childId: 6,
                childName: 'محمود',
                gateway: gateway,
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          final footer = find.byKey(const ValueKey('open-school-history'));
          await tester.dragUntilVisible(
            footer,
            find.byType(CustomScrollView),
            const Offset(0, -500),
          );
          await tester.pumpAndSettle();
          final last = find.byWidgetPredicate(
            (widget) =>
                widget is EnrollmentRequestCard && widget.request.id == 64,
          );
          expect(last, findsOneWidget);
          expect(
            tester.getBottomRight(last).dy,
            lessThanOrEqualTo(tester.getTopLeft(footer).dy),
          );
          expect(footer.hitTestable(), findsOneWidget);
          expect(gateway.writes, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
