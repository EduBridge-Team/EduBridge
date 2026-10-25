import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/specialist/specialist_bottom_navigation.dart';
import 'package:edubridge_app/screens/specialist/specialist_child_search_dialog.dart';
import 'package:edubridge_app/screens/specialist/specialist_dashboard_body.dart';
import 'package:edubridge_app/screens/specialist/specialist_verification_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {String language = 'en', double scale = 1}) =>
    MaterialApp(
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets(
    'body builds only the selected content and forwards trimmed search',
    (tester) async {
      var tab = 0;
      var loading = false;
      var failed = false;
      var query = '';
      var progressBuilds = 0;
      var lessonsBuilds = 0;
      late StateSetter update;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SpecialistDashboardBody(
                tabIndex: tab,
                loading: loading,
                hasError: failed,
                searchQuery: query,
                onSearchChanged: (value) => query = value,
                onRefresh: () async {},
                filter: const Text('filter'),
                pendingCount: 1,
                doneToday: 2,
                pendingProgress: 3,
                errorBuilder: (_) => const Text('failure'),
                progressBuilder: (_) {
                  progressBuilds++;
                  return const SliverToBoxAdapter(
                    child: Text('children content'),
                  );
                },
                lessonsBuilder: (_) {
                  lessonsBuilds++;
                  return const SliverToBoxAdapter(
                    child: Text('lessons content'),
                  );
                },
              );
            },
          ),
        ),
      );
      expect(find.text('children content'), findsOneWidget);
      expect(lessonsBuilds, 0);
      await tester.enterText(find.byType(TextFormField), '  Ali  ');
      expect(query, 'Ali');
      final previousProgressBuilds = progressBuilds;
      update(() => tab = 1);
      await tester.pump();
      expect(find.text('filter'), findsNothing);
      expect(find.text('lessons content'), findsOneWidget);
      expect(progressBuilds, previousProgressBuilds);
      update(() => loading = true);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('lessons content'), findsNothing);
      update(() {
        loading = false;
        failed = true;
      });
      await tester.pump();
      expect(find.text('failure'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bottom navigation delegates each destination', (tester) async {
    final selections = <int>[];
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.bottomCenter,
          child: SpecialistBottomNavigation(
            tabIndex: 0,
            onSelected: selections.add,
          ),
        ),
      ),
    );
    for (final destination
        in find
            .byType(NavigationDestination)
            .evaluate()
            .map((e) => e.widget)
            .toList()) {
      await tester.tap(find.byWidget(destination));
      await tester.pumpAndSettle();
    }
    expect(selections, [0, 1, 2, 3]);
  });

  testWidgets(
    'search dialog submits, clears and cancels without retaining input',
    (tester) async {
      String? result;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => result =
                  await SpecialistChildSearchDialog.show(context, 'Ali'),
              child: const Text('open'),
            ),
          ),
        ),
      );
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Noor');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(result, 'Noor');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Ali'), findsOneWidget);
      await tester.tap(find.text(strings.clearSearch));
      await tester.pumpAndSettle();
      expect(result, '');
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(strings.cancel));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'verification stays usable in $language at $width and large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var verified = false;
          await tester.pumpWidget(
            host(
              SpecialistVerificationDialog(onVerify: () => verified = true),
              language: language,
              scale: 2,
            ),
          );
          await tester.pumpAndSettle();
          final button = find.byType(ElevatedButton);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          expect(verified, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
