// lib/screens/profile/profile_delete_dialog.dart
part of 'profile_screen.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirmCtrl = TextEditingController();
  bool get _canDelete => _confirmCtrl.text.trim() == _confirmWord;

  String get _confirmWord => context.l10n.deleteConfirmationWord;

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(AppIcons.warning, color: AppColors.red, size: 32),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.deleteAccountPermanently,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.red,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWarningBox(),
            const SizedBox(height: 16),
            Text(
              context.l10n.deleteAccountInstruction(_confirmWord),
              style: TextStyle(
                fontSize: 14,
                color: c.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: _confirmWord,
                hintStyle: TextStyle(color: c.muted),
                filled: true,
                fillColor: c.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.red, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _canDelete ? AppColors.red : AppColors.red.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(AppIcons.delete),
          label: Text(context.l10n.permanentDelete),
          onPressed: _canDelete ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.irreversibleActionWarning,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(context.l10n.willBeDeleted, style: TextStyle(fontSize: 13)),
          SizedBox(height: 4),
          Text(context.l10n.deleteAccountData, style: TextStyle(fontSize: 13)),
          Text(context.l10n.deleteLinkedChildren, style: TextStyle(fontSize: 13)),
          Text(context.l10n.deleteLessonProgress, style: TextStyle(fontSize: 13)),
          Text(context.l10n.deleteMessagesNotifications, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}