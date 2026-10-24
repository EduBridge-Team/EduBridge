import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/school_directors/school_directors_screen.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';

import 'school_directors_fakes.dart';

Widget host(Widget child, String language, {double scale = 1}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

Future<void> chooseSchool(WidgetTester tester) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('School A').last);
  await tester.pumpAndSettle();
}

Future<void> openEditor(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const ValueKey('director-add')));
  await tester.tap(find.byKey(const ValueKey('director-add')));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester) async {
  for (final entry in {
    'name': 'New Director',
    'email': 'new@example.org',
    'experience': '5',
  }.entries) {
    final field = find.byKey(ValueKey('director-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('director-save')));
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets(
      'school history renders at large text on small $language screen',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = FakeSchoolDirectors();
        await tester.pumpWidget(
          host(SchoolDirectorsScreen(gateway: gateway), language, scale: 2),
        );
        await tester.pumpAndSettle();
        await chooseSchool(tester);
        final history = find.text(
          language == 'ar' ? 'سجل التكليفات' : 'Assignment history',
        );
        await tester.scrollUntilVisible(
          history,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(history, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'unavailable endpoint has localized error without fabricated data in $language',
      (tester) async {
        final gateway = FakeSchoolDirectors()
          ..loadFailure = DirectorFailure.unavailable;
        await tester.pumpWidget(
          host(SchoolDirectorsScreen(gateway: gateway), language),
        );
        await tester.pumpAndSettle();
        await chooseSchool(tester);
        expect(find.byKey(const ValueKey('director-error')), findsOneWidget);
        expect(
          find.text(
            language == 'ar'
                ? 'خدمة ملفات المديرين غير متاحة على السيرفر حاليًا.'
                : 'Director management is not available on the server yet.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('director-add')), findsNothing);
      },
    );
  }

  testWidgets('empty schools show truthful state', (tester) async {
    final gateway = FakeSchoolDirectors()..schoolResults = [];
    await tester.pumpWidget(
      host(SchoolDirectorsScreen(gateway: gateway), 'en'),
    );
    await tester.pumpAndSettle();
    expect(find.text('No schools belong to this institution.'), findsOneWidget);
    expect(find.byKey(const ValueKey('director-add')), findsNothing);
  });

  testWidgets(
    'editor validates required fields and retains draft after rejected save',
    (tester) async {
      final gateway = FakeSchoolDirectors()
        ..writeFailure = DirectorFailure.validation;
      await tester.pumpWidget(
        host(SchoolDirectorsScreen(gateway: gateway), 'en'),
      );
      await tester.pumpAndSettle();
      await chooseSchool(tester);
      await openEditor(tester);
      final save = find.byKey(const ValueKey('director-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(gateway.writes, 0);
      await fill(tester);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(gateway.writes, 1);
      expect(find.text('New Director'), findsOneWidget);
      expect(
        find.text('Review the details and dates before trying again.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pending save disables duplicate taps and successful save returns to directory',
    (tester) async {
      final gateway = FakeSchoolDirectors()..pendingWrite = Completer<void>();
      await tester.pumpWidget(
        host(SchoolDirectorsScreen(gateway: gateway), 'en'),
      );
      await tester.pumpAndSettle();
      await chooseSchool(tester);
      await openEditor(tester);
      await fill(tester);
      final save = find.byKey(const ValueKey('director-save'));
      await tester.tap(save);
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      await tester.tap(save);
      expect(gateway.writes, 1);
      gateway.pendingWrite!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('director-saved')), findsOneWidget);
    },
  );

  testWidgets('cancel ending an assignment never sends a write', (
    tester,
  ) async {
    final gateway = FakeSchoolDirectors();
    await tester.pumpWidget(
      host(SchoolDirectorsScreen(gateway: gateway), 'en'),
    );
    await tester.pumpAndSettle();
    await chooseSchool(tester);
    final end = find.text('End assignment');
    await tester.ensureVisible(end);
    await tester.tap(end);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Submit a request to end this assignment and revoke its access. Continue?',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
  });
}
