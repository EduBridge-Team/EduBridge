import 'package:flutter/widgets.dart';

class IepEvidenceLabels {
  IepEvidenceLabels(BuildContext context)
      : _english = Localizations.localeOf(context).languageCode == 'en';
  final bool _english;
  String pick(String ar, String en) => _english ? en : ar;
  String get title => pick('أدلة الهدف ومتابعته', 'Goal evidence and follow-up');
  String get open => pick('عرض أدلة الهدف', 'View goal evidence');
  String get empty => pick('لا توجد أدلة موثقة لهذا الهدف بعد.', 'No documented evidence for this goal yet.');
  String get note => pick('الملاحظات والقياسات توثق المتابعة؛ اكتمال الدرس أو علامته لا يعني تحقق الهدف.',
      'Observations and measurements document follow-up; lesson completion or score does not establish goal achievement.');
  String get source => pick('المصدر', 'Source');
  String get observation => pick('الملاحظة', 'Observation');
  String get date => pick('تاريخ الملاحظة', 'Observed on');
  String get recorded => pick('وقت التوثيق', 'Recorded at');
  String get measurement => pick('القياس', 'Measurement');
  String get author => pick('وثقه', 'Recorded by');
  String get unavailable => pick('غير متاح', 'Unavailable');
}

