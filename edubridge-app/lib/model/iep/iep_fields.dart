import '../enrollment/enrollment_models.dart';

String? iepOptionalText(dynamic value) {
  if (value != null && value is! String)
    throw const FormatException('Invalid IEP text');
  return value as String?;
}

DateTime iepDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid IEP date');
  }
  final date = DateTime.tryParse(value);
  if (date == null || date.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('Invalid IEP calendar date');
  }
  return date;
}

DateTime iepTimestamp(dynamic value) {
  if (value is! String ||
      value.length < 19 ||
      !RegExp(r'^\d{4}-\d{2}-\d{2}[T ]').hasMatch(value)) {
    throw const FormatException('Invalid IEP timestamp');
  }
  iepDate(value.substring(0, 10));
  final date = DateTime.tryParse(value);
  if (date == null) throw const FormatException('Invalid IEP timestamp');
  return date;
}

List<String> iepTexts(dynamic value) => List.unmodifiable(
  enrollmentList(value).map((item) => enrollmentText(item)),
);
num iepMeasurement(dynamic value) {
  if (value is! num || !value.isFinite)
    throw const FormatException('Missing IEP measurement');
  return value;
}
