part of 'admin_screen.dart';

/// Select a role before opening its dedicated account creation form.
class _AdminAccountTypeDialog extends StatelessWidget {
  const _AdminAccountTypeDialog();

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return AlertDialog(
      title: Text(arabic ? 'إنشاء حسابات' : 'Create accounts'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in [
              ('ministry', Icons.account_balance_outlined,
                  arabic ? 'وزارة' : 'Ministry'),
              ('institution', Icons.add_business_outlined,
                  arabic ? 'مؤسسة' : 'Institution'),
              ('school', Icons.school_outlined,
                  arabic ? 'مدرسة مستقلة' : 'Independent school'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  key: ValueKey('create_account_${option.$1}'),
                  onPressed: () => Navigator.pop(context, option.$1),
                  icon: Icon(option.$2),
                  label: Text(option.$3),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(arabic ? 'إلغاء' : 'Cancel'),
        ),
      ],
    );
  }
}
