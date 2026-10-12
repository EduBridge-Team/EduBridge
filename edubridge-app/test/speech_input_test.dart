import 'dart:async';
import 'package:edubridge_app/services/speech_input_service.dart';
import 'package:edubridge_app/widgets/accessibility/voice_draft_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class FakeResult implements SpeechRecognitionResult {
  @override
  final String recognizedWords;
  @override
  final bool finalResult;
  FakeResult(this.recognizedWords, {this.finalResult = true});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRecognizer implements SpeechRecognizer {
  int initializations = 0;
  int recordings = 0;
  int cancellations = 0;
  @override
  bool isListening = false;
  String? locale = 'ar-SA';
  void Function(String)? status;
  void Function(dynamic)? error;
  void Function(SpeechRecognitionResult)? result;
  Completer<void>? cancellation;
  @override
  Future<bool> initialize({required void Function(String) onStatus,
      required void Function(dynamic) onError}) async {
    initializations++;
    // Like the real plugin, keep the first initialization callbacks.
    status ??= onStatus;
    error ??= onError;
    return true;
  }
  @override
  Future<String?> arabicLocale() async => locale;
  @override
  Future<void> listen({required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult}) async {
    recordings++;
    result = onResult;
    isListening = true;
  }
  @override
  Future<void> stop() async {
    isListening = false;
    status?.call('done');
  }
  @override
  Future<void> cancel() async {
    cancellations++;
    if (cancellation != null) await cancellation!.future;
    isListening = false;
    status?.call('notListening');
  }
}

void main() {
  test('callbacks follow a new screen while initialization happens once', () async {
    final engine = FakeRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final first = Object(), second = Object();
    final events = <String>[];
    await service.initialize(owner: first, onStatus: (_) => events.add('first'), onError: (_) {});
    await service.cancel(first);
    await service.initialize(owner: second, onStatus: (_) => events.add('second'), onError: (_) {});
    engine.status!('done');
    expect(engine.initializations, 1);
    expect(events, ['second']);
  });

  test('a closing owner cannot cancel another recording or deliver stale text', () async {
    final engine = FakeRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final first = Object(), second = Object();
    var words = '';
    await service.initialize(owner: first, onStatus: (_) {}, onError: (_) {});
    await service.listen(owner: first, options: stt.SpeechListenOptions(), onResult: (r) => words = r.recognizedWords);
    final stale = engine.result!;
    expect(await service.initialize(owner: second, onStatus: (_) {}, onError: (_) {}), isFalse);
    await service.cancel(first);
    await service.initialize(owner: second, onStatus: (_) {}, onError: (_) {});
    await service.listen(owner: second, options: stt.SpeechListenOptions(), onResult: (r) => words = r.recognizedWords);
    await service.cancel(first);
    stale(FakeResult('قديم'));
    expect(words, isEmpty);
    expect(engine.isListening, isTrue);
    engine.result!(FakeResult('جديد'));
    expect(words, 'جديد');
  });

  test('new recording waits for pending cancellation', () async {
    final engine = FakeRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final first = Object(), second = Object();
    await service.initialize(owner: first, onStatus: (_) {}, onError: (_) {});
    engine.cancellation = Completer<void>();
    final closing = service.cancel(first);
    var ready = false;
    final opening = service.initialize(owner: second, onStatus: (_) {}, onError: (_) {}).then((value) => ready = value);
    await Future<void>.delayed(Duration.zero);
    expect(ready, isFalse);
    engine.cancellation!.complete();
    await closing;
    await opening;
    expect(ready, isTrue);
  });

  testWidgets('dictation can finish and start twice without duplicate text', (tester) async {
    final engine = FakeRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final controller = TextEditingController(text: 'إجابتي');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VoiceDraftButton(
      controller: controller, enabled: true, speechInput: service))));
    await tester.tap(find.text('أكتب بصوتي'));
    await tester.pump();
    engine.result!(FakeResult('الأولى'));
    engine.result!(FakeResult('الأولى'));
    await tester.pump();
    expect(controller.text, 'إجابتي الأولى');
    await tester.tap(find.text('أكتب بصوتي'));
    await tester.pump();
    engine.isListening = false;
    engine.status!('done');
    await tester.pump();
    expect(find.text('أكتب بصوتي'), findsOneWidget);
    engine.result!(FakeResult('الثانية'));
    await tester.pump();
    expect(controller.text, 'إجابتي الأولى الثانية');
    expect(engine.initializations, 1);
    expect(engine.recordings, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('disabling dictation ignores late results and cancels the mic', (tester) async {
    final engine = FakeRecognizer();
    final service = SpeechInputService.forTesting(engine);
    final controller = TextEditingController(text: 'إجابتي');
    Widget screen(bool enabled) => MaterialApp(home: Scaffold(body: VoiceDraftButton(
      controller: controller, enabled: enabled, speechInput: service)));
    await tester.pumpWidget(screen(true));
    await tester.tap(find.text('أكتب بصوتي'));
    await tester.pump();
    final stale = engine.result!;
    await tester.pumpWidget(screen(false));
    stale(FakeResult('متأخر'));
    await tester.pump();
    expect(controller.text, 'إجابتي');
    expect(engine.isListening, isFalse);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('missing Arabic speech keeps typing available', (tester) async {
    final engine = FakeRecognizer()..locale = null;
    final controller = TextEditingController(text: 'إجابتي');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: VoiceDraftButton(
      controller: controller, enabled: true, speechInput: SpeechInputService.forTesting(engine)))));
    await tester.tap(find.text('أكتب بصوتي'));
    await tester.pump();
    expect(engine.recordings, 0);
    expect(controller.text, 'إجابتي');
    expect(find.text('التعرف على الكلام العربي غير متاح على الجهاز.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
