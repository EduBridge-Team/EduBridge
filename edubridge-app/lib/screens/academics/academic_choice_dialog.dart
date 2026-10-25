import 'package:flutter/material.dart';

/// Scrollable choices preserve long authored names at large text scales.
Future<int?> showAcademicChoiceDialog(
  BuildContext context, {
  required String label,
  required Map<int, String> options,
  required int? value,
}) => showDialog<int>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(label),
    children: [
      for (final entry in options.entries)
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, entry.key),
          child: Row(
            children: [
              Expanded(child: Text(entry.value)),
              if (entry.key == value) const Icon(Icons.check),
            ],
          ),
        ),
    ],
  ),
);
