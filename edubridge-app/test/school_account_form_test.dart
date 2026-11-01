import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/admin/admin_school_create_page.dart';
import 'package:edubridge_app/screens/institution_school_account_screen.dart';
import 'package:edubridge_app/services/schools/school_account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

Finder field(String name) => find.byKey(ValueKey('school-account-$name'));
final submit = find.byKey(const ValueKey('school-account-submit'));

Future<void> fill(WidgetTester tester) async {
  for (final entry in {
    'name': 'School',
    'email': 'school@example.org',
    'password': 'school-password-12345',
    'password_confirmation': 'school-password-12345',
  }.entries) {
    await tester.ensureVisible(field(entry.key));
    await tester.enterText(field(entry.key), entry.value);
  }
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
}

http.Response created({int? organizationId}) => http.Response(
  jsonEncode({
    'school': {'id': 10, 'name': 'School', 'email': 'school@example.org', 'organization_id': organizationId},
    'account': {'id': 50, 'email': 'school@example.org', 'role': 'school'},
    'verification_email_sent': true,
  }),
  201,
);

void main() {
  for (final language in ['ar', 'en']) {
    testWidgets('required fields block HTTP in $language', (tester) async {
      var posts = 0;
      final repository = SchoolAccountRepository(
        post: (path, body) async {
          posts++;
          return created();
        },
      );
      await tester.pumpWidget(
        host(AdminSchoolCreatePage(repository: repository), language),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(posts, 0);
      expect(
        find.text(
          language == 'en' ? 'Enter the school name.' : 'أدخل اسم المدرسة.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'unavailable API shows localized error, never success in $language',
      (tester) async {
        final repository = SchoolAccountRepository(
          post: (path, body) async => http.Response('', 404),
        );
        await tester.pumpWidget(
          host(AdminSchoolCreatePage(repository: repository), language),
        );
        await tester.pumpAndSettle();
        await fill(tester);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('school-account-error')),
          findsOneWidget,
        );
        expect(
          find.text(
            language == 'en'
                ? 'School account creation is not available on the server yet.'
                : 'خدمة إنشاء حسابات المدارس غير متاحة على السيرفر حاليًا.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('school-account-success')),
          findsNothing,
        );
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      },
    );

    testWidgets(
      'affiliated form works on small screens with large text in $language',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 640));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final repository = SchoolAccountRepository(
          get: (_) async => http.Response(
            jsonEncode({
              'organization': {'id': 4, 'slug': 'demo-institution'},
            }),
            200,
          ),
          post: (path, _) async {
            expect(path, '/institutions/demo-institution/school-accounts');
            return created(organizationId: 4);
          },
        );
        await tester.pumpWidget(
          host(
            InstitutionSchoolAccountScreen(repository: repository),
            language,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        await fill(tester);
        await tester.tap(submit);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('school-account-success')),
          findsOneWidget,
        );
        expect(find.byType(TextFormField), findsNothing);
        expect(find.byKey(const ValueKey('school-account-verification-guidance')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('internal identifier cannot be used as a school email', (tester) async {
    var posts = 0;
    final repository = SchoolAccountRepository(post: (_, body) async { posts++; return created(); });
    await tester.pumpWidget(host(AdminSchoolCreatePage(repository: repository), 'en'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.enterText(field('email'), 'user@school.edubridge');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(posts, 0);
    expect(field('password'), findsOneWidget);
    expect(field('password_confirmation'), findsOneWidget);
  });

  testWidgets(
    'pending submission disables button and fields, then shows success',
    (tester) async {
      final pending = Completer<http.Response>();
      var posts = 0;
      final repository = SchoolAccountRepository(
        post: (path, body) {
          posts++;
          return pending.future;
        },
      );
      await tester.pumpWidget(
        host(AdminSchoolCreatePage(repository: repository), 'en'),
      );
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.tap(submit);
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(tester.widget<TextFormField>(field('email')).enabled, isFalse);
      await tester.tap(submit);
      expect(posts, 1);
      pending.complete(created());
      await tester.pumpAndSettle();
      expect(find.text('School and its login account created successfully.'), findsOneWidget);
      expect(find.byKey(const ValueKey('school-account-verification-guidance')), findsOneWidget);
      expect(submit, findsNothing);
    },
  );

  testWidgets(
    'leaving the screen during a request does not update disposed state',
    (tester) async {
      final pending = Completer<http.Response>();
      final repository = SchoolAccountRepository(
        post: (path, body) => pending.future,
      );
      await tester.pumpWidget(
        host(AdminSchoolCreatePage(repository: repository), 'en'),
      );
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.tap(submit);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(created());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
