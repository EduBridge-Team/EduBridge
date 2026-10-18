import 'package:edubridge_app/screens/chat/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('S16 composer sends text without removed communication modes',
      (tester) async {
    SharedPreferences.setMockInitialValues({'chat_composer_mode_v1': 'aac'});
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? sent;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: ChatComposer(
              controller: controller,
              onSend: (text) => sent = text,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('صور (AAC)'), findsNothing);
    expect(find.text('لغة الإشارة'), findsNothing);
    expect(find.text('اكتب رسالتك...'), findsOneWidget);
    final send = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mark_email_read_outlined));
    expect(send.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'مرحبا');
    await tester.pump();
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mark_email_read_outlined)).onPressed,
        isNotNull);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.mark_email_read_outlined));
    expect(sent, 'مرحبا');
  });
}
