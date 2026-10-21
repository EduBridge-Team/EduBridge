import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/child_accessibility/child_accessibility_settings_screen.dart';
import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object value, [int status = 200]) => http.Response(jsonEncode(value), status,
  headers: {'content-type': 'application/json; charset=utf-8'});
const _screen = ChildAccessibilitySettingsScreen(childId: 7, childName: 'محمود', disabilityTypeHint: 'أخرى');
Future<void> _pump(WidgetTester tester, {String language = 'en', double scale = 1}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(MaterialApp(locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!), home: _screen));
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    }
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 200, scrollable: find.byType(Scrollable).first);
  }
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({'userId': 1, 'role': 'specialist'});
    FlutterSecureStorage.setMockInitialValues({});
    AccessibilityService.instance.resetSession();
    await AccessibilityService.instance.load();
  });
  tearDown(AccessibilityService.instance.resetSession);
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language settings at $scale preserve permissions, unavailable switches and original content', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(320, 900);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final s = await AppLocalizations.delegate.load(Locale(language));
        final puts = <Map<String, dynamic>>[];
        final profile = const AccessibilityProfile(type: DisabilityType.none).toJson();
        await http.runWithClient(() async {
          await _pump(tester, language: language, scale: scale);
          expect(find.text(s.adaptationSettingsFor('محمود')), findsOneWidget);
          expect(Directionality.of(tester.element(find.byType(SwitchListTile).first)),
            language == 'ar' ? TextDirection.rtl : TextDirection.ltr);
          await tester.enterText(find.byType(TextField), '');
          await _tap(tester, find.text(s.adaptationSaveDisability));
          expect(find.text(s.adaptationEnterName), findsOneWidget);
          ScaffoldMessenger.of(tester.element(find.byType(TextField))).removeCurrentSnackBar();
          await tester.enterText(find.byType(TextField), 'وصف المختص الأصلي');
          await _tap(tester, find.text(s.adaptationSaveDisability));
          expect(puts.last['profile']['customDisabilityName'], 'وصف المختص الأصلي');
          expect(puts.last['profile']['type'], 'other');
          expect(find.text(s.adaptationCustomSaved), findsOneWidget);
          await _tap(tester, find.text(s.adaptationHearingSection));
          final flash = find.widgetWithText(SwitchListTile, s.adaptationFlashAlerts);
          expect(tester.widget<SwitchListTile>(flash).onChanged, isNull);
          await _tap(tester, find.text(s.adaptationBreakSection));
          expect(find.text(s.adaptationMinutes(15)), findsWidgets);
          expect(find.text(s.adaptationSeconds(30)), findsWidgets);
          expect(tester.takeException(), isNull);
        }, () => MockClient((request) async {
          expect(request.url.path.endsWith('/children/7/accessibility-profile'), isTrue);
          if (request.method == 'PUT') {
            puts.add(Map<String, dynamic>.from(jsonDecode(request.body)));
            return _json({});
          }
          expect(request.method, 'GET');
          return _json({'can_edit': true, 'profile': profile});
        }));
      });
    }
    testWidgets('$language denies nonassigned users without enabling controls', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _pump(tester, language: language);
        expect(find.text(s.adaptationRestricted), findsOneWidget);
        expect(find.byType(SwitchListTile), findsNothing);
        expect(tester.takeException(), isNull);
      }, () => MockClient((request) async {
        expect(request.method, 'GET');
        return _json({'can_edit': false, 'profile': const AccessibilityProfile(type: DisabilityType.none).toJson()});
      }));
    });
    testWidgets('$language save failure keeps draft and permits retry', (tester) async {
      final s = await AppLocalizations.delegate.load(Locale(language));
      var fail = true;
      var puts = 0;
      await http.runWithClient(() async {
        await _pump(tester, language: language);
        await tester.enterText(find.byType(TextField), 'ملاحظة أصلية');
        await _tap(tester, find.text(s.adaptationSaveDisability));
        expect(find.text(s.adaptationSaveFailed), findsOneWidget);
        expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'ملاحظة أصلية');
        ScaffoldMessenger.of(tester.element(find.byType(TextField))).removeCurrentSnackBar();
        fail = false;
        await _tap(tester, find.text(s.adaptationSaveDisability));
        expect(puts, 2);
        expect(find.text(s.adaptationCustomSaved), findsOneWidget);
      }, () => MockClient((request) async {
        if (request.method == 'PUT') { puts++; return _json({}, fail ? 500 : 200); }
        return _json({'can_edit': true, 'profile': const AccessibilityProfile(type: DisabilityType.none).toJson()});
      }));
    });
  }
}
