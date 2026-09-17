// lib/screens/profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'change_password_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

    Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;

      // ✅ احفظ صورة البروفايل محلياً للاستخدام السريع
      final avatarUrl = (data?['avatar_url'] ?? '').toString();
      await ApiService.saveAvatarUrl(
        avatarUrl.isEmpty ? null : avatarUrl,
      );

      setState(() {
        _profile = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الملف الشخصي';
        _loading = false;
      });
    }
  }
    // ═══════════════════════════════════════════
  //  صورة البروفايل
  // ═══════════════════════════════════════════
  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final file = File(picked.path);
      await _uploadAvatar(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح المعرض')),
      );
    }
  }

  Future<void> _uploadAvatar(File file) async {
    setState(() => _uploadingAvatar = true);

    try {
      final url = await ApiService.uploadProfilePicture(file);
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
        if (_profile != null) {
          _profile!['avatar_url'] = url;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم تحديث الصورة'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف صورة البروفايل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ApiService.removeProfilePicture();
    if (!mounted) return;

    if (ok) {
      setState(() {
        if (_profile != null) {
          _profile!['avatar_url'] = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الصورة'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تغيير صورة البروفايل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_camera,
                    color: AppColors.tealDeep),
                title: const Text('التقاط صورة'),
                subtitle: const Text('من كاميرا الجهاز'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.tealDeep),
                title: const Text('اختيار من المعرض'),
                subtitle: const Text('صورة محفوظة على الجهاز'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if ((_profile?['avatar_url'] ?? '').toString().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  title: const Text(
                    'حذف الصورة الحالية',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _removeAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  حذف الحساب
  // ═══════════════════════════════════════════
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeleteAccountDialog(),
    );

    if (confirmed != true || !mounted) return;
    await _executeDelete();
  }

  Future<void> _executeDelete() async {
    setState(() => _deleting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      await ApiService.deleteAccount();

      if (!mounted) return;
      Navigator.pop(context); // إغلاق التحميل

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف حسابك بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);

      setState(() => _deleting = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  // ═══════════════════════════════════════════
  //  تسجيل الخروج
  // ═══════════════════════════════════════════
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  // ═══════════════════════════════════════════
  //  بناء الواجهة
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: '👤 الملف الشخصي'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(c),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(JisrColors c) {
    final name = (_profile?['name'] ?? '').toString();
    final email = (_profile?['email'] ?? '').toString();
    final phone = (_profile?['phone'] ?? '').toString();
    final role = (_profile?['role'] ?? '').toString();
    final isVerified = _profile?['is_verified'] == true ||
        _profile?['verification_status'] == 'verified';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── الأفاتار الكبير + الاسم ───
          _buildHeaderCard(
            name: name,
            role: role,
            isVerified: isVerified,
          ),
          const SizedBox(height: 20),

          // ─── معلومات الحساب ───
          _sectionTitle('👤 معلومات الحساب', c),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.person_outline,
                    label: 'الاسم',
                    value: name.isEmpty ? '—' : name,
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    icon: Icons.mail_outline,
                    label: 'البريد الإلكتروني',
                    value: email.isEmpty ? '—' : email,
                  ),
                  if (phone.isNotEmpty) ...[
                    const Divider(height: 1),
                    _infoRow(
                      icon: Icons.phone_outlined,
                      label: 'رقم الهاتف',
                      value: phone,
                    ),
                  ],
                  const Divider(height: 1),
                  _infoRow(
                    icon: Icons.badge_outlined,
                    label: 'الدور',
                    value: _roleLabel(role),
                  ),
                  const Divider(height: 1),
                  _infoRow(
                    icon: isVerified
                        ? Icons.verified_outlined
                        : Icons.info_outline,
                    label: 'الحالة',
                    value: isVerified ? 'موثّق ✓' : 'غير موثّق',
                    valueColor: isVerified
                        ? AppColors.green
                        : AppColors.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ─── الأمان ───
          _sectionTitle('🔐 الأمان', c),
          const SizedBox(height: 8),
          _actionCard(
            icon: Icons.lock_outline,
            title: 'تغيير كلمة المرور',
            subtitle: 'حدّث كلمة المرور لحماية حسابك',
            color: AppColors.teal,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
              if (result == true) _load();
            },
          ),
          const SizedBox(height: 20),

          // ─── الإعدادات ───
          _sectionTitle('⚙️ الإعدادات', c),
          const SizedBox(height: 8),
          _actionCard(
            icon: Icons.contrast,
            title: 'تبديل وضع العرض',
            subtitle: 'فاتح / ليلي',
            color: AppColors.navy,
            onTap: () async {
              await toggleThemeMode();
            },
          ),
          const SizedBox(height: 8),
          _actionCard(
            icon: Icons.privacy_tip_outlined,
            title: 'الخصوصية والحساب',
            subtitle: 'سياسة الخصوصية وشروط الاستخدام',
            color: AppColors.tealDeep,
            onTap: () {
              // استخدام LegalLinksButton الموجودة
              // (يمكنك استدعاؤها مباشرة)
            },
          ),
          const SizedBox(height: 20),

          // ─── منطقة الخطر ───
          _sectionTitle('⚠️ منطقة الخطر', c),
          const SizedBox(height: 8),
          _actionCard(
            icon: Icons.delete_forever,
            title: 'حذف الحساب نهائياً',
            subtitle: 'سيتم حذف حسابك وكل بياناتك — لا يمكن التراجع',
            color: Colors.red,
            isDanger: true,
            onTap: _deleting ? null : _confirmDeleteAccount,
          ),
          const SizedBox(height: 8),
          _actionCard(
            icon: Icons.logout,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من التطبيق',
            color: AppColors.orangeDeep,
            onTap: _logout,
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

   Widget _buildHeaderCard({
    required String name,
    required String role,
    required bool isVerified,
  }) {
    final initial = name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : '؟';
    final avatarUrl = (_profile?['avatar_url'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ الأفاتار قابل للنقر
          GestureDetector(
            onTap: _uploadingAvatar ? null : _showAvatarOptions,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: _uploadingAvatar
                      ? const CircularProgressIndicator(
                          color: AppColors.tealDeep,
                        )
                      : avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                              errorBuilder: (_, __, ___) => Text(
                                initial,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navyDeep,
                                ),
                              ),
                            )
                          : Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyDeep,
                              ),
                            ),
                ),
                // ─── أيقونة كاميرا صغيرة ───
                if (!_uploadingAvatar)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name.isEmpty ? 'مستخدم' : name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _roleLabel(role),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isVerified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'موثّق',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _sectionTitle(String title, JisrColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: c.heading,
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.tealDeep),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? JisrColors.of(context).body,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final c = JisrColors.of(context);

    return Card(
      margin: EdgeInsets.zero,
      color: isDanger
          ? Colors.red.withValues(alpha: 0.05)
          : c.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDanger
              ? Colors.red.withValues(alpha: 0.3)
              : c.line,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDanger ? Colors.red : c.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: c.muted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'parent':
        return 'ولي أمر';
      case 'teacher':
        return 'معلّم';
      case 'specialist':
        return 'مختص';
      case 'admin':
        return 'أدمن';
      case 'ministry':
        return 'وزارة';
      case 'institution':
        return 'مؤسسة';
      default:
        return role.isEmpty ? 'مستخدم' : role;
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  نافذة تأكيد حذف الحساب
// ═══════════════════════════════════════════════════════════
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmCtrl = TextEditingController();
  bool _canDelete = false;

  static const _confirmWord = 'حذف';

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() {
      final ok = _confirmCtrl.text.trim() == _confirmWord;
      if (ok != _canDelete) setState(() => _canDelete = ok);
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
          Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 32),
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
                  Text('سيتم حذف:',
                      style: TextStyle(fontSize: 13)),
                  SizedBox(height: 4),
                  Text('• حسابك وبياناتك الشخصية',
                      style: TextStyle(fontSize: 13)),
                  Text('• جميع الأطفال المرتبطين بحسابك',
                      style: TextStyle(fontSize: 13)),
                  Text('• كل الدروس والتقدّم المسجّل',
                      style: TextStyle(fontSize: 13)),
                  Text('• الإشعارات والمحادثات',
                      style: TextStyle(fontSize: 13)),
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
                  borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _canDelete
                ? Colors.red
                : Colors.red.withValues(alpha: 0.4),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.delete_forever),
          label: const Text('حذف نهائي'),
          onPressed:
              _canDelete ? () => Navigator.pop(context, true) : null,
        ),
      ],
    );
  }
}