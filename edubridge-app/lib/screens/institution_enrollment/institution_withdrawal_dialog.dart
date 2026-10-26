import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_enrollment_history.dart';

class InstitutionWithdrawalDialog extends StatelessWidget {
  const InstitutionWithdrawalDialog({super.key, required this.data, required this.record});
  final InstitutionEnrollmentHistory data;
  final InstitutionEnrollmentRecord record;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.institutionWithdrawalTitle),
      scrollable: true,
      content: SizedBox(width: 440, child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(record.childName),
          Text(data.sectionLabel(record.sectionId)),
          const SizedBox(height: 12),
          Text(l.institutionWithdrawalNotice),
        ],
      )),
      actions: [
        TextButton(key: const ValueKey('cancel-institution-withdrawal'),
          onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(key: const ValueKey('confirm-institution-withdrawal'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.institutionWithdrawalConfirm)),
      ],
    );
  }
}
