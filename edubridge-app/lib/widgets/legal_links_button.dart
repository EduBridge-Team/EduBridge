import '../l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/welcome_screen.dart';
import '../services/api_service.dart';
import '../screens/profile/profile_screen.dart' show DeleteAccountDialog;
part 'legal_links_button_view.dart';

class LegalLinksButton extends StatelessWidget {
  const LegalLinksButton({super.key});

  static final Uri _privacyUri =
      Uri.parse('https://edubridge.win/privacy.html');
  static final Uri _deleteAccountUri =
      Uri.parse('https://edubridge.win/delete-account.html');

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.pageOpenFailed)),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DeleteAccountDialog(),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await _executeDelete(context);
  }

  Future<void> _executeDelete(BuildContext context) async {
    // عرض تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      await ApiService.deleteAccount();

      if (!context.mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.accountDeleted),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context).pop();

      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.sharedMessage(msg)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.privacyAndAccount,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(context.l10n.privacyPolicy),
                  subtitle: Text(context.l10n.privacyPolicyDescription),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(context, _privacyUri);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(context.l10n.requestAccountDeletion),
                  subtitle: Text(context.l10n.deletionRequestSteps),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(context, _deleteAccountUri);
                  },
                ),
                const Divider(height: 24),
                // ✅ زر حذف الحساب نهائياً
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: Text(
                    context.l10n.deleteAccountPermanently,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    context.l10n.deleteAccountWarning,
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDelete(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}
