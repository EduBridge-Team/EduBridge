import 'package:edubridge_app/utils/presentation_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial preserves grapheme clusters including emoji', () {
    expect(PresentationText.initial('👩‍🏫 مدرسة'), '👩‍🏫');
    expect(PresentationText.initial('لَمى'), 'لَ');
  });
  test('caller whitespace and fallback conventions remain distinct', () {
    expect(PresentationText.initial(' اسم'), ' ');
    expect(PresentationText.initial(' اسم', trim: true), 'ا');
    expect(PresentationText.initial('   ', trim: true, fallback: 'م'), 'م');
    expect(PresentationText.initial(null), '؟');
    expect(PresentationText.initial('', fallback: ''), '');
  });
  test('clock keeps original unpadded hours and padded minutes', () {
    final date = DateTime(2026, 10, 7, 9, 3);
    expect(PresentationText.clock(date), '9:03');
    expect(PresentationText.clock(date, padHour: true), '09:03');
    expect(PresentationText.clock(DateTime(2026, 10, 7, 0, 0)), '0:00');
  });
}
