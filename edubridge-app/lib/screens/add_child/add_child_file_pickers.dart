// lib/screens/add_child/add_child_file_pickers.dart
part of 'add_child_screen.dart';

Widget buildDocumentsSection({
  required BuildContext context,
  required JisrColors c,
  required File? idCardFile,
  required File? birthCertFile,
  required VoidCallback onPickId,
  required VoidCallback onCaptureId,
  required VoidCallback onRemoveId,
  required VoidCallback onPickBirth,
  required VoidCallback onRemoveBirth,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
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
            Text(
              'المستندات الرسمية',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'مطلوب',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildFilePicker(
          context: context,
          label: 'هوية ولي الأمر',
          sublabel: 'صورة واضحة للوجه الأمامي للهوية',
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
          label: 'شهادة الميلاد',
          sublabel: 'صورة واضحة للشهادة كاملة',
          icon: AppIcons.certificate,
          file: birthCertFile,
          onPick: onPickBirth,
          onRemove: onRemoveBirth,
          color: AppColors.brandBlue,
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
      borderRadius: BorderRadius.circular(14),
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
                  fontWeight: FontWeight.bold,
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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(AppIcons.upload, size: 18),
                    label: const Text('من المعرض',
                        style: TextStyle(fontSize: 13)),
                    onPressed: onPick,
                  ),
                ),
              ),
              if (onCapture != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 42,
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
                      label: const Text('الكاميرا',
                          style: TextStyle(fontSize: 13)),
                      onPressed: onCapture,
                    ),
                  ),
                ),
              ],
            ],
          )
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
                    Text('تم الرفع',
                        style: TextStyle(fontSize: 11, color: c.success)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.refresh, color: color, size: 20),
                tooltip: 'تغيير',
                onPressed: onPick,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(AppIcons.delete, color: AppColors.red, size: 20),
                tooltip: 'حذف',
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