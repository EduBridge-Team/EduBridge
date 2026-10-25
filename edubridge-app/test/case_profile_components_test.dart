import 'package:edubridge_app/features/students/presentation/student_learning_metrics_cards.dart';
import 'package:edubridge_app/features/students/presentation/student_profile_action_card.dart';
import 'package:edubridge_app/features/students/presentation/student_profile_details_section.dart';
import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/case_discussion/case_discussion_s21.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, String language) => MaterialApp(
  locale: Locale(language),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: Scaffold(body: child),
);

void main() {
  for (final language in ['ar', 'en']) {
    for (final width in [320.0, 720.0, 1280.0]) {
      testWidgets(
        'case dialog callbacks in $language at $width with large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final topic = TextEditingController();
          final description = TextEditingController();
          addTearDown(topic.dispose);
          addTearDown(description.dispose);
          int? toggled;
          var saved = false;
          await tester.pumpWidget(
            host(
              NewCaseStudyDialogS21(
                children: const [
                  {'id': 5, 'name': 'Child'},
                ],
                team: const [
                  {'id': 8, 'name': 'Me', 'role': 'specialist'},
                  {'id': 7, 'name': 'Teacher', 'role': 'teacher'},
                ],
                selectedChildId: 5,
                selectedParticipants: const {8},
                myUserId: 8,
                topicController: topic,
                descriptionController: description,
                loading: false,
                saving: false,
                error: null,
                onChildSelected: (_) {},
                onParticipantToggled: (id) => toggled = id,
                onSave: () => saved = true,
                onCancel: () {},
                onRetry: () {},
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          final checkbox = find.byType(CheckboxListTile);
          expect(checkbox, findsOneWidget);
          await tester.ensureVisible(checkbox);
          await tester.pumpAndSettle();
          await tester.tap(checkbox);
          expect(toggled, 7);
          final save = find.byKey(const ValueKey('s21_create'));
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
          expect(saved, isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );

      testWidgets(
        'metrics known and unknown in $language at $width with large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            host(
              const Padding(
                padding: EdgeInsets.all(14),
                child: StudentLearningMetricsCards(
                  lessonsCount: 3,
                  completionPercent: 33,
                ),
              ),
              language,
            ),
          );
          expect(find.text('3'), findsOneWidget);
          expect(find.text('33%'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            host(
              const StudentLearningMetricsCards(
                lessonsCount: null,
                completionPercent: null,
              ),
              language,
            ),
          );
          expect(find.text('—'), findsNWidgets(2));
          expect(find.text('0%'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
      testWidgets(
        'profile actions and details in $language at $width with large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var opened = false;
          await tester.pumpWidget(
            host(
              ListView(
                children: [
                  StudentProfileActionCard(
                    icon: Icons.menu_book,
                    title: 'Action title',
                    subtitle: 'A complete description that can wrap when text is enlarged',
                    tint: Colors.blue.shade50,
                    accent: Colors.blue,
                    badge: '3',
                    onTap: () => opened = true,
                  ),
                  const StudentProfileDetailsSection(
                    title: 'Details',
                    subtitle: 'A complete details summary that can wrap',
                    icon: Icons.badge,
                    children: [Text('Expanded detail')],
                  ),
                ],
              ),
              language,
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Action title'));
          expect(opened, isTrue);
          expect(
            find.byIcon(
              language == 'ar'
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
            ),
            findsOneWidget,
          );
          final tile = find.byType(ExpansionTile);
          await tester.ensureVisible(tile);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Details'));
          await tester.pumpAndSettle();
          expect(find.text('Expanded detail'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
