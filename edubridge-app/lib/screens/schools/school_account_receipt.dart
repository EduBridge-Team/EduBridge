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
                ? 'تم تكليف المدير بحسابه الشخصي الموثّق. يدخل المدير ببريده وكلمة مرور حسابه الحاليين.'
                : 'The director is assigned through their verified personal account. Sign in with the existing personal email and password.',
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
