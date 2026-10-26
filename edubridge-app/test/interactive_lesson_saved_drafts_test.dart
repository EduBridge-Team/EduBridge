import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/interactive_draft_repository.dart';

void main() {
  test('saved draft list validates identity and version', () {
    final draft = InteractiveDraftSummary.fromJson({
      'id': 3, 'version': 2, 'template_id': 'ar-alif-01',
      'title': 'عنوان', 'objective': 'نتاج',
    });
    expect(draft.id, 3);
    expect(draft.version, 2);
    expect(draft.templateId, 'ar-alif-01');
  });

  test('saved draft summary rejects malformed data', () {
    final valid = {
      'id': 3, 'version': 2, 'template_id': 'ar-alif-01',
      'title': 'عنوان', 'objective': 'نتاج',
    };
    for (final invalid in [
      {...valid, 'id': 0},
      {...valid, 'version': 0},
      {...valid, 'title': '  '},
      {...valid, 'objective': null},
      {...valid, 'template_id': ''},
    ]) {
      expect(() => InteractiveDraftSummary.fromJson(invalid), throwsFormatException);
    }
  });
}
