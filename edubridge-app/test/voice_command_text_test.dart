import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_app/services/voice_command_text.dart';

void main() {
  test('Arabic recognition normalizes spelling and matches complete words', () {
    expect(matchesVoiceText('اِفتحْ دُروس ولي الأَمْر!', ['دروس ولي الامر']), isTrue);
    expect(matchesVoiceText('افتح إعدادات التَّكيُّف', ['اعدادات التكيف']), isTrue);
    expect(matchesVoiceText('العدسات', ['العد']), isFalse);
    expect(matchesVoiceText('أوقف القراءة', ['اوقف القراءه']), isTrue);
  });
  test('Child navigation rejects ambiguous names and substring matches', () {
    final children = <Map<String, dynamic>>[
      {'id': 1, 'name': 'محمد أحمد'},
      {'id': 2, 'name': 'محمد علي'},
      {'id': 3, 'name': 'نور'},
    ];
    expect(findVoiceChild('افتح دروس محمد', children), isNull);
    expect(findVoiceChild('افتح دروس محمد أحمد', children)?['id'], 1);
    expect(findVoiceChild('افتح دروس نورا', children), isNull);
    expect(findVoiceChild('افتح تقدم نور', children)?['id'], 3);
  });
}
