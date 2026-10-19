import 'dart:async';
import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/specialist_suggestions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _response(Object data, [int status = 200]) => http.Response(jsonEncode(data), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
Map<String, Object> _suggestion({String status = 'pending', String name = 'محمود'}) => {
  'id': 27, 'child_name': name, 'suggested_by_name': 'المعلم الأصلي',
  'specialty': 'learning_support', 'status': status, 'reason': 'سبب الاقتراح الأصلي',
};
Future<void> _mount(WidgetTester tester, String language, {double scale = 1}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(360, 800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: const SpecialistSuggestionsScreen()));
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    await tester.tap(target.hitTestable());
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language suggestions scale=$scale preserve text and filter IDs', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final paths = <Uri>[];
        await http.runWithClient(() async {
          await _mount(tester, language, scale: scale);
          expect(find.text(strings.followupSuggestionsTitle), findsOneWidget);
          expect(find.text('محمود'), findsOneWidget);
          expect(find.text('سبب الاقتراح الأصلي'), findsOneWidget);
          expect(find.text(strings.ticketFromUser('المعلم الأصلي')), findsOneWidget);
          expect(Directionality.of(tester.element(find.byType(Scaffold))), language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          for (final entry in {
            strings.followupAcceptedFilter: 'accepted', strings.rejectedStatus: 'rejected', strings.all: null,
          }.entries) {
            await _tap(tester, find.widgetWithText(ChoiceChip, entry.key));
            expect(paths.last.queryParameters['status'], entry.value);
          }
        }, () => MockClient((request) async {
          paths.add(request.url);
          return _response({'suggestions': [_suggestion(status: request.url.queryParameters['status'] ?? 'accepted')]});
        }));
      });
    }
    testWidgets('$language accept cancellation and confirmation retain suggestion ID', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, language, scale: 2);
        await _tap(tester, find.text(strings.followupAcceptAndFollow));
        expect(find.text(strings.followupAcceptQuestion('محمود', strings.learningSupportSpecialist)), findsOneWidget);
        await _tap(tester, find.text(strings.cancel));
        expect(writes, isEmpty);
        await _tap(tester, find.text(strings.followupAcceptAndFollow));
        await _tap(tester, find.widgetWithText(FilledButton, strings.followupAccept));
        expect(writes.single.method, 'PUT');
        expect(writes.single.url.path, endsWith('/specialist-suggestions/27/accept'));
        expect(jsonDecode(writes.single.body), isEmpty);
        expect(find.text(strings.followupAcceptedNotice), findsOneWidget);
      }, () => MockClient((request) async {
        if (request.method == 'GET') return _response({'suggestions': [_suggestion()]});
        writes.add(request);
        return _response({});
      }));
    });
    testWidgets('$language rejection preserves authored reason and survives server failure', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      final writes = <http.Request>[];
      await http.runWithClient(() async {
        await _mount(tester, language, scale: 2);
        await _tap(tester, find.widgetWithText(OutlinedButton, strings.reject));
        await tester.enterText(find.byType(TextField), '  سبب الرفض الأصلي  ');
        await _tap(tester, find.widgetWithText(FilledButton, strings.reject));
        expect(writes.single.url.path, endsWith('/specialist-suggestions/27/reject'));
        expect(jsonDecode(writes.single.body), {'reason': 'سبب الرفض الأصلي'});
        expect(find.text(strings.followupRejectedNotice), findsNothing);
        expect(find.text(language == 'en' ? strings.genericError : 'خطأ من الخادم'), findsOneWidget);
        await _tap(tester, find.widgetWithText(OutlinedButton, strings.reject));
        await _tap(tester, find.text(strings.cancel));
        expect(writes, hasLength(1));
      }, () => MockClient((request) async {
        if (request.method == 'GET') return _response({'suggestions': [_suggestion()]});
        writes.add(request);
        return _response({'error': 'خطأ من الخادم'}, 500);
      }));
    });
    testWidgets('$language load errors retry and empty names are safe', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      var calls = 0;
      await http.runWithClient(() async {
        await _mount(tester, language);
        expect(find.text(strings.followupSuggestionsLoadFailed), findsOneWidget);
        expect(find.text(strings.followupNoPending), findsNothing);
        await _tap(tester, find.text(strings.retryAction));
        expect(find.text('?'), findsOneWidget);
      }, () => MockClient((request) async => ++calls == 1
        ? _response({}, 500) : _response({'suggestions': [_suggestion(name: '')]})));
    });
  }
  testWidgets('late filter responses cannot overwrite current suggestions', (tester) async {
    final pending = Completer<http.Response>();
    await http.runWithClient(() async {
      await tester.runAsync(() async {
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('en'), supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const SpecialistSuggestionsScreen()));
        await Future<void>.delayed(Duration.zero);
        await tester.pump();
        await tester.tap(find.widgetWithText(ChoiceChip, 'Accepted'));
        await tester.pump();
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.text('Current child'), findsOneWidget);
      await tester.runAsync(() async {
        pending.complete(_response({'suggestions': [_suggestion(name: 'Stale child')]}));
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pumpAndSettle();
      expect(find.text('Current child'), findsOneWidget);
      expect(find.text('Stale child'), findsNothing);
    }, () => MockClient((request) async => request.url.queryParameters['status'] == 'pending'
      ? await pending.future : _response({'suggestions': [_suggestion(status: 'accepted', name: 'Current child')]})));
  });
}
