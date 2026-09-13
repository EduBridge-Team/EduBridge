import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A single, reusable entry point for the legal pages required by Google Play.
class LegalLinksButton extends StatelessWidget {
  const LegalLinksButton({super.key});

  static final Uri _privacyUri =
      Uri.parse('https://edubridge.alwaysdata.net/privacy.html');
  static final Uri _deleteAccountUri =
      Uri.parse('https://edubridge.alwaysdata.net/delete-account.html');

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح الصفحة. حاول مرة أخرى.')),
      );
    }
  }

  void _showLegalLinks(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الخصوصية والحساب',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('سياسة الخصوصية'),
                subtitle: const Text('اعرف كيف نجمع بياناتك ونحميها'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, _privacyUri);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined),
                title: const Text('طلب حذف الحساب والبيانات'),
                subtitle: const Text('افتح خطوات إرسال طلب الحذف'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, _deleteAccountUri);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
      tooltip: 'الخصوصية وحذف الحساب',
      onPressed: () => _showLegalLinks(context),
    );
  }
}
