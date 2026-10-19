// lib/screens/add_child/add_child_file_pickers.dart
part of 'add_child_screen.dart';

Widget buildDocumentsSection({
  required BuildContext context,
  required JisrColors c,
  required File? idCardFile,
  required File? birthCertFile,
  required List<File> medicalReportFiles,
  required VoidCallback onPickId,
  required VoidCallback onCaptureId,
  required VoidCallback onRemoveId,
  required VoidCallback onPickBirth,
  required VoidCallback onRemoveBirth,
  required VoidCallback onPickMedical,
  required VoidCallback onCaptureMedical,
  required void Function(int index) onRemoveMedical,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: AppColors.brandBlue.withValues(alpha: 0.4),
        width: 2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.attach,
                color: AppColors.brandBlue, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.officialDocuments,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.requiredBadge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildFilePicker(
          context: context,
          label: context.l10n.guardianNationalId,
          sublabel: context.l10n.guardianIdFrontDescription,
          icon: AppIcons.profile,
          file: idCardFile,
          onPick: onPickId,
          onCapture: onCaptureId,
          onRemove: onRemoveId,
          color: AppColors.brandTeal,
        ),
        const SizedBox(height: 12),
        _buildFilePicker(
          context: context,
          label: context.l10n.birthCertificate,
          sublabel: context.l10n.birthCertificateDescription,
          icon: AppIcons.certificate,
          file: birthCertFile,
          onPick: onPickBirth,
          onRemove: onRemoveBirth,
          color: AppColors.brandBlue,
        ),
        const SizedBox(height: 12),
        buildMedicalReportSection(
          context: context,
          c: c,
          files: medicalReportFiles,
          onPick: onPickMedical,
          onCapture: onCaptureMedical,
          onRemove: onRemoveMedical,
        ),
      ],
    ),
  );
}

Widget _buildFilePicker({
  required BuildContext context,
  required String label,
  required String sublabel,
  required IconData icon,
  required File? file,
  required VoidCallback onPick,
  VoidCallback? onCapture,
  required VoidCallback onRemove,
  required Color color,
}) {
  final c = JisrColors.of(context);
  final hasFile = file != null;

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: hasFile
          ? color.withValues(alpha: 0.08)
          : c.tintTeal.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: hasFile ? color : c.line,
        width: hasFile ? 2 : 1.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: c.heading,
                ),
              ),
            ),
            if (hasFile) Icon(AppIcons.check, color: c.success, size: 22),
          ],
        ),
        const SizedBox(height: 4),
        Text(sublabel, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 10),
        if (!hasFile)
          _DocumentActions(children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(AppIcons.upload, size: 18),
                label: Text(context.l10n.fromGallery,
                    style: TextStyle(fontSize: 13)),
                onPressed: onPick,
              ),
            ),
            if (onCapture != null) ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 42),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(AppIcons.camera, size: 18),
                label: Text(context.l10n.camera,
                    style: TextStyle(fontSize: 13)),
                onPressed: onCapture,
              ),
            ),
          ])
        else
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: c.line,
                    child: Icon(AppIcons.image, color: c.muted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.path.split('/').last,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.onTint,
                      ),
                    ),
                    Text(context.l10n.uploaded,
                        style: TextStyle(fontSize: 11, color: c.success)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.refresh, color: color, size: 20),
                tooltip: context.l10n.changeFile,
                onPressed: onPick,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(AppIcons.delete, color: AppColors.red, size: 20),
                tooltip: context.l10n.deleteConfirmationWord,
                onPressed: onRemove,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
      ],
    ),
  );
}


/// Stack document actions when large text or a narrow card needs more room.
class _DocumentActions extends StatelessWidget {
  const _DocumentActions({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final stack = constraints.maxWidth < 220 ||
        MediaQuery.textScalerOf(context).scale(13) > 18;
    if (stack) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
      ]);
    }
    return Row(children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: children[i]),
      ],
    ]);
  });
}
