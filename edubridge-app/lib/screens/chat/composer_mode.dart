// lib/screens/chat/composer_mode.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════════════════
//  أوضاع التواصل داخل المحادثة
// ═══════════════════════════════════════════════════════════
enum ComposerMode {
  text,       // ⌨️ كتابة عادية
  aac,        // 🖼️ تواصل بالصور
  sign,       // 🤟 لغة إشارة
}

// ═══════════════════════════════════════════════════════════
//  وصف كل وضع للعرض في الواجهة
// ═══════════════════════════════════════════════════════════
class ComposerModeMeta {
  final ComposerMode mode;
  final IconData icon;
  final String label;
  final String description;

  const ComposerModeMeta({
    required this.mode,
    required this.icon,
    required this.label,
    required this.description,
  });
}

// ═══════════════════════════════════════════════════════════
//  قائمة الأوضاع — مصدر واحد للحقيقة
// ═══════════════════════════════════════════════════════════
const kComposerModes = <ComposerModeMeta>[
  ComposerModeMeta(
    mode: ComposerMode.text,
    icon: Icons.keyboard_alt_outlined,
    label: 'نص',
    description: 'الكتابة بالكيبورد',
  ),
  ComposerModeMeta(
    mode: ComposerMode.aac,
    icon: Icons.grid_view_rounded,
    label: 'صور (AAC)',
    description: 'اختر صوراً لبناء جملتك',
  ),
  ComposerModeMeta(
    mode: ComposerMode.sign,
    icon: Icons.sign_language_outlined,
    label: 'لغة الإشارة',
    description: 'استخدم رموز الإشارة العربية',
  ),
];

// ═══════════════════════════════════════════════════════════
//  خدمة حفظ الوضع المختار
//  - Singleton لضمان حالة واحدة عبر التطبيق
//  - يُحفظ في SharedPreferences ليُستعاد عند إعادة الفتح
// ═══════════════════════════════════════════════════════════
class ComposerModeService {
  ComposerModeService._();
  static final ComposerModeService instance = ComposerModeService._();

  static const _prefKey = 'chat_composer_mode_v1';

  final ValueNotifier<ComposerMode> mode =
      ValueNotifier<ComposerMode>(ComposerMode.text);

  bool _loaded = false;

  /// يُستدعى مرة واحدة عند فتح أول محادثة
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved != null) {
      final parsed = ComposerMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ComposerMode.text,
      );
      mode.value = parsed;
    }
    _loaded = true;
  }

  /// يغيّر الوضع ويحفظه
  Future<void> setMode(ComposerMode next) async {
    if (mode.value == next) return;
    mode.value = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next.name);
  }

  /// إعادة للوضع الافتراضي (نص)
  Future<void> reset() async {
    await setMode(ComposerMode.text);
  }
}