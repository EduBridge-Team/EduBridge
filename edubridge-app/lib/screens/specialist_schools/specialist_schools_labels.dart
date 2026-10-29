import 'package:flutter/widgets.dart';

class SpecialistSchoolsLabels {
  SpecialistSchoolsLabels(BuildContext context) : english = Localizations.localeOf(context).languageCode == 'en';
  final bool english;
  String pick(String ar, String en) => english ? en : ar;
  String get schools => pick('مدارسي', 'My schools');
  String get students => pick('طلاب المدرسة', 'School students');
  String get noSchools => pick('لا توجد مدارس مكلّف بها حاليًا.', 'You have no current school assignments.');
  String get noStudents => pick('لا يوجد طلاب متاحون في هذه المدرسة.', 'No students are available in this school.');
  String get noMatches => pick('لا يوجد طلاب مطابقون للبحث.', 'No students match your search.');
  String get search => pick('البحث عن طالب', 'Search students');
  String get follow => pick('بدء متابعة الطالب', 'Start following student');
  String get following => pick('تحت متابعتك', 'On your caseload');
  String get confirm => pick('تأكيد', 'Confirm');
  String get cancel => pick('إلغاء', 'Cancel');
  String get explanation => pick('اختر الطلاب الذين تريد متابعتهم من المدرسة المكلّف بها. لا تتم إضافة أي طالب تلقائيًا.',
      'Choose students to follow from your assigned school. No student is added automatically.');
}

