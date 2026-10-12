import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Dictation requires an explicit tap; it only edits the draft.
class VoiceDraftButton extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  const VoiceDraftButton({super.key, required this.controller, required this.enabled});
  @override
  State<VoiceDraftButton> createState() => _VoiceDraftButtonState();
}

class _VoiceDraftButtonState extends State<VoiceDraftButton> with WidgetsBindingObserver {
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _starting = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancel() {
    _generation++;
    _speech.cancel();
    if (mounted) setState(() { _listening = false; _starting = false; });
  }

  @override
  void didUpdateWidget(covariant VoiceDraftButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) _cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _speech.cancel();
    super.dispose();
  }

  void _error(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle() async {
    if (!widget.enabled || _starting) return;
    if (_listening) { await _speech.stop(); return; }
    final generation = ++_generation;
    setState(() => _starting = true);
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (mounted && generation == _generation && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted && generation == _generation) {
            setState(() => _listening = false);
            _error('تعذّر سماع الصوت. يمكنك كتابة الإجابة.');
          }
        },
      );
      if (!mounted || generation != _generation || !widget.enabled) return;
      if (!available) { _error('الميكروفون غير متاح. يمكنك كتابة الإجابة.'); return; }
      final locales = await _speech.locales();
      if (!mounted || generation != _generation || !widget.enabled) return;
      final arabic = locales.where((locale) => locale.localeId.toLowerCase().startsWith('ar')).toList();
      if (arabic.isEmpty) { _error('التعرف على الكلام العربي غير متاح على الجهاز.'); return; }
      setState(() => _listening = true);
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(localeId: arabic.first.localeId,
          partialResults: false, listenFor: const Duration(seconds: 30)),
        onResult: (result) {
          if (!mounted || generation != _generation || !widget.enabled || !result.finalResult) return;
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;
          final current = widget.controller.text.trimRight();
          final text = current.isEmpty ? words : '$current $words';
          widget.controller.value = TextEditingValue(text: text,
            selection: TextSelection.collapsed(offset: text.length));
        },
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _listening = false);
        _error('تعذّر تشغيل الميكروفون. يمكنك كتابة الإجابة.');
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: widget.enabled && !_starting ? _toggle : null,
    icon: Icon(_listening ? Icons.stop : Icons.mic_none),
    label: Text(_starting ? 'جارٍ تشغيل الميكروفون' : _listening ? 'أوقف التسجيل' : 'أكتب بصوتي'),
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
  );
}
