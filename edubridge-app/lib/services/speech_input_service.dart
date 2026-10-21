import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// One recognizer for the app. Its initialization callbacks never capture a
/// screen or recording session, because the plugin retains the first callbacks.
class SpeechInputService {
  SpeechInputService._() : _speech = _PluginSpeechRecognizer();
  SpeechInputService.forTesting(SpeechRecognizer recognizer) : _speech = recognizer;
  static final instance = SpeechInputService._();
  final SpeechRecognizer _speech;
  Future<void>? _cancellation;
  int _recording = 0;
  Object? _owner;
  void Function(String)? _onStatus;
  void Function(dynamic)? _onError;
  Future<bool>? _initialization;

  Future<bool> initialize({required Object owner,
      required void Function(String) onStatus,
      required void Function(dynamic) onError}) async {
    if (_cancellation != null) await _cancellation;
    if (_owner != null && !identical(_owner, owner)) {
      if (_speech.isListening) return false;
      _onStatus?.call('notListening');
      await cancel(_owner!);
    }
    _owner = owner;
    _onStatus = onStatus;
    _onError = onError;
    final available = await (_initialization ??= _initialize());
    return available && identical(_owner, owner);
  }

  Future<bool> _initialize() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) => _onStatus?.call(status),
        onError: (error) => _onError?.call(error),
      );
      if (!available) _initialization = null;
      return available;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  Future<String?> arabicLocale(Object owner) async {
    if (!identical(_owner, owner)) return null;
    final locale = await _speech.arabicLocale();
    return identical(_owner, owner) ? locale : null;
  }

  Future<String?> localeForLanguage(Object owner, String language) async {
    if (!identical(_owner, owner)) return null;
    final engine = _speech;
    final locale = engine is LanguageSpeechRecognizer
        ? await (engine as LanguageSpeechRecognizer).localeForLanguage(language)
        : language.startsWith('ar') ? await engine.arabicLocale() : null;
    return identical(_owner, owner) ? locale : null;
  }

  Future<void> listen({required Object owner,
      required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult}) async {
    if (!identical(_owner, owner)) return;
    final recording = ++_recording;
    await _speech.listen(options: options, onResult: (result) {
      if (identical(_owner, owner) && recording == _recording) onResult(result);
    });
  }

  Future<void> stop(Object owner) async {
    if (identical(_owner, owner)) await _speech.stop();
  }

  Future<void> cancel(Object owner) async {
    if (!identical(_owner, owner)) return;
    if (_cancellation != null) { await _cancellation; return; }
    _recording++;
    _onStatus = null;
    _onError = null;
    _cancellation = _cancel(owner);
    await _cancellation;
    _cancellation = null;
  }

  Future<void> _cancel(Object owner) async {
    try {
      // Permission/initialization may still be pending when a sheet is closed.
      // Cancel after it completes, before allowing the next owner to start.
      if (_initialization != null) await _initialization;
      await _speech.cancel();
    } catch (_) {}
    if (identical(_owner, owner)) _owner = null;
  }
}

abstract class SpeechRecognizer {
  bool get isListening;
  Future<bool> initialize({required void Function(String) onStatus,
      required void Function(dynamic) onError});
  Future<String?> arabicLocale();
  Future<void> listen({required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult});
  Future<void> stop();
  Future<void> cancel();
}

abstract class LanguageSpeechRecognizer {
  Future<String?> localeForLanguage(String language);
}

class _PluginSpeechRecognizer implements SpeechRecognizer, LanguageSpeechRecognizer {
  final _speech = stt.SpeechToText();
  @override
  bool get isListening => _speech.isListening;
  @override
  Future<bool> initialize({required void Function(String) onStatus,
      required void Function(dynamic) onError}) =>
      _speech.initialize(onStatus: onStatus, onError: onError);
  @override
  Future<String?> arabicLocale() => localeForLanguage('ar');
  @override
  Future<String?> localeForLanguage(String language) async {
    final code = language.toLowerCase().split(RegExp('[-_]')).first;
    for (final locale in await _speech.locales()) {
      if (locale.localeId.toLowerCase().split(RegExp('[-_]')).first == code) return locale.localeId;
    }
    return null;
  }
  @override
  Future<void> listen({required stt.SpeechListenOptions options,
      required void Function(SpeechRecognitionResult) onResult}) =>
      _speech.listen(listenOptions: options, onResult: onResult);
  @override
  Future<void> stop() => _speech.stop();
  @override
  Future<void> cancel() => _speech.cancel();
}
