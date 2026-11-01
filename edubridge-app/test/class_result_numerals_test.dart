import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/screens/class_lesson_results/class_result_controller.dart';
import 'class_result_fixture.dart';

void main() {
  for (final numbers in [
    ['0', '10', '2.5'],
    ['٠', '١٠', '٢٫٥'],
    ['۰', '۱۰', '۲٫۵'],
  ]) {
    test('localized decimal input submits numeric values $numbers', () async {
      final f = ClassResultFixture();
      final controller = ClassResultController(f.repository);
      addTearDown(controller.dispose);
      await controller.reload();
      final options = controller.options!, epoch = controller.generation;
      controller.change(options, epoch, () {
        controller.state = 'completed';
        controller.observedOn = DateTime(2026, 10, 28);
        controller.observation = 'Authored observation';
        controller.score = numbers[0];
        controller.maximum = numbers[1];
        controller.measurement = numbers[2];
      });
      expect(controller.canSubmit, isTrue);
      await controller.submit(options, epoch, controller.draft!);
      expect(controller.resultId, 88);
      expect(f.body!['score'], 0);
      expect(f.body!['maximum'], 10);
      expect(
          f.body!['goal_measurement'], {'value': 2.5, 'unit': 'عدد المحاولات'});
    });
  }
  for (final invalid in [
    'NaN',
    'Infinity',
    '١e٢',
    '0x10',
    '-١',
    '١ ٢',
    '١٫٢٫٣'
  ]) {
    test('invalid localized measurement cannot enable recording $invalid',
        () async {
      final f = ClassResultFixture();
      final controller = ClassResultController(f.repository);
      addTearDown(controller.dispose);
      await controller.reload();
      controller.change(controller.options!, controller.generation, () {
        controller.state = 'completed';
        controller.observedOn = DateTime(2026, 10, 28);
        controller.observation = 'Authored observation';
        controller.measurement = invalid;
      });
      expect(controller.canSubmit, isFalse);
      expect(f.posts, 0);
    });
  }
}
