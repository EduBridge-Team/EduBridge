import 'package:edubridge_app/screens/notifications_screen.dart';
import 'package:edubridge_app/services/notification_listener_service.dart';
import 'package:edubridge_app/widgets/notification_snackbar.dart';
import 'dart:convert';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/ministry_statistics_screen.dart';
import 'package:edubridge_app/widgets/listen_button.dart';
import 'package:edubridge_app/widgets/tts_toggle_button.dart';
import 'package:edubridge_app/widgets/accessibility/read_mode_badge.dart';
import 'package:edubridge_app/widgets/disability/disability_display.dart';
import 'package:edubridge_app/services/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

MockClient _client({bool empty = false}) => MockClient((request) async {
  expect(request.method, 'GET');
  expect(request.url.path.endsWith('/ministry/statistics'), isTrue);
  return http.Response(jsonEncode(empty ? {} : {
    'total_children': 120000, 'active_children': 100000, 'homework_completion_rate': 85,
    'learning_support_meetings_count': 500,
    'by_disability_type': {'متلازمة داون': 6, 'غير محدد': 3, 'وصف مخصص من المؤسسة': 1},
    'by_age_group': {'0-5': 2, '6-9': 5, '10-13': 2, '14+': 1},
  }), 200, headers: {'content-type': 'application/json; charset=utf-8'});
});
Future<void> _mount(WidgetTester tester, Widget screen, String language, {double scale = 1}) async {
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
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale)), child: child!), home: screen));
    for (var frame = 0; frame < 3; frame++) {
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    }
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pumpAndSettle();
}
Future<void> _tap(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(target, 180, scrollable: find.byType(Scrollable).first);
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
  setUp(() {
    SharedPreferences.setMockInitialValues({'role': 'ministry', 'userId': 6});
    FlutterSecureStorage.setMockInitialValues({});
    TtsService.instance.tapToRead.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => 1);
  });
  tearDown(() {
    TtsService.instance.tapToRead.value = false;
    NotificationListenerService.instance.notifications.value = [];
    NotificationListenerService.instance.latestNotification.value = null;
  });
  for (final language in ['ar', 'en']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$language ministry statistics at $scale preserve counts and localize known disability labels', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await http.runWithClient(() async {
          await _mount(tester, const MinistryStatisticsScreen(), language, scale: scale);
          expect(find.text(strings.ministryStatsPageTitle), findsOneWidget);
          expect(find.text('120000'), findsOneWidget);
          expect(find.text('85%'), findsOneWidget);
          final down = DisabilityDisplay.label('متلازمة داون', strings);
          await tester.scrollUntilVisible(find.text(down), 160, scrollable: find.byType(Scrollable).first);
          expect(find.text(down), findsOneWidget);
          expect(find.text(DisabilityDisplay.label('غير محدد', strings)), findsOneWidget);
          expect(find.text('وصف مخصص من المؤسسة'), findsOneWidget);
          expect(tester.widgetList<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
            .map((widget) => widget.value), contains(.6));
          await tester.scrollUntilVisible(find.text('0-5'), 160, scrollable: find.byType(Scrollable).first);
          final range = tester.widget<Text>(find.text('0-5'));
          expect(range.textDirection, TextDirection.ltr);
        }, () => _client());
      });
      testWidgets('$language notification list and details at $scale preserve body text', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        final notification = <String, dynamic>{
          'title': 'تم رفض هويتك',
          'message': 'محتوى أصلي Original content',
          'type': 'verification',
          'is_read': true,
        };
        NotificationListenerService.instance.notifications.value = [notification];
        await _mount(tester, const NotificationsScreen(), language, scale: scale);
        expect(find.text(strings.notificationTitleIdentityRejected), findsOneWidget);
        expect(find.text('محتوى أصلي Original content'), findsOneWidget);
        await _tap(tester, find.text(strings.notificationTitleIdentityRejected));
        expect(find.text(strings.notificationTitleIdentityRejected), findsNWidgets(2));
        expect(find.text('محتوى أصلي Original content'), findsNWidgets(2));
        expect(notification['title'], 'تم رفض هويتك');
        expect(notification['message'], 'محتوى أصلي Original content');
      });
      testWidgets('$language notification snackbar at $scale preserves the written message', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await _mount(tester, const Scaffold(body: NotificationSnackbarHost(child: SizedBox())), language, scale: scale);
        NotificationListenerService.instance.latestNotification.value = {
          'id': 5,
          'title': 'تم اعتماد شهادتك',
          'message': 'محتوى أصلي Original content',
          'type': 'certificate',
        };
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.text(strings.notificationTitleCertificateApproved), findsOneWidget);
        expect(find.text('محتوى أصلي Original content'), findsOneWidget);
      });
      testWidgets('$language read controls and badge at $scale share the same state', (tester) async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        await _mount(tester, const Scaffold(body: Column(children: [
          ListenButton(), TtsToggleButton(), ReadModeBadge(),
        ])), language, scale: scale);
        expect(find.text(strings.readingModeEnabled), findsNothing);
        await _tap(tester, find.byTooltip(strings.tapReadStartTooltip));
        expect(TtsService.instance.tapToRead.value, isTrue);
        expect(find.text(strings.readingModeEnabled), findsOneWidget);
        expect(find.text(strings.tapReadEnabledNotice), findsOneWidget);
        expect(find.byTooltip(strings.readingStopTooltip), findsOneWidget);
        ScaffoldMessenger.of(tester.element(find.byType(ListenButton))).removeCurrentSnackBar();
        await tester.pumpAndSettle();
        await _tap(tester, find.byTooltip(strings.tapReadStopTooltip));
        expect(TtsService.instance.tapToRead.value, isFalse);
        expect(find.text(strings.readingModeEnabled), findsNothing);
        expect(find.text(strings.tapReadDisabledNotice), findsOneWidget);
        await _tap(tester, find.byTooltip(strings.readingStartTooltip));
        expect(find.text(strings.readingModeEnabled), findsOneWidget);
        await _tap(tester, find.text(strings.readingModeEnabled));
        expect(TtsService.instance.tapToRead.value, isFalse);
      });
    }
    testWidgets('$language empty ministry statistics retain zero values', (tester) async {
      final strings = await AppLocalizations.delegate.load(Locale(language));
      await http.runWithClient(() async {
        await _mount(tester, const MinistryStatisticsScreen(), language);
        expect(find.text(strings.ministryStatsPageTitle), findsOneWidget);
        expect(find.text('0'), findsNWidgets(3));
        expect(find.text('0%'), findsOneWidget);
      }, () => _client(empty: true));
    });
  }
}
