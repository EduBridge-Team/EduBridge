import 'package:edubridge_app/services/accessibility_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final role in ['parent', 'teacher', 'admin']) {
    test('$role cannot persist a child adaptation override locally', () async {
      SharedPreferences.setMockInitialValues({'role': role});
      const next = AccessibilityProfile(type: DisabilityType.blind);
      await expectLater(
        AccessibilityService.instance.updateForChild(901, next),
        throwsStateError,
      );
      expect(AccessibilityService.instance.profileForChild(901), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('acc_child_profile_901'), isFalse);
    });
  }
}
