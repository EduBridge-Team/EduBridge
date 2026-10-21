import 'package:edubridge_app/l10n/generated/app_localizations.dart';
import 'package:edubridge_app/services/app_locale_controller.dart';
import 'package:edubridge_app/services/speech_input_service.dart';
import 'package:edubridge_app/services/voice_command_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'speech_input_test.dart' show FakeRecognizer, FakeResult;

class CommandRecognizer extends FakeRecognizer implements LanguageSpeechRecognizer {
  final requested = <String>[];
  final selected = <String?>[];
  bool supported = true;
  @override
  Future<String?> localeForLanguage(String language) async {
    requested.add(language);
    return supported ? (language == 'en' ? 'en-US' : 'ar-SA') : null;
  }
  @override
  Future<void> listen({required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult}) async {
    selected.add(options.localeId);
    await super.listen(options: options, onResult: onResult);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('voice navigation selects the UI language and drops results after a locale change', () async {
    final engine = CommandRecognizer();
    final locale = AppLocaleController()..value = const Locale('en');
    final service = VoiceCommandService.forTesting(SpeechInputService.forTesting(engine), locale);
    final calls = <MethodCall>[];
    const channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (call) async { calls.add(call); return 1; });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    addTearDown(locale.dispose);
    addTearDown(service.dispose);
    await service.startListening();
    expect(engine.selected, ['en-US']);
    engine.result!(FakeResult('open lessons for Sam', finalResult: false));
    expect(service.lastHeard.value, 'open lessons for Sam');
    final stale = engine.result!;
    locale.value = const Locale('ar');
    expect(service.isListening.value, isFalse);
    stale(FakeResult('open games'));
    expect(service.lastHeard.value, 'open lessons for Sam');
    await service.cancel();
    await service.startListening();
    expect(engine.selected, ['en-US', 'ar-SA']);
    await service.cancel();
    locale.value = const Locale('en');
    engine.supported = false;
    await service.startListening();
    final strings = await AppLocalizations.delegate.load(const Locale('en'));
    expect(service.lastReply.value, strings.voiceCommandLocaleUnavailable);
    expect(engine.recordings, 2);
    expect(calls.where((call) => call.method == 'setLanguage').last.arguments, 'en');
  });
}
