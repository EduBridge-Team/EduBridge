import 'package:edubridge_app/features/lessons/domain/caption_sound_cues.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses authored sound cues without inventing descriptions', () {
    expect(captionSoundCues('مرحباً [موسيقى] ثم [باب يطرق]'), '[موسيقى] [باب يطرق]');
    expect(captionSoundCues('مرحباً'), '');
    expect(captionSoundCues('[نص غير مكتمل'), '');
  });
}
