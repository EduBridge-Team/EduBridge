import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/screens/institutions/institution_school_form_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final editing in [false, true]) {
    for (final language in ['ar', 'en']) {
      for (final width in [320.0, 720.0, 1280.0]) {
        testWidgets(
          '${editing ? 'edit' : 'create'} school fields at $width in $language with large text',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            Map<String, String>? fields;
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
                home: Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () async =>
                          fields = await InstitutionSchoolFormDialog.show(
                            context,
                            school: editing
                                ? {
                                    'id': 9,
                                    'name': 'Old',
                                    'address': 'Gaza',
                                    'phone': '123',
                                  }
                                : null,
                          ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.text('open'));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byType(TextFormField).first,
              '  New name  ',
            );
            if (!editing)
              await tester.enterText(
                find.byType(TextFormField).last,
                'new-school',
              );
            final save = find.byType(FilledButton);
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(
              fields,
              editing
                  ? {'name': 'New name', 'address': 'Gaza', 'phone': '123'}
                  : {'name': 'New name', 'slug': 'new-school'},
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
