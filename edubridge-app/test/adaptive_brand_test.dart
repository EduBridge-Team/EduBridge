import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/theme.dart';
import 'package:edubridge_app/utils/adaptive_helper.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_wrapper.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_button.dart';
import 'package:edubridge_app/widgets/accessibility/adaptive_text.dart';
import 'package:edubridge_app/widgets/accessibility/alt_text_image.dart';
import 'package:edubridge_app/widgets/accessibility/visual_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());
  testWidgets('every adaptation preserves the EduBridge theme and palette', (tester) async {
    final theme = buildJisrTheme();
    for (final type in DisabilityType.values) {
      AccessibilityService.instance.profile.value = AccessibilityProfile.recommendedFor(type)
          .copyWith(highContrast: true, repetitionMode: false);
      await tester.pumpWidget(MaterialApp(theme: theme, home: AdaptiveWrapper(
        child: Builder(builder: (context) {
          expect(Theme.of(context).colorScheme.primary, theme.colorScheme.primary);
          expect(AdaptiveHelper.accentColor(context), theme.colorScheme.primary);
          expect(AdaptiveHelper.surfaceColor(context), theme.scaffoldBackgroundColor);
          expect(AdaptiveHelper.textColor(context), theme.colorScheme.onSurface);
          expect(AdaptiveHelper.cardColor(context), theme.cardColor);
          return const SizedBox();
        }),
      )));
    }
  });
  testWidgets('text-only mode shows the description without requesting an image', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, textOnlyMode: true);
    await tester.pumpWidget(const MaterialApp(home: AltTextImage(imageUrl: 'https://invalid.example/image.png', altText: 'وصف الصورة')));
    expect(find.byType(Image), findsNothing);
    expect(find.text('وصف الصورة'), findsOneWidget);
  });
  testWidgets('icon-only mode does not erase standalone instructions', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none, iconOnlyMode: true);
    await tester.pumpWidget(const MaterialApp(home: AdaptiveWrapper(child: AdaptiveText('اختر الإجابة'))));
    expect(find.text('اختر الإجابة'), findsOneWidget);
  });
  testWidgets('an adaptive button with no callback remains disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AdaptiveButton(label: 'انتظر', onPressed: null))));
    expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNull);
  });
  testWidgets('an untimed non-flashing alert remains visible and can be dismissed', (tester) async {
    var dismissed = 0;
    AccessibilityService.instance.profile.value = const AccessibilityProfile(type: DisabilityType.none,
      noTimedInteractions: true, noFlashing: true, flashAlerts: true);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VisualAlert(message: 'تنبيه', onDismiss: () => dismissed++))));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('تنبيه'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
    await tester.tap(find.byTooltip('إغلاق التنبيه'));
    await tester.pump();
    expect(dismissed, 1);
    expect(find.text('تنبيه'), findsNothing);
  });
}
