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
            arabic
                ? 'سيتلقى البريد الرسمي للمدرسة رابطًا لتعيين كلمة المرور وتفعيل الحساب. حساب المدير شخصي ومستقل، ويمكن تعيينه أو دعوته لاحقًا.'
                : 'The official school mailbox receives a link to set its password and activate the account. The director has a separate personal login and can be appointed or invited later.',
            key: const ValueKey('school-account-verification-guidance'),
          ),
          if (account.invitationPending)
            Text(arabic ? 'دعوة المدير بانتظار قبولها.' : 'Director invitation awaits acceptance.'),
          const SizedBox(height: 12),
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
