import 'package:flutter/material.dart';
import '../../services/accessibility_service.dart';
import '../../utils/adaptive_helper.dart';
import 'voice_draft_button.dart';
import 'word_prediction_bar.dart';

/// Uses the same dictation and caret-aware completion as homework answers.
class AdaptiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final IconData? prefixIcon;
  final List<String> suggestions;
  final bool enableVoice;
  final bool enablePrediction;
  final String? Function(String?)? validator;

  const AdaptiveTextField({super.key, required this.controller, this.labelText,
    this.hintText, this.maxLines = 1, this.prefixIcon,
    this.suggestions = const [], this.enableVoice = true,
    this.enablePrediction = true, this.validator});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AccessibilityProfile>(
    valueListenable: AccessibilityService.instance.profile,
    builder: (context, profile, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(controller: controller, maxLines: maxLines,
          validator: validator,
          style: TextStyle(fontSize: AdaptiveHelper.bodyFontSize),
          decoration: InputDecoration(labelText: labelText, hintText: hintText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon))),
        WordPredictionBar(controller: controller, words: suggestions,
          enabled: enablePrediction && profile.wordPrediction),
        if (enableVoice && profile.voiceToText) ...[
          const SizedBox(height: 8),
          VoiceDraftButton(controller: controller, enabled: true),
        ],
      ],
    ),
  );
}
