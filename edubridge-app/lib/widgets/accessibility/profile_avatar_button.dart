// lib/widgets/profile_avatar_button.dart
import 'package:flutter/material.dart';
import '../../screens/profile/profile_screen.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

/// زر الأفاتار — يعرض:
/// - صورة البروفايل إذا وُجدت
/// - أو الحرف الأول من الاسم
/// عند الضغط → يفتح الملف الشخصي
class ProfileAvatarButton extends StatefulWidget {
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool showVerificationBadge;

  const ProfileAvatarButton({
    super.key,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 42,
    this.showVerificationBadge = false,
  });

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  String? _avatarUrl;
  String _initial = '؟';
  bool _loading = true;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await ApiService.getName();
    final url = await ApiService.getSavedAvatarUrl();
    final verified = widget.showVerificationBadge
        ? await ApiService.isVerified()
        : false;

    if (!mounted) return;
    setState(() {
      _initial = (name != null && name.trim().isNotEmpty)
          ? name.trim().characters.first.toUpperCase()
          : '؟';
      _avatarUrl = url;
      _verified = verified;
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.foregroundColor ?? AppColors.brandTealDeep,
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
          if (widget.showVerificationBadge && _verified)
            Positioned(
              left: -2,
              bottom: -2,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: const Color(0xFF35B76B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.check, size: 11, color: Colors.white),
              ),
            ),
        ],
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
          color: widget.foregroundColor ?? AppColors.brandTealDeep,
        ),
      ),
    );
  }
}