import 'package:flutter/material.dart';

/// Completes only the word at the caret and preserves surrounding text.
TextEditingValue completeWord(TextEditingValue value, String suggestion) {
  final caret = value.selection.isValid ? value.selection.extentOffset.clamp(0, value.text.length) : value.text.length;
  var start = caret;
  var end = caret;
  while (start > 0 && !RegExp(r'\s').hasMatch(value.text[start - 1])) { start--; }
  while (end < value.text.length && !RegExp(r'\s').hasMatch(value.text[end])) { end++; }
  final text = value.text.replaceRange(start, end, suggestion);
  return TextEditingValue(text: text,
      selection: TextSelection.collapsed(offset: start + suggestion.length));
}

class WordPredictionBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final List<String> words;
  const WordPredictionBar({super.key, required this.controller,
    required this.enabled, this.words = const ['أريد', 'أحتاج', 'مساعدة', 'شكراً', 'نعم', 'لا']});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controller,
    builder: (context, value, _) {
      if (!enabled || !value.composing.isCollapsed ||
          (value.selection.isValid && !value.selection.isCollapsed)) return const SizedBox.shrink();
      final caret = value.selection.isValid ? value.selection.extentOffset.clamp(0, value.text.length) : value.text.length;
      final prefix = value.text.substring(0, caret).split(RegExp(r'\s')).last;
      if (prefix.isEmpty) return const SizedBox.shrink();
      final matches = words.where((word) => word.startsWith(prefix) && word != prefix).toSet().take(3);
      return Wrap(spacing: 8, children: [for (final word in matches)
        ActionChip(materialTapTargetSize: MaterialTapTargetSize.padded, label: Text(word), tooltip: 'إكمال الكلمة: $word',
          onPressed: () => controller.value = completeWord(controller.value, word))]);
    },
  );
}
