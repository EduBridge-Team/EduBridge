/// Weekly reports use the API's UTC calendar, including on local Monday nights.
DateTime reportWeekStart(DateTime instant) {
  final utc = instant.toUtc();
  final date = DateTime.utc(utc.year, utc.month, utc.day);
  return date.subtract(Duration(days: utc.weekday - DateTime.monday));
}
