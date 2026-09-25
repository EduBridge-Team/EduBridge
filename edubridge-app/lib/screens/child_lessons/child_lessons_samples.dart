// lib/screens/child_lessons/child_lessons_samples.dart
part of 'child_lessons_screen.dart';

List<Map<String, dynamic>> getSampleLessons(DisabilityType type) {
  switch (type) {
    case DisabilityType.downSyndrome:
      return [
        {
          'id': -1,
          'title': 'الفواكه',
          'content': 'هذه تفاحة. التفاحة حمراء. أكل التفاحة مفيد!'
        },
        {
          'id': -2,
          'title': 'الحيوانات',
          'content': 'هذا كلب. الكلب يقول: هَو هَو.'
        },
        {
          'id': -3,
          'title': 'الطقس',
          'content': 'الشمس مشرقة. نلبس ملابس خفيفة.'
        },
      ];
    case DisabilityType.blind:
      return [
        {
          'id': -1,
          'title': 'أصوات الحيوانات',
          'content': 'الكلب يعوي: هَو هَو. القطة تموء: مياو.'
        },
        {
          'id': -2,
          'title': 'الملمس والأشكال',
          'content': 'المستطيل له 4 أضلاع. المربع كل أضلاعه متساوية.'
        },
      ];
    case DisabilityType.deaf:
      return [
        {
          'id': -1,
          'title': 'حروف الإشارة',
          'content': 'إشارة الألف: ارفع إبهامك للأعلى'
        },
        {
          'id': -2,
          'title': 'القراءة البصرية',
          'content': 'انظر للكلمات: بيت، شمس'
        },
      ];
    default:
      return [
        {
          'id': -1,
          'title': 'درس تجريبي',
          'content': 'هذا درس تجريبي.'
        },
      ];
  }
}