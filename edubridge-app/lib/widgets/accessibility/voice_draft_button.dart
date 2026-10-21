import '../../l10n/l10n.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/speech_input_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Dictation requires an explicit tap; it only edits the draft.
class VoiceDraftButton extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final SpeechInputService? speechInput;
  const VoiceDraftButton({super.key, required this.controller, required this.enabled, this.speechInput});
  @override
  State<VoiceDraftButton> createState() => _VoiceDraftButtonState();
}

class _VoiceDraftButtonState extends State<VoiceDraftButton> with WidgetsBindingObserver {
  late final _speech = widget.speechInput ?? SpeechInputService.instance;
  final _owner = Object();
  bool _listening = false;
  bool _starting = false;
  int _generation = 0;
  String? _language;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.l10n.localeName;
    if (_language != null && _language != language) _cancel();
    _language = language;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _cancel() {
    _generation++;
    unawaited(_speech.cancel(_owner));
    if (mounted) setState(() { _listening = false; _starting = false; });
  }

  @override
  void didUpdateWidget(covariant VoiceDraftButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((!widget.enabled && oldWidget.enabled) ||
        !identical(widget.controller, oldWidget.controller)) {
      _cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _cancel();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_speech.cancel(_owner));
    super.dispose();
  }

  void _error(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle() async {
    if (!widget.enabled || _starting) return;
    if (_listening) {
      try { await _speech.stop(_owner); }
      catch (_) { _cancel(); _error(context.l10n.dictationStopFailed); }
      if (mounted) setState(() => _listening = false);
      return;
    }
    final generation = ++_generation;
    setState(() => _starting = true);
    var recordingRequested = false;
    try {
      final available = await _speech.initialize(
        owner: _owner,
        onStatus: (status) {
          if (mounted && widget.enabled && (status == 'done' || status == 'notListening')) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted && widget.enabled && (_starting || _listening)) {
            setState(() { _listening = false; _starting = false; });
            _generation++;
            unawaited(_speech.cancel(_owner));
            _error(context.l10n.dictationHearFailed);
          }
        },
      );
      if (!mounted || generation != _generation || !widget.enabled) return;
      if (!available) { _error(context.l10n.dictationUnavailable); return; }
      final language = context.l10n.localeName;
      final locale = await _speech.localeForLanguage(_owner, language);
      if (!mounted || generation != _generation || !widget.enabled) return;
      if (locale == null) { _error(context.l10n.dictationLocaleUnavailable); return; }
      setState(() => _listening = true);
      recordingRequested = true;
      await _speech.listen(
        owner: _owner,
        options: stt.SpeechListenOptions(localeId: locale,
          partialResults: false, listenFor: const Duration(seconds: 30)),
        onResult: (result) {
          if (!mounted || generation != _generation || !widget.enabled || !result.finalResult) return;
          setState(() { _listening = false; _starting = false; });
          _generation++;
          unawaited(_speech.cancel(_owner));
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
        unawaited(_speech.cancel(_owner));
        _error(context.l10n.dictationStartFailed);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _starting = false);
        if (!recordingRequested) unawaited(_speech.cancel(_owner));
      }
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: widget.enabled && !_starting ? _toggle : null,
    icon: Icon(_listening ? Icons.stop : Icons.mic_none),
    label: Text(_starting ? context.l10n.dictationStarting : _listening ? context.l10n.dictationStop : context.l10n.dictationWrite),
    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 52)),
  );
}
