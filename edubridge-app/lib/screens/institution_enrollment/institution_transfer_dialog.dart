import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/institutions/institution_enrollment_history.dart';

class InstitutionTransferDialog extends StatefulWidget {
  const InstitutionTransferDialog({super.key, required this.data, required this.record});
  final InstitutionEnrollmentHistory data;
  final InstitutionEnrollmentRecord record;
  @override
  State<InstitutionTransferDialog> createState() => _InstitutionTransferDialogState();
}

class _InstitutionTransferDialogState extends State<InstitutionTransferDialog> {
  int? _target;
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.institutionTransferTitle),
      scrollable: true,
      content: SizedBox(width: 440, child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.record.childName),
          Text(widget.data.sectionLabel(widget.record.sectionId)),
          Text(l.institutionTransferNotice),
          const SizedBox(height: 12),
          Text(l.institutionTransferDestination),
          for (final section in widget.data.transferTargets(widget.record.id))
            Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: OutlinedButton(
              key: ValueKey('transfer-target-${section.id}'),
              onPressed: () => setState(() => _target = section.id),
              child: Row(children: [
                Icon(_target == section.id ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.data.sectionLabel(section.id))),
              ]),
            )),
        ],
      )),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(key: const ValueKey('confirm-institution-transfer'),
          onPressed: _target == null ? null : () => Navigator.pop(context, _target),
          child: Text(l.institutionTransferConfirm)),
      ],
    );
  }
}
