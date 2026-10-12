import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('changing classification preserves every adaptation field', () {
    final original = AccessibilityProfile.recommendedFor(DisabilityType.adhd)
        .copyWith(brainBreakDurationSeconds: 90, slowSpeech: true, autoReadOnTap: false);
    final changed = original.withDisability(DisabilityType.downSyndrome);
    final before = original.toJson()..remove('type')..remove('customDisabilityName');
    final after = changed.toJson()..remove('type')..remove('customDisabilityName');
    expect(after, before);
    expect(changed.type, DisabilityType.downSyndrome);
  });

  test('custom classification name can be cleared without resetting adaptations', () {
    const original = AccessibilityProfile(type: DisabilityType.other,
        customDisabilityName: 'مخصص', extraLargeTouchTargets: true);
    final changed = original.withDisability(DisabilityType.deaf);
    expect(changed.customDisabilityName, isNull);
    expect(changed.extraLargeTouchTargets, isTrue);
  });
}
