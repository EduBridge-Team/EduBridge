// lib/widgets/adaptive/adaptive_text_field.dart
// حقل نصي مع إدخال صوتي واقتراح كلمات
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';

class AdaptiveTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final IconData? prefixIcon;
  final List<String> suggestions;   // كلمات مقترحة
  final bool enableVoice;
  final bool enablePrediction;
  final String? Function(String?)? validator;

  const AdaptiveTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.prefixIcon,
    this.suggestions = const [],
    this.enableVoice = true,
    this.enablePrediction = true,
    this.validator,
  });

  @override
  State<AdaptiveTextField> createState() => _AdaptiveTextFieldState();
}

class _AdaptiveTextFieldState extends State<AdaptiveTextField> {
  final _speech = stt.SpeechToText();
  bool _isListening = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.enablePrediction) return;
    final text = widget.controller.text.trim();
    if (text.isEmpty) {
      setState(() => _filteredSuggestions = []);
      return;
    }
    final lastWord = text.split(' ').last.toLowerCase();
    final matching = widget.suggestions
        .where((s) => s.toLowerCase().startsWith(lastWord))
        .take(4)
        .toList();
    setState(() => _filteredSuggestions = matching);
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الميكروفون غير متاح')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    AdaptiveHelper.hapticFeedback();

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(localeId: 'ar-SA'),
      onResult: (result) {
        if (result.finalResult) {
          final newText = widget.controller.text.isEmpty
              ? result.recognizedWords
              : '${widget.controller.text} ${result.recognizedWords}';
          widget.controller.text = newText;
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: newText.length),
          );
          setState(() => _isListening = false);
        }
      },
    );
  }

  void _applySuggestion(String suggestion) {
    final text = widget.controller.text;
    final words = text.split(' ');
    if (words.isNotEmpty) {
      words[words.length - 1] = suggestion;
    }
    widget.controller.text = words.join(' ');
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
    setState(() => _filteredSuggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityProfile>(
      valueListenable: AccessibilityService.instance.profile,
      builder: (context, profile, _) {
        final showVoice = widget.enableVoice &&
            (profile.voiceToText || profile.type == DisabilityType.motorDisability);
        final showPrediction = widget.enablePrediction &&
            (profile.wordPrediction ||
                profile.shortSentences ||
                profile.type == DisabilityType.stuttering);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: widget.controller,
              maxLines: widget.maxLines,
              validator: widget.validator,
              style: TextStyle(fontSize: AdaptiveHelper.bodyFontSize),
              decoration: InputDecoration(
                labelText: widget.labelText,
                hintText: widget.hintText,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon)
                    : null,
                suffixIcon: showVoice
                    ? IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : null,
                        ),
                        onPressed: _startVoiceInput,
                        tooltip: 'إدخال صوتي',
                      )
                    : null,
              ),
            ),

            // ✅ اقتراحات الكلمات
            if (showPrediction && _filteredSuggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filteredSuggestions.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: const Icon(Icons.auto_awesome, size: 18),
                        label: Text(
                          s,
                          style:
                              TextStyle(fontSize: AdaptiveHelper.bodyFontSize - 2),
                        ),
                        onPressed: () => _applySuggestion(s),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}