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
            arabic
                ? 'يجب على صاحب الحساب تأكيد بريده الإلكتروني قبل تسجيل الدخول. تحقق من البريد الوارد والرسائل غير المرغوب فيها، ويمكن إعادة إرسال رابط التأكيد من شاشة تسجيل الدخول.'
                : 'The account owner must verify their email before signing in. Check the inbox and spam folder; the verification link can be resent from the sign-in screen.',
            key: const ValueKey('school-account-verification-guidance'),
          ),
          const SizedBox(height: 16),
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
