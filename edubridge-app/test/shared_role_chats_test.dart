import 'package:edubridge_app/features/communication/data/conversation_repository.dart';
import 'package:edubridge_app/screens/chats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final role in [
    'parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution',
  ]) {
    testWidgets('$role uses the shared contact dialog with role navigation',
        (tester) async {
      SharedPreferences.setMockInitialValues({'role': role});
      final repository = ConversationRepository(
        conversations: () async => [],
        users: () async => [
          {'id': 42, 'name': 'جهة التواصل المتاحة', 'role': 'teacher'},
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: ChatsScreen(repository: repository),
      ));
      await tester.pumpAndSettle();
      expect(find.text('لا توجد محادثات بعد'), findsOneWidget);
      expect(find.text('دراسات الحالة'),
          role == 'specialist' ? findsOneWidget : findsNothing);
      await tester.tap(find.text('محادثة جديدة'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactPickerDialog), findsOneWidget);
      expect(find.text('جهة التواصل المتاحة'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('s19_cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
