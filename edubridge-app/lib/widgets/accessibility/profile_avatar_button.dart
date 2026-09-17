// lib/widgets/profile_avatar_button.dart
import 'package:flutter/material.dart';
import '../../screens/profile_screen.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

/// زر الأفاتار — يعرض:
/// - صورة البروفايل إذا وُجدت
/// - أو الحرف الأول من الاسم
/// عند الضغط → يفتح الملف الشخصي
class ProfileAvatarButton extends StatefulWidget {
  final Color? backgroundColor;
  final double size;

  const ProfileAvatarButton({
    super.key,
    this.backgroundColor,
    this.size = 42,
  });

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  String? _avatarUrl;
  String _initial = '؟';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await ApiService.getName();
    final url = await ApiService.getSavedAvatarUrl();

    if (!mounted) return;
    setState(() {
      _initial = (name != null && name.trim().isNotEmpty)
          ? name.trim().characters.first.toUpperCase()
          : '؟';
      _avatarUrl = url;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
        // ✅ إعادة تحميل الصورة عند الرجوع
        _load();
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        clipBehavior: Clip.antiAlias,
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.navyDeep,
                ),
              )
            : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                ? Image.network(
                    _avatarUrl!,
                    fit: BoxFit.cover,
                    width: widget.size,
                    height: widget.size,
                    errorBuilder: (_, __, ___) => _buildInitial(),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _buildInitial();
                    },
                  )
                : _buildInitial(),
      ),
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: widget.size * 0.45,
          fontWeight: FontWeight.bold,
          color: AppColors.navyDeep,
        ),
      ),
    );
  }
}