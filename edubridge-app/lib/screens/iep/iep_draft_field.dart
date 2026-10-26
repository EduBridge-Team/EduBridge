import 'package:flutter/material.dart';

/// A wrapping, content-sized form control shared by draft authoring pages.
class IepDraftField extends StatelessWidget {
  const IepDraftField({
    super.key,
    required this.name,
    required this.label,
    required this.values,
    required this.onChanged,
    this.validator,
    this.multiline = false,
    this.numeric = false,
    this.hint,
  });
  final String name, label;
  final Map<String, String> values;
  final VoidCallback onChanged;
  final String? Function(String?)? validator;
  final bool multiline, numeric;
  final String? hint;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey('iep-input-$name'),
      initialValue: values[name] ?? '',
      decoration: InputDecoration(
        label: Text(label),
        hintText: hint,
        border: const OutlineInputBorder(),
        errorMaxLines: 5,
      ),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : multiline
          ? TextInputType.multiline
          : TextInputType.text,
      minLines: multiline ? 2 : 1,
      maxLines: multiline ? null : 1,
      validator: validator,
      onChanged: (value) {
        values[name] = value;
        onChanged();
      },
    ),
  );
}

Future<bool> confirmIepDiscard(
  BuildContext context,
  String message,
  String discard,
  String cancel,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancel),
          ),
          TextButton(
            key: const ValueKey('iep-discard-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(discard),
          ),
        ],
      ),
    ) ??
    false;
