import 'package:flutter/material.dart';

import '../../app_icons.dart';
import '../../l10n/l10n.dart';
import '../../theme.dart';
import '../../utils/safe_bottom.dart';

class CertificateSubmissionForm extends StatelessWidget {
  const CertificateSubmissionForm({
    super.key,
    required this.titleController,
    required this.fileName,
    required this.saving,
    required this.error,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onSave,
  });

  final TextEditingController titleController;
  final String? fileName;
  final bool saving;
  final Object? error;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final bottom = safeModalBottom(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 60, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    AppIcons.certificate,
                    color: AppColors.orange,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.addQualificationCertificate,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.certificateUploadDescription,
                style: TextStyle(fontSize: 13, height: 1.5, color: c.muted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: context.l10n.certificateTitle,
                  hintText: context.l10n.certificateTitleExample,
                  prefixIcon: Icon(AppIcons.edit),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          AppIcons.attach,
                          size: 20,
                          color: AppColors.greenDeep,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.l10n.certificateFileLabel,
                            softWrap: true,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              height: 1.35,
                              color: c.onTint,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (fileName == null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: double.infinity,
                          minHeight: 50,
                        ),
                        child: FilledButton.icon(
                          icon: const Icon(AppIcons.upload),
                          label: Text(
                            context.l10n.chooseImageOrPdf,
                            textAlign: TextAlign.center,
                          ),
                          onPressed: onPickFile,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.green,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(AppIcons.check, color: c.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onTint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(AppIcons.close, color: c.onTint),
                            onPressed: onRemoveFile,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.error,
                        color: AppColors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.sharedMessage(error),
                          style: const TextStyle(color: AppColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                      ),
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(AppIcons.save),
                      onPressed: saving ? null : onSave,
                      label: Text(
                        saving
                            ? context.l10n.saving
                            : context.l10n.submitForReview,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
