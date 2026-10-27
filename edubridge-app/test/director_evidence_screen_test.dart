import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/model/schools/director_evidence.dart';
import 'package:edubridge_app/screens/school_directors/evidence/director_evidence_screen.dart';
import 'package:edubridge_app/services/schools/director_api_client.dart';

import 'director_evidence_fakes.dart';
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
Widget screen(
  FakeDirectorEvidence gateway, {
  Future<DirectorDocumentDraft?> Function(DirectorDocumentKind)? picker,
}) => DirectorEvidenceScreen(
  school: directorSchoolA,
  director: directorProfile,
  gateway: gateway,
  picker: picker,
);

Future<void> selectIdentity(WidgetTester tester) async {
  final select = find.byType(DropdownButtonFormField<int>);
  await tester.ensureVisible(select);
  await tester.pumpAndSettle();
  await tester.tap(select);
  await tester.pumpAndSettle();
  await tester.tap(find.text('identity.pdf').last);
  await tester.pumpAndSettle();
  await tester.ensureVisible(
    find.byKey(const ValueKey('director-verification-submit')),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets(
      'evidence and review fit a small screen with large $language text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = FakeDirectorEvidence();
        await tester.pumpWidget(host(screen(gateway), language, scale: 2));
        await tester.pumpAndSettle();
        final status = find.byKey(
          const ValueKey('director-verification-status'),
        );
        await tester.scrollUntilVisible(
          status,
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          find.text(
            language == 'ar' ? 'لم يُرسل طلب تحقق' : 'No review submitted',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'unavailable evidence does not fabricate approval in $language',
      (tester) async {
        final gateway = FakeDirectorEvidence()
          ..loadFailure = DirectorFailure.unavailable;
        await tester.pumpWidget(host(screen(gateway), language));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('director-evidence-error')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('director-verification-status')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('director-document-upload')),
          findsNothing,
        );
      },
    );
  }
  testWidgets('cancelling file picker never sends upload', (tester) async {
    final gateway = FakeDirectorEvidence();
    await tester.pumpWidget(
      host(screen(gateway, picker: (_) async => null), 'en'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('director-document-upload')));
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
    expect(find.byKey(const ValueKey('director-evidence-saved')), findsNothing);
  });
  testWidgets('invalid file shows localized error and sends nothing', (
    tester,
  ) async {
    final gateway = FakeDirectorEvidence();
    await tester.pumpWidget(
      host(
        screen(
          gateway,
          picker: (_) async =>
              throw const DirectorApiException(DirectorFailure.invalidFile),
        ),
        'en',
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('director-document-upload')));
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
    expect(
      find.byKey(const ValueKey('director-evidence-error')),
      findsOneWidget,
    );
  });
  testWidgets('cancelling verification confirmation sends nothing', (
    tester,
  ) async {
    final gateway = FakeDirectorEvidence();
    await tester.pumpWidget(host(screen(gateway), 'en'));
    await tester.pumpAndSettle();
    await selectIdentity(tester);
    await tester.tap(
      find.byKey(const ValueKey('director-verification-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(gateway.writes, 0);
  });
  testWidgets('verification submission shows pending and protects evidence', (
    tester,
  ) async {
    final gateway = FakeDirectorEvidence();
    await tester.pumpWidget(host(screen(gateway), 'en'));
    await tester.pumpAndSettle();
    await selectIdentity(tester);
    await tester.tap(
      find.byKey(const ValueKey('director-verification-submit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(gateway.writes, 1);
    expect(find.text('Pending review'), findsOneWidget);
    final remove = find.byKey(const ValueKey('director-document-remove-70'));
    expect(tester.widget<TextButton>(remove).onPressed, isNull);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('director-verification-submit')),
          )
          .onPressed,
      isNull,
    );
  });
}
