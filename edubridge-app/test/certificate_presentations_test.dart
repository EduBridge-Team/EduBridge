import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/certificates/certificate_submission_form.dart';
import 'package:edubridge_app/screens/certificates/specialist_certificate_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final specialist in [false, true]) {
    for (final language in ['ar', 'en']) {
      for (final width in [320.0, 720.0, 1280.0]) {
        testWidgets(
          '${specialist ? 'dialog' : 'sheet'} certificate at $width in $language with large text',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final controller = TextEditingController(text: 'Certificate');
            addTearDown(controller.dispose);
            var removed = false;
            var saved = false;
            final strings = await AppLocalizations.delegate.load(
              Locale(language),
            );
            final presentation = specialist
                ? SpecialistCertificateDialog(
                    titleController: controller,
                    fileName: 'training.pdf',
                    saving: false,
                    error: null,
                    onPickFile: () {},
                    onRemoveFile: () => removed = true,
                    onSave: () => saved = true,
                  )
                : CertificateSubmissionForm(
                    titleController: controller,
                    fileName: 'training.pdf',
                    saving: false,
                    error: null,
                    onPickFile: () {},
                    onRemoveFile: () => removed = true,
                    onSave: () => saved = true,
                  );
            await tester.pumpWidget(
              MaterialApp(
                locale: Locale(language),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: Scaffold(body: presentation),
              ),
            );
            await tester.pumpAndSettle();
            expect(find.text('training.pdf'), findsOneWidget);
            final remove = specialist
                ? find.byTooltip(strings.removeSelectedFile)
                : find.descendant(
                    of: find
                        .ancestor(
                          of: find.text('training.pdf'),
                          matching: find.byType(Row),
                        )
                        .first,
                    matching: find.byType(IconButton),
                  );
            await tester.ensureVisible(remove);
            await tester.pumpAndSettle();
            await tester.tap(remove);
            expect(removed, isTrue);
            final save = specialist
                ? find.byKey(const ValueKey('s18_submit_certificate'))
                : find.byType(FilledButton);
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            await tester.tap(save);
            expect(saved, isTrue);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
}
