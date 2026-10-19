import 'package:edubridge_app/services/app_locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('existing installs default to Arabic and restore a saved English choice', () async {
    final controller = AppLocaleController();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.value, const Locale('ar'));
    await controller.setLocale(const Locale('en'));
    final restored = AppLocaleController();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.value, const Locale('en'));
  });

  test('rapid choices keep the last language on screen and disk', () async {
    final controller = AppLocaleController();
    addTearDown(controller.dispose);
    final first = controller.setLocale(const Locale('en'));
    final last = controller.setLocale(const Locale('ar'));
    await Future.wait([first, last]);
    expect(controller.value, const Locale('ar'));
    final restored = AppLocaleController();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.value, controller.value);
  });

  test('unsupported saved values fall back and invalid choices cannot persist', () async {
    SharedPreferences.setMockInitialValues({'app_interface_language': 'fr'});
    final controller = AppLocaleController();
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.value, const Locale('ar'));
    await expectLater(controller.setLocale(const Locale('fr')), throwsArgumentError);
    expect(controller.value, const Locale('ar'));
    expect((await SharedPreferences.getInstance()).getString('app_interface_language'), 'fr');
  });
}
