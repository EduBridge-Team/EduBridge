// lib/screens/profile/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_icons.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../change_password_screen.dart';
import '../welcome_screen.dart';

part 'profile_delete_dialog.dart';
part 'profile_widgets.dart';

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

  final ImagePicker _picker = ImagePicker();
  bool _uploadingAvatar = false;

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

      final avatarUrl = (data?['avatar_url'] ?? '').toString();
      await ApiService.saveAvatarUrl(avatarUrl.isEmpty ? null : avatarUrl);

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

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;
      await _uploadAvatar(File(picked.path));
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
        if (_profile != null) _profile!['avatar_url'] = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الصورة'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الصورة'),
        content: const Text('هل تريد حذف صورة البروفايل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
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
        if (_profile != null) _profile!['avatar_url'] = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الصورة'),
          backgroundColor: AppColors.green,
        ),
      );
    }
  }

  void _showAvatarOptions() {
    final hasAvatar =
        (_profile?['avatar_url'] ?? '').toString().isNotEmpty;

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(AppIcons.camera, color: AppColors.brandBlue),
                title: const Text('التقاط صورة'),
                subtitle: const Text('من كاميرا الجهاز'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(AppIcons.image, color: AppColors.brandBlue),
                title: const Text('اختيار من المعرض'),
                subtitle: const Text('صورة محفوظة على الجهاز'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(AppIcons.delete, color: AppColors.red),
                  title: const Text(
                    'حذف الصورة الحالية',
                    style: TextStyle(color: AppColors.red),
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

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
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
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف حسابك بنجاح'),
          backgroundColor: AppColors.green,
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
        SnackBar(content: Text(msg), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من التطبيق؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
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

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'الملف الشخصي'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(c),
    );
  }

}
