import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/enrollment/enrollment_models.dart';

class SchoolEnrollmentDecisionDialog extends StatefulWidget {
  const SchoolEnrollmentDecisionDialog({
    super.key,
    required this.approve,
    required this.request,
    required this.sections,
  });
  final bool approve;
  final EnrollmentRequest request;
  final List<EnrollmentSection> sections;
  @override
  State<SchoolEnrollmentDecisionDialog> createState() =>
      _SchoolEnrollmentDecisionDialogState();
}

class _SchoolEnrollmentDecisionDialogState
    extends State<SchoolEnrollmentDecisionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  int? _sectionId;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approve
          ? context.l10n.enrollmentApprove
          : context.l10n.enrollmentReject,
    ),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.request.childName),
            if (widget.approve)
              DropdownButtonFormField<int>(
                key: const ValueKey('enrollment-section'),
                isExpanded: true,
                itemHeight: null,
                decoration: InputDecoration(
                  labelText: context.l10n.enrollmentSection,
                ),
                items: [
                  for (final section in widget.sections)
                    DropdownMenuItem(
                      value: section.id,
                      child: Text(
                        section.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => _sectionId = value,
                validator: (value) => value == null
                    ? context.l10n.enrollmentSectionRequired
                    : null,
              ),
            TextFormField(
              key: const ValueKey('enrollment-reason'),
              controller: _reason,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.enrollmentReason,
              ),
              validator: (value) =>
                  !widget.approve && (value ?? '').trim().isEmpty
                  ? context.l10n.enrollmentReasonRequired
                  : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.l10n.enrollmentCancelAction),
      ),
      FilledButton(
        key: const ValueKey('enrollment-decision-confirm'),
        onPressed: () {
          if (_form.currentState!.validate())
            Navigator.pop(
              context,
              EnrollmentDecision(
                approve: widget.approve,
                sectionId: _sectionId,
                reason: _reason.text.trim(),
              ),
            );
        },
        child: Text(context.l10n.enrollmentConfirm),
      ),
    ],
  );
}
