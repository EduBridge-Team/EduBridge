import 'package:flutter/widgets.dart';

class SchoolSpecialistsLabels {
  SchoolSpecialistsLabels(BuildContext context) : english = Localizations.localeOf(context).languageCode == 'en';
  final bool english;
  String pick(String ar, String en) => english ? en : ar;
  String get title => pick('أخصائيو المدرسة', 'School specialists');
  String get add => pick('تكليف أخصائي بالمدرسة', 'Assign specialist to school');
  String get choose => pick('اختر الأخصائي', 'Choose specialist');
  String get end => pick('إنهاء التكليف', 'End assignment');
  String get confirm => pick('تأكيد', 'Confirm');
  String get cancel => pick('إلغاء', 'Cancel');
  String get active => pick('تكليف حالي', 'Current assignment');
  String get ended => pick('تكليف منتهٍ', 'Ended assignment');
  String get empty => pick('لا توجد تكليفات أخصائيين لهذه المدرسة.', 'No specialist assignments for this school.');
  String get noEligible => pick('لا يوجد أخصائيون متاحون للتكليف.', 'No specialists are eligible for assignment.');
  String get scope => pick('التكليف للمدرسة كاملة. يختار الأخصائي لاحقًا الطلاب الذين سيتابعهم من المدرسة؛ لا يضيف هذا الإجراء طلابًا إلى متابعته تلقائيًا.',
      'This assignment is for the whole school. The specialist later chooses students from that school to follow; this action does not automatically add students to their caseload.');
  String get endEffect => pick('ينتهي الوصول الناتج عن هذا التكليف حسب سياسة الخدمة، مع حفظ سجل المتابعة السابق.',
      'Access derived from this assignment ends under server policy; previous follow-up history is retained.');
  String get effective => pick('التاريخ الفعلي', 'Effective date');
}

