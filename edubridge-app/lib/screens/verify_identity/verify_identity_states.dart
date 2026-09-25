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
              color: AppColors.green,
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
