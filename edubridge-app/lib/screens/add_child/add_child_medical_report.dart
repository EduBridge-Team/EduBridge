// lib/screens/add_child/add_child_medical_report.dart
part of 'add_child_screen.dart';

Widget buildMedicalReportSection({
  required BuildContext context,
  required JisrColors c,
  required List<File> files,
  required VoidCallback onPick,
  required VoidCallback onCapture,
  required void Function(int index) onRemove,
}) {
  final hasFiles = files.isNotEmpty;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: AppColors.brandTeal.withValues(alpha: 0.4),
        width: 2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.certificate,
                color: AppColors.brandTeal, size: 26),
            const SizedBox(width: 8),
            Text(
              'التقرير الطبي',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'مطلوب',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'ارفع صورة أو أكثر للتقرير الطبي الخاص بالطفل',
          style: TextStyle(fontSize: 12, color: c.muted),
        ),
        const SizedBox(height: 14),
        if (hasFiles) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < files.length; i++)
                _buildMedicalThumb(
                  context: context,
                  c: c,
                  file: files[i],
                  onRemove: () => onRemove(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(AppIcons.upload, size: 18),
                  label: Text(
                    hasFiles ? 'إضافة المزيد' : 'من المعرض',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: onPick,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandTeal,
                    side: const BorderSide(
                        color: AppColors.brandTeal, width: 1.5),
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
        ),
      ],
    ),
  );
}

Widget _buildMedicalThumb({
  required BuildContext context,
  required JisrColors c,
  required File file,
  required VoidCallback onRemove,
}) {
  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          file,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 92,
            height: 92,
            color: c.line,
            child: Icon(AppIcons.image, color: c.muted),
          ),
        ),
      ),
      Positioned(
        top: 2,
        right: 2,
        child: InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ),
      ),
    ],
  );
}