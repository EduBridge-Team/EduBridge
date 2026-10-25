import 'package:flutter/material.dart';

import 'academic_choice_dialog.dart';

class AcademicChoiceField extends StatelessWidget {
  const AcademicChoiceField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.requiredMessage,
    required this.onChanged,
  });

  final String label, requiredMessage;
  final Map<int, String> options;
  final int? value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) => FormField<int>(
    key: ValueKey(value),
    initialValue: value,
    validator: (value) => options.containsKey(value) ? null : requiredMessage,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onChanged == null || options.isEmpty
              ? null
              : () async {
                  final selected = await showAcademicChoiceDialog(
                    context,
                    label: label,
                    options: options,
                    value: value,
                  );
                  if (context.mounted && selected != null)
                    onChanged?.call(selected);
                },
          icon: const Icon(Icons.expand_more),
          label: Text('$label: ${options[value] ?? '—'}'),
        ),
        if (field.errorText != null)
          Semantics(
            liveRegion: true,
            child: Text(
              field.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
}
