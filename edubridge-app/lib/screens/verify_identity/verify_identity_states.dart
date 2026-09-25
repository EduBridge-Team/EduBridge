// lib/screens/verify_identity/verify_identity_states.dart
part of 'verify_identity_screen.dart';

// ═══════════════════════════════════════════════════════════
//  State 0: موثّق — شاشة تأكيد (جديد من زميلك)
// ═══════════════════════════════════════════════════════════
Widget buildVerifiedState({
  required BuildContext context,
  required JisrColors c,
  required bool isTeacherOrSpecialist,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: 'توثيق الهوية'),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified_user,
              size: 76,
              color: AppColors.brandBlueLight,
            ),
            const SizedBox(height: 16),
            Text(
              'تم توثيق حسابك',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrSpecialist
                  ? 'تم اعتماد الهوية وبياناتك المهنية. يمكنك استخدام صلاحياتك بشكل طبيعي.'
                  : 'تم اعتماد هويتك بنجاح.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.muted,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
                onPressed: () => Navigator.maybePop(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  State 1: قيد المراجعة
// ═══════════════════════════════════════════════════════════
Widget buildPendingState({
  required BuildContext context,
  required JisrColors c,
  required bool isTeacherOrSpecialist,
  required bool loading,
  required Future<void> Function() onRefresh,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: 'توثيق الهوية'),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_top, size: 72, color: AppColors.tealDeep),
            const SizedBox(height: 16),
            Text(
              'طلبك قيد المراجعة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeacherOrSpecialist
                  ? 'سيتم التحقق من هويتك وشهادتك خلال 24 ساعة. شكراً لصبرك.'
                  : 'سيتم تفعيل حسابك فور موافقة الإدارة. شكراً لصبرك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث الحالة'),
                onPressed: loading ? null : onRefresh,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('خروج'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  State 2: مرفوض
// ═══════════════════════════════════════════════════════════
Widget buildRejectedState({
  required BuildContext context,
  required JisrColors c,
  required VoidCallback onRetry,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: 'توثيق الهوية'),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 72, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'تم رفض طلب التوثيق',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يرجى مراجعة البيانات والصور وإعادة المحاولة، أو التواصل مع الدعم الفني.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
//  State 3: نموذج جديد
// ═══════════════════════════════════════════════════════════
Widget buildFormState({
  required BuildContext context,
  required JisrColors c,
  required bool isTeacherOrSpecialist,
  required TextEditingController nationalIdCtrl,
  required TextEditingController certificateTitleCtrl,
  required File? idImage,
  required File? certificateFile,
  required bool loading,
  required String? error,
  required VoidCallback onPickId,
  required VoidCallback onCaptureId,
  required VoidCallback onRemoveId,
  required VoidCallback onPickCertificate,
  required VoidCallback onCaptureCertificate,
  required VoidCallback onRemoveCertificate,
  required VoidCallback onSubmit,
}) {
  return Scaffold(
    appBar: JisrAppBar(title: 'توثيق الهوية'),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(c, isTeacherOrSpecialist),
          const SizedBox(height: 20),

          TextField(
            controller: nationalIdCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'رقم الهوية *',
              prefixIcon: Icon(Icons.credit_card),
              hintText: 'مثال: 1234567890',
            ),
          ),
          const SizedBox(height: 16),

          _buildFileCard(
            c: c,
            title: 'صورة الهوية *',
            subtitle: 'jpg, png, webp — صورة واضحة للوجه الأمامي',
            icon: Icons.badge_outlined,
            color: AppColors.teal,
            file: idImage,
            onPick: onPickId,
            onCapture: onCaptureId,
            onClear: onRemoveId,
          ),

          if (isTeacherOrSpecialist) ...[
            const SizedBox(height: 16),
            _buildCertificateSection(
              c: c,
              titleCtrl: certificateTitleCtrl,
              file: certificateFile,
              onPick: onPickCertificate,
              onCapture: onCaptureCertificate,
              onClear: onRemoveCertificate,
            ),
          ],

          const SizedBox(height: 20),

          if (error != null) ...[
            _buildErrorBox(error),
            const SizedBox(height: 12),
          ],

          _buildSubmitButton(loading: loading, onSubmit: onSubmit),
        ],
      ),
    ),
  );
}

Widget _buildInfoBanner(JisrColors c, bool isTeacherOrSpecialist) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: c.tintOrange,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(Icons.info, color: c.onTint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isTeacherOrSpecialist
                ? 'مطلوب توثيق الهوية + رفع الشهادة العلمية لتفعيل صلاحياتك الكاملة.'
                : 'لا يمكنك استخدام الصلاحيات الكاملة قبل توثيق هويتك.',
            style: TextStyle(
              color: c.onTint,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCertificateSection({
  required JisrColors c,
  required TextEditingController titleCtrl,
  required File? file,
  required VoidCallback onPick,
  required VoidCallback onCapture,
  required VoidCallback onClear,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: c.tintYellow,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.brandBlueLight.withValues(alpha: 0.4),
        width: 1.5,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppColors.brandBlueDeep, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'الشهادة العلمية *',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.brandBlueLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'إلزامي',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlueDeep,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'عنوان الشهادة *',
            hintText: 'مثال: بكالوريوس تربية خاصة',
            prefixIcon: Icon(Icons.school),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (file == null)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('من المعرض'),
                    onPressed: onPick,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue,
                      side: const BorderSide(
                          color: AppColors.blue, width: 1.5),
                    ),
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('الكاميرا'),
                    onPressed: onCapture,
                  ),
                ),
              ),
            ],
          )
        else
          _buildSelectedFileRow(c, file, onClear),
      ],
    ),
  );
}

Widget _buildSelectedFileRow(JisrColors c, File file, VoidCallback onClear) {
  return Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          file.path.split('/').last,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: c.onTint,
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, color: Colors.red, size: 20),
        onPressed: onClear,
      ),
    ],
  );
}

Widget _buildFileCard({
  required JisrColors c,
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required File? file,
  required VoidCallback onPick,
  VoidCallback? onCapture,
  required VoidCallback onClear,
}) {
  final hasFile = file != null;

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: hasFile ? color.withValues(alpha: 0.08) : c.tintTeal,
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
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: c.heading,
                ),
              ),
            ),
            if (hasFile)
              const Icon(Icons.check_circle,
                  color: AppColors.green, size: 22),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: c.muted)),
        const SizedBox(height: 10),
        if (!hasFile)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('من المعرض'),
                    onPressed: onPick,
                  ),
                ),
              ),
              if (onCapture != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color, width: 1.5),
                      ),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('الكاميرا'),
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
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: c.line,
                    child: Icon(Icons.image, color: c.muted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  file.path.split('/').last,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c.onTint,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: color, size: 20),
                onPressed: onPick,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: onClear,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
      ],
    ),
  );
}

Widget _buildErrorBox(String error) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.red.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            error,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSubmitButton({
  required bool loading,
  required VoidCallback onSubmit,
}) {
  return SizedBox(
    height: 56,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.tealDeep,
      ),
      onPressed: loading ? null : onSubmit,
      icon: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.send),
      label: Text(
        loading ? 'جارٍ الإرسال...' : 'حفظ وإرسال للتوثيق',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    ),
  );
}