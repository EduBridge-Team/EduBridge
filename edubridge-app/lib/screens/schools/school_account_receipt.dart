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
          Text(arabic
              ? 'تم إنشاء المدرسة وإرسال رابط التفعيل إلى بريدها الرسمي.'
              : 'School created. Activation link sent to the official school mailbox.',
              key: const ValueKey('school-account-success')),
          const SizedBox(height: 12),
          Text(
            arabic
                ? 'يفتح مسؤول البريد الرسمي رابط التفعيل ويحدد كلمة مرور المدرسة. حساب المدير مستقل ويمكن تكليفه لاحقًا.'
                : 'The mailbox owner activates the school and sets its password. The director uses a separate personal account.',
            key: const ValueKey('school-account-verification-guidance'),
          ),
          if (account.invitationPending)
            Text(arabic ? 'أُرسلت دعوة المدير؛ ينتظر التكليف قبولها.' : 'Director invitation sent; appointment awaits acceptance.'),
          if (account.directorAssigned)
            Text(arabic ? 'تم ربط المدير بحسابه الشخصي.' : 'Director appointed through the personal account.'),
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
