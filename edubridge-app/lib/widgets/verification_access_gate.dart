import 'package:flutter/material.dart';
import '../screens/verify_identity_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// يعرض الصلاحيات قبل التوثيق، ويمنع تنفيذها إلى أن يوافق الأدمن.
class VerificationAccessGate extends StatelessWidget {
  final Widget child;

  const VerificationAccessGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getVerificationStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        final isApproved = status == 'approved';

        if (isApproved) return child;

        return Stack(
          children: [
            AbsorbPointer(absorbing: true, child: child),
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.08),
                child: Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 54, color: AppColors.orange),
                          const SizedBox(height: 12),
                          Text(
                            status == 'pending'
                                ? 'طلب التوثيق قيد المراجعة'
                                : status == 'rejected'
                                    ? 'تم رفض التوثيق، يرجى إعادة الإرسال'
                                    : 'وثّق هويتك لتفعيل الصلاحيات',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'يمكنك مشاهدة أقسام التطبيق الآن، ولن تتمكن من استخدامها إلا بعد موافقة الأدمن.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.upload_file),
                              label: Text(status == 'pending'
                                  ? 'عرض حالة التوثيق'
                                  : 'توثيق الهوية'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const VerifyIdentityScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
