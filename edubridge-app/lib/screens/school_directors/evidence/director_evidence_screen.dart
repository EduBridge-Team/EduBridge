import 'package:flutter/material.dart';

import '../../../theme.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import '../../../model/schools/director_evidence.dart';
import '../../../model/schools/school_director.dart';
import '../../../services/schools/director_evidence_picker.dart';
import '../../../services/schools/director_evidence_repository.dart';
import '../director_failure_message.dart';
import 'director_evidence_controller.dart';
import 'director_evidence_labels.dart';
import 'director_verification_card.dart';

class DirectorEvidenceScreen extends StatefulWidget {
  const DirectorEvidenceScreen({
    super.key,
    required this.school,
    required this.director,
    this.gateway,
    this.picker,
    this.openLink,
  });
  final DirectorSchool school;
  final SchoolDirector director;
  final DirectorEvidenceGateway? gateway;
  final DirectorEvidencePick? picker;
  final Future<bool> Function(Uri)? openLink;
  @override
  State<DirectorEvidenceScreen> createState() => _DirectorEvidenceScreenState();
}

class _DirectorEvidenceScreenState extends State<DirectorEvidenceScreen> {
  late DirectorEvidenceController _controller;
  DirectorDocumentKind _kind = DirectorDocumentKind.identity;

  @override
  void initState() {
    super.initState();
    _loadController();
  }

  void _loadController() {
    _controller = DirectorEvidenceController(
      widget.gateway ??
          DirectorEvidenceRepository(
            school: widget.school,
            directorId: widget.director.id,
          ),
    )..reload();
  }

  @override
  void didUpdateWidget(covariant DirectorEvidenceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.gateway != oldWidget.gateway ||
        widget.school.id != oldWidget.school.id ||
        widget.school.organizationId != oldWidget.school.organizationId ||
        widget.school.organizationSlug != oldWidget.school.organizationSlug ||
        widget.director.id != oldWidget.director.id) {
      _controller.dispose();
      _kind = DirectorDocumentKind.identity;
      _loadController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _remove(DirectorDocument document) async {
    final controller = _controller;
    final evidence = controller.evidence;
    if (!controller.canWrite) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.directorDocumentRemove),
        content: SingleChildScrollView(
          child: Text(context.l10n.directorDocumentRemoveConfirm),
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
        identical(controller, _controller) &&
        identical(controller.evidence, evidence) &&
        controller.canWrite) {
      await controller.remove(document);
    }
  }

  Future<bool> _launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      final l10n = context.l10n;
      final evidence = _controller.evidence;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(l10n.directorEvidenceTitle),
          actions: [
            IconButton(
              tooltip: l10n.directorReload,
              onPressed: _controller.loading || _controller.busy
                  ? null
                  : _controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.director.details.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(widget.school.name),
              Text(l10n.directorEvidenceHint),
              const SizedBox(height: 16),
              if (_controller.loading || _controller.busy)
                const LinearProgressIndicator(),
              if (_controller.saved)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l10n.directorSaved,
                    key: const ValueKey('director-evidence-saved'),
                  ),
                ),
              if (_controller.error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    directorFailureMessage(l10n, _controller.error!),
                    key: const ValueKey('director-evidence-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (evidence != null) ...[
                DropdownButtonFormField<DirectorDocumentKind>(
                  key: ValueKey(('director-document-kind', _controller)),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.directorDocumentKind,
                  ),
                  items: [
                    for (final kind in DirectorDocumentKind.values)
                      DropdownMenuItem(
                        value: kind,
                        child: Text(directorDocumentLabel(l10n, kind)),
                      ),
                  ],
                  onChanged: _controller.canWrite
                      ? (kind) {
                          if (kind != null &&
                              _controller.canWrite &&
                              identical(_controller.evidence, evidence)) {
                            setState(() => _kind = kind);
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 8),
                Text(l10n.directorDocumentLimits),
                FilledButton.icon(
                  key: const ValueKey('director-document-upload'),
                  onPressed: _controller.canWrite
                      ? () => _controller.pickAndUpload(
                          _kind,
                          widget.picker ?? pickDirectorEvidence,
                        )
                      : null,
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.directorDocumentUpload),
                ),
                const SizedBox(height: 16),
                DirectorVerificationCard(
                  key: ObjectKey(_controller),
                  controller: _controller,
                ),
                if (evidence.documents.isEmpty)
                  Text(l10n.directorDocumentEmpty),
                for (final document in evidence.documents)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(document.fileName),
                          Text(directorDocumentLabel(l10n, document.kind)),
                          Text('${(document.sizeBytes / 1024).ceil()} KB'),
                          Wrap(
                            spacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: _controller.canWrite
                                    ? () => _controller.open(
                                        document,
                                        widget.openLink ?? _launch,
                                      )
                                    : null,
                                icon: const Icon(Icons.open_in_new),
                                label: Text(l10n.directorDocumentOpen),
                              ),
                              TextButton.icon(
                                key: ValueKey(
                                  'director-document-remove-${document.id}',
                                ),
                                onPressed:
                                    _controller.canWrite &&
                                        evidence.canRemove(document)
                                    ? () => _remove(document)
                                    : null,
                                icon: const Icon(Icons.delete_outline),
                                label: Text(l10n.directorDocumentRemove),
                              ),
                            ],
                          ),
                          if (!evidence.canRemove(document))
                            Text(l10n.directorDocumentProtected),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
