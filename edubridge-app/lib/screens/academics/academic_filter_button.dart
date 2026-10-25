import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'academic_choice_dialog.dart';

/// A wrapping label and scrollable choice dialog for long school-authored names.
class AcademicFilterButton extends StatelessWidget {
  const AcademicFilterButton({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Map<int, String> options;
  final int? value;
  final ValueChanged<int?>? onChanged;

  Future<void> _choose(BuildContext context) async {
    final result = await showAcademicChoiceDialog(
      context,
      label: label,
      options: {0: context.l10n.all, ...options},
      value: value ?? 0,
    );
    if (context.mounted && result != null) {
      onChanged?.call(result == 0 ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onChanged == null ? null : () => _choose(context),
    icon: const Icon(Icons.filter_list),
    label: Text('$label: ${options[value] ?? context.l10n.all}'),
  );
}
