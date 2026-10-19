import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/l10n/l10n.dart';
import 'package:edubridge_app/features/communication/data/conversation_repository.dart';
import 'package:edubridge_app/screens/verify_identity/verify_identity_screen.dart';
import 'package:edubridge_app/theme.dart';
import 'package:edubridge_app/screens/add_certificate_sheet.dart';
import 'package:edubridge_app/screens/change_password_screen.dart';
import 'package:edubridge_app/screens/chat/chat_composer.dart';
import 'package:edubridge_app/screens/chats_screen.dart';
import 'package:edubridge_app/screens/login_screen.dart';
import 'package:edubridge_app/screens/password_recovery_screen.dart';
import 'package:edubridge_app/screens/profile/profile_screen.dart';
import 'package:edubridge_app/screens/register_screen.dart';
import 'package:edubridge_app/screens/support_sheet.dart';
import 'package:edubridge_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {String language = 'en', double scale = 1}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true,
      textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  final screens = <String, Widget>{
    'sign in': const LoginScreen(),
    'register': const RegisterScreen(),
    'recover password': const ForgotPasswordScreen(),
    'change password': const ChangePasswordScreen(),
    'certificate': AddCertificateSheet(onSaved: () {}),
  };
  for (final entry in screens.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('English ${entry.key} fits 360px at text scale $scale', (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_host(entry.value, scale: scale));
        await tester.pumpAndSettle();
        final fields = find.byType(EditableText);
        expect(fields, findsWidgets);
        expect(Directionality.of(tester.element(fields.first)), TextDirection.ltr);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('English onboarding retains every tour page and navigates to landing', (tester) async {
    await tester.pumpWidget(_host(const WelcomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Learning that adapts to every child'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Specialist'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create a new account'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('support validation follows locale without losing a draft', (tester) async {
    const screen = Scaffold(body: SupportSheet());
    await tester.pumpWidget(_host(screen, language: 'ar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'موضوع كتبه المستخدم');
    await tester.tap(find.text('إرسال'));
    await tester.pump();
    expect(find.text('الرجاء تعبئة الموضوع والرسالة'), findsOneWidget);
    await tester.pumpWidget(_host(screen));
    await tester.pumpAndSettle();
    expect(find.text('Enter a subject and message'), findsOneWidget);
    expect(find.text('موضوع كتبه المستخدم'), findsOneWidget);
    expect(find.text('Contact technical support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deletion requires the exact confirmation in the current language', (tester) async {
    const screen = Scaffold(body: DeleteAccountDialog());
    await tester.pumpWidget(_host(screen, language: 'ar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'حذف');
    await tester.pump();
    ElevatedButton button() => tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button().onPressed, isNotNull);
    await tester.pumpWidget(_host(screen));
    await tester.pumpAndSettle();
    expect(button().onPressed, isNull);
    expect(find.text('To confirm, type "DELETE" in the field below:'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(button().onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(button().onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('registration translates labels and validation while keeping role IDs', (tester) async {
    await tester.pumpWidget(_host(const RegisterScreen()));
    await tester.pumpAndSettle();
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>).first);
    // Menu labels may change; payload identifiers must remain canonical.
    final form = tester.state<FormState>(find.byType(Form));
    expect(dropdown, isNotNull);
    expect(form.validate(), isFalse);
    await tester.pump();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email address is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    final roleMenu = find.byType(DropdownButton<String>);
    final role = tester.widget<DropdownButton<String>>(roleMenu.first);
    expect(role.items!.map((item) => item.value).toSet(), {'parent', 'teacher', 'specialist'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('English composer and contact picker preserve authored Arabic text and identity', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? sent;
    await tester.pumpWidget(_host(Scaffold(body: ChatComposer(
      controller: controller, onSend: (value) => sent = value,
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Write your message…'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'رسالة بالعربية');
    await tester.pump();
    await tester.tap(find.byTooltip('Send'));
    expect(sent, 'رسالة بالعربية');
    int? selected;
    await tester.pumpWidget(_host(Scaffold(body: ContactPickerDialog(
      users: const [{'id': 17, 'name': 'اسم حقيقي', 'role': 'teacher'}],
      onSelect: (user) => selected = user['id'] as int,
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Communication team'), findsOneWidget);
    expect(find.text('اسم حقيقي'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('s19_contact_17')));
    expect(selected, 17);
    expect(tester.takeException(), isNull);
  });

  for (final role in ['parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution']) {
    testWidgets('English shared conversations preserve navigation for $role', (tester) async {
      SharedPreferences.setMockInitialValues({'role': role});
      final repository = ConversationRepository(
        conversations: () async => [], users: () async => [],
      );
      await tester.pumpWidget(_host(ChatsScreen(repository: repository)));
      await tester.pumpAndSettle();
      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Case studies'), role == 'specialist' ? findsOneWidget : findsNothing);
      expect(find.text('New conversation'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('professional verification form translates without changing file actions', (tester) async {
    final nationalId = TextEditingController();
    final certificateTitle = TextEditingController();
    addTearDown(nationalId.dispose);
    addTearDown(certificateTitle.dispose);
    var picked = 0;
    await tester.pumpWidget(_host(Builder(builder: (context) => buildFormState(
      context: context, c: JisrColors.of(context), isTeacherOrSpecialist: true,
      nationalIdCtrl: nationalId, certificateTitleCtrl: certificateTitle,
      idImage: null, certificateFile: null, loading: false, error: null,
      onPickId: () => picked++, onCaptureId: () {}, onRemoveId: () {},
      onPickCertificate: () {}, onCaptureCertificate: () {}, onRemoveCertificate: () {},
      onSubmit: () {},
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Verify identity'), findsOneWidget);
    expect(find.text('Qualification certificate *'), findsOneWidget);
    final pick = find.text('Upload from gallery').first;
    await tester.ensureVisible(pick);
    await tester.tap(pick);
    expect(picked, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unstructured remote errors have a translated English fallback', (tester) async {
    await tester.pumpWidget(_host(Builder(builder: (context) => Scaffold(
      body: Text(context.sharedMessage('رسالة خطأ من الخادم')),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('Unable to complete this action. Please try again.'), findsOneWidget);
    expect(find.text('رسالة خطأ من الخادم'), findsNothing);
  });
}
