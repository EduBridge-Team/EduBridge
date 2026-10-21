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
  test('English aliases share command intents without changing name matching', () {
    for (final entry in voiceCommandEnglishAliases.entries) {
      for (final phrase in entry.value) {
        expect(matchesVoiceCommand('Please $phrase for Sam!', [entry.key]), isTrue,
          reason: '$phrase maps to ${entry.key}');
      }
    }
    expect(matchesVoiceCommand('homeworkshop', ['واجب']), isFalse);
    expect(matchesVoiceCommand('backpack', ['ارجع']), isFalse);
    expect(matchesVoiceCommand('stop reading', ['اوقف القراءه']), isTrue);
    expect(matchesVoiceText('open lessons for children', ['اطفال']), isFalse);
    final children = <Map<String, dynamic>>[
      {'id': 1, 'name': 'Sam Lee'}, {'id': 2, 'name': 'Sam Brown'},
      {'id': 3, 'name': 'ليان'}, {'id': 4, 'name': 'اطفال'},
    ];
    expect(findVoiceChild('open lessons for Sam', children), isNull);
    expect(findVoiceChild('open lessons for Sam Lee', children)?['id'], 1);
    expect(findVoiceChild('open homework for ليان', children)?['id'], 3);
    expect(findVoiceChild('open lessons for children', children), isNull);
  });
}
