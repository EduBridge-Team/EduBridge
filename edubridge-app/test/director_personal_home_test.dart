import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/home_screen.dart';
import 'package:edubridge_app/screens/school_management/school_management_screen.dart';
import 'package:edubridge_app/utils/home_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget host(Widget home) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: home,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'role': 'parent',
      'name': 'Ahmed',
    });
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('verified director opens personal home, not school management', () {
    final home = homeForSchoolContext('parent', {'role': 'director'});
    expect(home, isA<HomeScreen>());
    expect((home as HomeScreen).schoolManagementPage, isNotNull);
    expect(homeForSchoolContext('teacher', {'role': 'staff'}),
        isA<SchoolManagementScreen>());
  });

  testWidgets('director school card precedes children and opens administration',
      (tester) async {
    await tester.pumpWidget(host(HomeScreen(
      schoolManagementPage: () =>
          const Scaffold(body: Text('School administration opened')),
    )));
    await tester.pumpAndSettle();

    final schoolCard = find.byKey(
      const ValueKey('director-school-management'),
    );
    expect(schoolCard, findsOneWidget);
    expect(
      tester.getTopLeft(schoolCard).dy,
      lessThan(tester.getTopLeft(find.text('الأطفال')).dy),
    );
    await tester.tap(schoolCard);
    await tester.pumpAndSettle();
    expect(find.text('School administration opened'), findsOneWidget);
    Navigator.of(tester.element(find.text('School administration opened'))).pop();
    await tester.pumpAndSettle();
    expect(schoolCard, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal personal home does not expose school administration',
      (tester) async {
    await tester.pumpWidget(host(const HomeScreen()));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('director-school-management')),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}
