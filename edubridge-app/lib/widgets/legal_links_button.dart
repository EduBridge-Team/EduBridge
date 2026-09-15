import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/welcome_screen.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/navigation.dart';

/// مجموعة أزرار قانونية موحّدة:
/// - سياسة الخصوصية (رابط خارجي)
/// - طلب حذف الحساب (رابط خارجي)
/// - حذف الحساب نهائياً (تنفيذ فعلي داخل التطبيق)
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

  // ═══════════════════════════════════════════════════════
  //  حذف الحساب نهائياً
  // ═══════════════════════════════════════════════════════
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DeleteAccountDialog(),
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

      // أغلق نافذة التحميل
      Navigator.of(context).pop();

      // رسالة نجاح
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف حسابك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // توجيه لشاشة الترحيب
      await Future.delayed(const Duration(milliseconds: 800));
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      // أغلق نافذة التحميل
      Navigator.of(context).pop();

      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void show(BuildContext context) {
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
                leading: const Icon(Icons.description_outlined),
                title: const Text('طلب حذف الحساب والبيانات'),
                subtitle: const Text('افتح خطوات إرسال طلب الحذف'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open(context, _deleteAccountUri);
                },
              ),
              const Divider(height: 24),
              // ✅ زر حذف الحساب نهائياً
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text(
                  'حذف الحساب نهائياً',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'سيتم حذف حسابك وكل بياناتك — لا يمكن التراجع',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
      tooltip: 'الخصوصية وحذف الحساب',
      onPressed: () => show(context),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  نافذة تأكيد حذف الحساب — مع تأكيد كتابي
// ═══════════════════════════════════════════════════════
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmCtrl = TextEditingController();
  bool _canDelete = false;

  // الكلمة المطلوبة للتأكيد
  static const _confirmWord = 'حذف';

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() {
      final ok = _confirmCtrl.text.trim() == _confirmWord;
      if (ok != _canDelete) {
        setState(() => _canDelete = ok);
      }
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'حذف الحساب نهائياً',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
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
            // تحذير
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ تحذير: هذا الإجراء نهائي',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'سيتم حذف:',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text('• حسابك وبياناتك الشخصية', style: TextStyle(fontSize: 13)),
                  Text('• جميع الأطفال المرتبطين بحسابك', style: TextStyle(fontSize: 13)),
                  Text('• كل الدروس والتقدّم المسجّل', style: TextStyle(fontSize: 13)),
                  Text('• الإشعارات والمحادثات', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'للتأكيد، اكتب كلمة "$_confirmWord" في الحقل أدناه:',
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
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
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // زر إلغاء
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        // زر حذف — معطّل حتى الكتابة الصحيحة
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _canDelete ? Colors.red : Colors.red.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text('حذف نهائي'),
          onPressed: _canDelete
              ? () => Navigator.pop(context, true)
              : null,
        ),
      ],
    );
  }
}
