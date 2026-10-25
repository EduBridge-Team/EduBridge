import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../l10n/l10n.dart';

/// Owns the temporary search input and returns the user's selected query.
class SpecialistChildSearchDialog extends StatefulWidget {
  const SpecialistChildSearchDialog({super.key, required this.query});

  final String query;

  static Future<String?> show(BuildContext context, String query) =>
      showDialog<String>(
        context: context,
        builder: (_) => SpecialistChildSearchDialog(query: query),
      );

  @override
  State<SpecialistChildSearchDialog> createState() =>
      _SpecialistChildSearchDialogState();
}

class _SpecialistChildSearchDialogState
    extends State<SpecialistChildSearchDialog> {
  late final _controller = TextEditingController(text: widget.query);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.searchForChild),
    content: TextField(
      controller: _controller,
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.enterChildName,
        prefixIcon: const Icon(AppIcons.search),
      ),
      onSubmitted: (value) => Navigator.pop(context, value),
    ),
    actions: [
      if (widget.query.isNotEmpty)
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: Text(context.l10n.clearSearch),
        ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: Text(context.l10n.search),
      ),
    ],
  );
}
