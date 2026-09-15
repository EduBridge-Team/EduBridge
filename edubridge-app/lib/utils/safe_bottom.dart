import 'package:flutter/material.dart';

/// المسافة الآمنة السفلية لأي bottom sheet / modal:
/// - إذا الكيبورد مفتوح: نرجّع ارتفاعه (viewInsets.bottom).
/// - إذا لأ: نرجّع مساحة أمان الجهاز (padding.bottom — شريط التنقل/الجست)
///   زائد هامش بصري بسيط، حتى ما تلتصق الأزرار بشريط تنقل الجهاز.
double safeModalBottom(BuildContext context, {double margin = 16}) {
  final mq = MediaQuery.of(context);
  return mq.viewInsets.bottom > 0
      ? mq.viewInsets.bottom
      : mq.padding.bottom + margin;
}
