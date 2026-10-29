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
  String get measurementSummary => pick('ملخص القياسات', 'Measurement summary');
  String get latestMeasurement => pick('أحدث قياس بتاريخ الملاحظة', 'Latest measurement by observation date');
  String get noMeasurements => pick('لا توجد قياسات رقمية؛ تبقى الملاحظات الوصفية متاحة في السجل.', 'No numeric measurements; qualitative observations remain in the history.');
  String get measurementCaution => pick('المقارنة وصفية. لا تعني زيادة القيمة تحسنًا دائمًا، ولا تثبت هذه المقارنة تحقق الهدف.', 'This is a descriptive comparison. Higher values are not always better, and this comparison does not establish goal achievement.');
  String get plotTitle => pick('القياسات حسب تاريخ الملاحظة', 'Measurements by observation date');
  String get plotLegend => pick('النقاط: القياسات. الخط المتقطع: خط الأساس. الخط المتصل: القيمة المستهدفة.', 'Dots: measurements. Dashed line: baseline. Solid line: target.');
  String get plotAccessible => pick('رسم للقياسات الرقمية. القيم الدقيقة ومصادرها متاحة في جدول القياسات.', 'Numeric measurement plot. Exact values and sources are available in the measurement table.');
  String get plotLimit => pick('يعرض الرسم أحدث 50 قياسًا بحد أقصى؛ الجدول يتضمن كل القياسات المتاحة.', 'The plot shows up to the latest 50 measurements; the table includes all available measurements.');
  String get measurementTable => pick('كل القياسات ومصادرها', 'All measurements and sources');
  String get searchEvidence => pick('ابحث في الملاحظات أو المصدر أو الموثّق', 'Search observations, source or author');
  String get allEvidence => pick('كل الأدلة', 'All evidence');
  String get numericEvidence => pick('قياسات رقمية', 'Numeric measurements');
  String get qualitativeEvidence => pick('ملاحظات فقط', 'Qualitative only');
  String get oldestFirst => pick('الأقدم أولًا', 'Oldest first');
  String get filterNote => pick('التصفية تخص السجل أدناه؛ ملخص القياسات يشمل كل الأدلة المتاحة.', 'Filters apply to the history below; the measurement summary uses all available evidence.');
  String get noMatchingEvidence => pick('لا توجد أدلة مطابقة للتصفية والبحث.', 'No evidence matches the filters and search.');
}

