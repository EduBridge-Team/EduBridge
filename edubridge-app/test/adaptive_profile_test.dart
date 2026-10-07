import 'package:edubridge_app/services/accessibility_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every recommended profile survives copyWith and JSON round trips', () {
    for (final type in DisabilityType.values) {
      final profile = AccessibilityProfile.recommendedFor(type, customName: 'مخصص');
      expect(profile.copyWith().toJson(), profile.toJson());
      expect(AccessibilityProfile.fromJson(profile.toJson()).toJson(), profile.toJson());
    }
  });
  test('switch control and untimed interaction can be enabled and disabled independently', () {
    const base = AccessibilityProfile(type: DisabilityType.none);
    final enabled = base.copyWith(switchControl: true, noTimedInteractions: true);
    expect(enabled.switchControl, isTrue);
    expect(enabled.noTimedInteractions, isTrue);
    expect(enabled.copyWith(highContrast: true).switchControl, isTrue);
    expect(enabled.copyWith(switchControl: false).noTimedInteractions, isTrue);
    expect(enabled.copyWith(noTimedInteractions: false).switchControl, isTrue);
  });
  test('malformed remote data uses safe types and bounded intervals', () {
    final profile = AccessibilityProfile.fromJson({
      'type': 4, 'customDisabilityName': [], 'switchControl': 'true',
      'noTimedInteractions': 1, 'highContrast': {}, 'videoCaptions': 'false',
      'brainBreakIntervalMinutes': -1, 'timerRenewalMinutes': '999999',
    });
    expect(profile.type, DisabilityType.none);
    expect(profile.customDisabilityName, isNull);
    expect(profile.switchControl, isTrue);
    expect(profile.noTimedInteractions, isTrue);
    expect(profile.highContrast, isFalse);
    expect(profile.videoCaptions, isFalse);
    expect(profile.brainBreakIntervalMinutes, 1);
    expect(profile.timerRenewalMinutes, 60);
    expect(AccessibilityProfile.fromJson({'timerRenewalMinutes': []}).timerRenewalMinutes, 5);
  });
}
