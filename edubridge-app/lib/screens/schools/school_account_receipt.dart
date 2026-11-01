import '../school_management/school_director_management_screen.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_account.dart';

/// Confirmed public account details only; never retain provisioning credentials.
class SchoolAccountReceipt extends StatelessWidget {
  const SchoolAccountReceipt({super.key, required this.account});
  final SchoolAccount account;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.schoolAccountSuccess, key: const ValueKey('school-account-success')),
          const SizedBox(height: 12),
          Text(
            account.verificationEmailSent
              ? (arabic
                  ? 'أرسلنا رسالة التحقق إلى بريد المدرسة. بعد تأكيد البريد، يمكن تسجيل الدخول ببريد المدرسة وكلمة المرور التي تم تحديدها. يمكن تعيين المدير لاحقًا.'
                  : 'A verification link was sent to the school mailbox. Verify the email, then sign in with the school email and chosen password. A director can be appointed later.')
              : (arabic
                  ? 'تم إنشاء الحساب، لكن لم نتمكن من إرسال رسالة التحقق. أعد إرسال التأكيد من صفحة تسجيل الدخول.'
                  : 'Account created, but we could not send the verification email. Resend verification from the login page.'),
            key: const ValueKey('school-account-verification-guidance'),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SchoolDirectorManagementScreen(schoolId: account.schoolId, schoolName: account.name))), child: Text(arabic ? 'إدارة مدير المدرسة والدعوات' : 'Manage school director and invitations')),
          SelectableText('${l.schoolAccountName}: ${account.name}'),
          const SizedBox(height: 8),
          Text(l.schoolAccountEmail),
          SelectableText(account.email, textDirection: TextDirection.ltr,
            key: const ValueKey('school-account-created-email')),
        ],
      ),
    );
  }
}
