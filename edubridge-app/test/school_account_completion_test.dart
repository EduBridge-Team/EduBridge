import 'dart:async';
import 'dart:convert';

import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/schools/school_account_form.dart';
import 'package:edubridge_app/services/schools/school_account_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'school_account_form_test.dart' show host, fill, field, submit, created;

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      for (final affiliated in [false, true]) {
        testWidgets('school receipt excludes credentials $language $width affiliated=$affiliated', (tester) async {
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var posts = 0;
          final repository = SchoolAccountRepository(
            get: (_) async => http.Response(jsonEncode({
              'organization': {'id': 4, 'slug': 'demo-institution'},
            }), 200),
            post: (path, body) async {
              posts++;
              expect(path, affiliated ? '/institutions/demo-institution/school-accounts' : '/admin/school-accounts');
              return created(organizationId: affiliated ? 4 : null);
            },
          );
          await tester.pumpWidget(host(SchoolAccountForm(
            scope: affiliated ? SchoolAccountScope.affiliated : SchoolAccountScope.independent,
            repository: repository), language, scale: 2));
          await tester.pumpAndSettle();
          await fill(tester);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          final l = await AppLocalizations.delegate.load(Locale(language));
          expect(find.text(l.schoolAccountSuccess), findsOneWidget);
          expect(find.byKey(const ValueKey('school-account-verification-guidance')), findsOneWidget,
            reason: 'The receipt explains school mailbox verification and school login');
          expect(find.byKey(const ValueKey('school-account-created-email')), findsOneWidget);
          expect(find.text('school@example.org'), findsOneWidget);
          expect(find.text('password123'), findsNothing);
          expect(find.byType(TextFormField), findsNothing);
          expect(posts, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final oldFails in [false, true]) {
    testWidgets('old provisioning result cannot finish a replacement submission failure=$oldFails', (tester) async {
      final oldReply = Completer<http.Response>(), newReply = Completer<http.Response>();
      final first = SchoolAccountRepository(post: (_, body) => oldReply.future);
      final second = SchoolAccountRepository(
        get: (_) async => http.Response(jsonEncode({
          'organization': {'id': 4, 'slug': 'demo-institution'},
        }), 200),
        post: (_, body) => newReply.future,
      );
      await tester.pumpWidget(host(SchoolAccountForm(scope: SchoolAccountScope.independent, repository: first), 'en'));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.tap(submit);
      await tester.pump();
      await tester.pumpWidget(host(SchoolAccountForm(scope: SchoolAccountScope.affiliated, repository: second), 'en'));
      await tester.pumpAndSettle();
      expect(field('password'), findsOneWidget);
      expect(tester.widget<TextFormField>(field('email')).controller!.text, isEmpty);
      await fill(tester);
      await tester.tap(submit);
      await tester.pump();
      oldReply.complete(oldFails ? http.Response('{"errors":{"email":["Rejected"]}}', 422) : created());
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      expect(find.byKey(const ValueKey('school-account-success')), findsNothing);
      expect(find.byKey(const ValueKey('school-account-error')), findsNothing);
      newReply.complete(created(organizationId: 4));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('school-account-success')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('back cannot hide school provisioning while awaiting its receipt', (tester) async {
    final reply = Completer<http.Response>();
    var posts = 0;
    final repository = SchoolAccountRepository(post: (_, body) { posts++; return reply.future; });
    await tester.pumpWidget(host(Builder(builder: (context) => Scaffold(body: TextButton(
      child: const Text('Create school'), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => SchoolAccountForm(scope: SchoolAccountScope.independent, repository: repository))),
    ))), 'en'));
    await tester.tap(find.text('Create school'));
    await tester.pumpAndSettle();
    await fill(tester);
    await tester.tap(submit);
    await tester.pump();
    await tester.pageBack();
    await tester.pump();
    expect(find.byType(SchoolAccountForm), findsOneWidget);
    reply.complete(created());
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.byKey(const ValueKey('school-account-success')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Create school'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
