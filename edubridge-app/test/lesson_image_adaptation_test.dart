import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:edubridge_app/widgets/accessibility/alt_text_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => AccessibilityService.instance.resetSession());
  testWidgets('text-only lesson images show selected description without loading an image', (tester) async {
    AccessibilityService.instance.profile.value = const AccessibilityProfile(
      type: DisabilityType.none, textOnlyMode: true, detailedAltText: true,
    );
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AltTextImage(
      imageUrl: 'https://example.invalid/image.png', altText: 'وصف قصير',
      detailedDescription: 'وصف كامل للصورة',
    ))));
    expect(find.text('وصف كامل للصورة'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    AccessibilityService.instance.profile.value = const AccessibilityProfile(
      type: DisabilityType.none, textOnlyMode: true,
    );
    await tester.pump();
    expect(find.text('وصف قصير'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
