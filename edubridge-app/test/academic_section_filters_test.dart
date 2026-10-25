import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/academics/academic_screen.dart';
import 'package:edubridge_app/screens/academics/academic_sections_panel.dart';
import 'package:edubridge_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'academic_filter_fixtures.dart';

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

Finder get catalogScroll => find
    .descendant(
      of: find.byType(ListView).first,
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> reveal(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    tester.state<ScrollableState>(catalogScroll).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(target, 250, scrollable: catalogScroll);
  }
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String filter, String label) async {
  final button = find.byKey(ValueKey('academic-filter-$filter'));
  await reveal(tester, button);
  await tester.tap(button);
  await tester.pumpAndSettle();
  final choice = find.descendant(
    of: find.byType(SimpleDialog),
    matching: find.text(label),
  );
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

Future<void> resume(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
  await tester.pumpAndSettle();
}

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets('school section filters and refresh in $language at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final gateway = FilterAcademicGateway();
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await tester.pumpWidget(
          host(AcademicScreen(gateway: gateway), language),
        );
        await tester.pumpAndSettle();
        expect(find.byType(BrandAppBar), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);
        await choose(tester, 'year', currentYearName);
        expect(
          find.byKey(const ValueKey('academic-section-3')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('academic-section-6')), findsNothing);
        await choose(tester, 'grade', secondGradeName);
        expect(
          find.byKey(const ValueKey('academic-sections-empty')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('academic-section-3')), findsNothing);
        await choose(tester, 'year', previousYearName);
        expect(
          find.byKey(const ValueKey('academic-section-7')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('academic-section-6')), findsNothing);
        expect(gateway.reads, 1);
        expect(gateway.writes, 0);
        await resume(tester);
        expect(gateway.reads, 2);
        await reveal(
          tester,
          find.byKey(const ValueKey('academic-filter-grade')),
        );
        expect(
          find.byKey(const ValueKey('academic-section-7')),
          findsOneWidget,
        );
        await choose(tester, 'grade', strings.all);
        expect(
          find.byKey(const ValueKey('academic-section-6')),
          findsOneWidget,
        );
        // The selected year disappears from a later canonical snapshot.
        gateway.data = filterCatalog(removeYear: true);
        tester.state<ScrollableState>(catalogScroll).position.jumpTo(0);
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, 350));
        await tester.pumpAndSettle();
        expect(gateway.reads, 3);
        await reveal(
          tester,
          find.byKey(const ValueKey('academic-filter-year')),
        );
        expect(
          find.byKey(const ValueKey('academic-section-3')),
          findsOneWidget,
        );
        expect(
          find.text('${strings.academicYears}: ${strings.all}'),
          findsOneWidget,
        );
        expect(gateway.writes, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('changing school resets filters even when IDs are reused', (
    tester,
  ) async {
    Widget panel(int school) => host(
      Scaffold(
        body: ListView(
          children: [
            AcademicSectionsPanel(catalog: filterCatalog(school: school)),
          ],
        ),
      ),
      'en',
    );
    await tester.pumpWidget(panel(10));
    await tester.pumpAndSettle();
    await choose(tester, 'year', previousYearName);
    await tester.pumpWidget(panel(11));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('academic-section-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('academic-section-6')), findsOneWidget);
  });

  testWidgets('unavailable catalog removes stale actions and filters', (
    tester,
  ) async {
    final gateway = FilterAcademicGateway();
    await tester.pumpWidget(host(AcademicScreen(gateway: gateway), 'en'));
    await tester.pumpAndSettle();
    gateway.failRead = true;
    await resume(tester);
    expect(find.byType(AcademicSectionsPanel), findsNothing);
    expect(find.byKey(const ValueKey('academic-add-section')), findsNothing);
    gateway.failRead = false;
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const ValueKey('academic-filter-year')));
    expect(find.byType(AcademicSectionsPanel), findsOneWidget);
    expect(gateway.writes, 0);
  });
}
