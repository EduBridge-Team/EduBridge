// lib/screens/add_lesson/add_lesson_media_pickers.dart
part of 'add_lesson_sheet.dart';

Widget buildImagesPicker({
  required BuildContext context,
  required JisrColors c,
  required List<File> imageFiles,
  required VoidCallback onPick,
  required ValueChanged<int> onRemove,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.orange.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(AppIcons.image, color: AppColors.orange, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'صور الدرس (اختياري)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.onTint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'يمكن اختيار عدة صور ودمجها مع الفيديو أو الصوت',
          style: TextStyle(fontSize: 11, color: c.muted),
        ),
        const SizedBox(height: 8),
        if (imageFiles.isNotEmpty) ...[
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imageFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final file = imageFiles[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        file,
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 3,
                      right: 3,
                      child: InkWell(
                        onTap: () => onRemove(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(AppIcons.close,
                              color: Colors.white, size: 15),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
        SizedBox(
          width: double.infinity,
          height: 38,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(AppIcons.image, size: 18),
            label: Text(imageFiles.isEmpty ? 'اختر صوراً' : 'تغيير الصور'),
            onPressed: onPick,
          ),
        ),
      ],
    ),
  );
}

Widget buildFilePicker({
  required JisrColors c,
  required IconData icon,
  required String label,
  required String sublabel,
  required Color color,
  required File? file,
  required VoidCallback onPick,
  required VoidCallback onClear,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: c.onTint,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(sublabel, style: TextStyle(fontSize: 11, color: c.muted)),
        const SizedBox(height: 8),
        if (file == null)
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(AppIcons.upload, size: 18),
              label: const Text('اختر ملف'),
              onPressed: onPick,
            ),
          )
        else
          Row(
            children: [
              Icon(AppIcons.check, color: c.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  file.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.onTint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(AppIcons.close, color: c.onTint, size: 18),
                onPressed: onClear,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
      ],
    ),
  );
}