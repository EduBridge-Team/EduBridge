import 'package:edubridge_app/services/lesson_resume_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = LessonResumeService();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('positions stay separate across accounts children and lessons', () async {
    await service.save(1, 2, 3, 'content', 2);
    expect(await service.load(1, 2, 3, 'content', 4), 2);
    expect(await service.load(9, 2, 3, 'content', 4), 0);
    expect(await service.load(1, 9, 3, 'content', 4), 0);
    expect(await service.load(1, 2, 9, 'content', 4), 0);
  });

  test('changed content and invalid positions start at the first step', () async {
    await service.save(1, 2, 3, 'old', 2);
    expect(await service.load(1, 2, 3, 'new', 4), 0);
    expect(await service.load(1, 2, 3, 'old', 2), 0);
    await service.save(1, 2, 3, 'old', -1);
    expect(await service.load(1, 2, 3, 'old', 4), 0);
  });
}
