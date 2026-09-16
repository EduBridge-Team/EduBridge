import 'package:flutter/material.dart';

/// شعار EduBridge الموحد: الأيقونة الرسمية + الاسم بدون مسافة.
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
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/brand_icon.png',
            width: iconSize,
            height: iconSize,
            fit: BoxFit.contain,
          ),
          SizedBox(width: gap),
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFF1769C2),
                Color(0xFF54CED0),
                Color(0xFF1769C2),
              ],
            ).createShader(bounds),
            child: Text(
              'EduBridge',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
