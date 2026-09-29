import 'package:flutter/material.dart';

/// شعار EduBridge الأفقي الرسمي.
///
/// نستخدم ملف الهوية نفسه بدلاً من إعادة رسم كلمة EduBridge بخط النظام؛
/// هذا يمنع اختلاف شكل الحروف، خصوصاً حرف g، بين الأجهزة والخطوط.
class BrandLockup extends StatelessWidget {
  final double iconSize;
  final double fontSize;
  final double gap;

  const BrandLockup({
    super.key,
    this.iconSize = 58,
    this.fontSize = 34,
    this.gap = 9,
  });

  @override
  Widget build(BuildContext context) {
    final height = iconSize.clamp(34.0, 72.0);
    final width = (fontSize * 5.75 + iconSize + gap).clamp(150.0, 280.0);

    return Image.asset(
      'assets/brand_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'EduBridge',
    );
  }
}
