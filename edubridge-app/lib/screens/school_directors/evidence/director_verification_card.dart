import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../model/schools/director_evidence.dart';
import 'director_evidence_controller.dart';
import 'director_evidence_labels.dart';

class DirectorVerificationCard extends StatefulWidget {
  const DirectorVerificationCard({super.key, required this.controller});
  final DirectorEvidenceController controller;
  @override
  State<DirectorVerificationCard> createState() =>
      _DirectorVerificationCardState();
}

class _DirectorVerificationCardState extends State<DirectorVerificationCard> {
  int? _selected;

  Future<void> _submit() async {
    final controller = widget.controller;
    final evidence = controller.evidence;
    final selected = _selected;
    if (selected == null || !widget.controller.canWrite) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.directorVerificationSubmit),
        content: SingleChildScrollView(
          child: Text(context.l10n.directorVerificationConfirm),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.directorCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.directorConfirm),
          ),
        ],
      ),
    );
    if (confirm == true &&
        mounted &&
        identical(controller, widget.controller) &&
        identical(controller.evidence, evidence) &&
        controller.canWrite) {
      await controller.submit(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final evidence = widget.controller.evidence!;
    final verification = evidence.verification;
    final documents = evidence.documents
        .where((d) => d.kind == DirectorDocumentKind.identity)
        .toList();
    if (!documents.any((d) => d.id == _selected)) _selected = null;
    final canSubmit =
        widget.controller.canWrite &&
        _selected != null &&
        verification.status != DirectorVerificationStatus.pending &&
        !(verification.status == DirectorVerificationStatus.approved &&
            verification.identityDocumentId == _selected);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.directorVerificationTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                directorVerificationLabel(l10n, verification.status),
                key: const ValueKey('director-verification-status'),
              ),
            ),
            if (verification.reason != null)
              Text(
                '${l10n.directorVerificationReason}: ${verification.reason}',
              ),
            const SizedBox(height: 12),
            if (documents.isEmpty)
              Text(l10n.directorVerificationMissing)
            else
              DropdownButtonFormField<int>(
                key: ValueKey('director-identity-${_selected ?? 0}'),
                initialValue: _selected,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.directorVerificationChoose,
                ),
                items: [
                  for (final document in documents)
                    DropdownMenuItem(
                      value: document.id,
                      child: Text(
                        document.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged:
                    widget.controller.canWrite &&
                        verification.status !=
                            DirectorVerificationStatus.pending
                    ? (value) {
                        if (widget.controller.canWrite &&
                            identical(widget.controller.evidence, evidence)) {
                          setState(() => _selected = value);
                        }
                      }
                    : null,
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('director-verification-submit'),
              onPressed: canSubmit ? _submit : null,
              child: Text(l10n.directorVerificationSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
