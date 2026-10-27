import 'package:flutter/material.dart';

/// A bounded, scrollable period calendar with wrapping date/action labels.
class InstitutionPeriodDialog extends StatefulWidget {
  const InstitutionPeriodDialog({super.key, required this.initialRange});
  final DateTimeRange initialRange;

  @override
  State<InstitutionPeriodDialog> createState() => _InstitutionPeriodDialogState();
}

class _InstitutionPeriodDialogState extends State<InstitutionPeriodDialog> {
  late DateTime _start = widget.initialRange.start;
  late DateTime _end = widget.initialRange.end;
  bool _choosingStart = true;

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final local = MaterialLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        key: const ValueKey('statistics-period-popup'),
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(english ? 'Choose period' : 'اختيار الفترة',
              style: Theme.of(context).textTheme.titleLarge),
            Wrap(spacing: 8, runSpacing: 8, children: [
              TextButton(
                onPressed: () => setState(() => _choosingStart = true),
                child: Text('${english ? 'From' : 'من'}: ${local.formatMediumDate(_start)}'),
              ),
              TextButton(
                onPressed: () => setState(() => _choosingStart = false),
                child: Text('${english ? 'To' : 'إلى'}: ${local.formatMediumDate(_end)}'),
              ),
            ]),
            Text(_choosingStart
              ? (english ? 'Choose the start date' : 'اختاري تاريخ البداية')
              : (english ? 'Choose the end date' : 'اختاري تاريخ النهاية')),
            CalendarDatePicker(
              key: ValueKey((_choosingStart, _start, _end)),
              initialDate: _choosingStart ? _start : _end,
              firstDate: _choosingStart ? DateTime(1900) : _start,
              lastDate: DateTime(2100, 12, 31),
              onDateChanged: (date) => setState(() {
                if (_choosingStart) {
                  _start = date;
                  if (_end.isBefore(date)) _end = date;
                  _choosingStart = false;
                } else {
                  _end = date;
                }
              }),
            ),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(local.cancelButtonLabel)),
              FilledButton(
                key: const ValueKey('statistics-period-apply'),
                onPressed: () => Navigator.pop(context, DateTimeRange(start: _start, end: _end)),
                child: Text(local.okButtonLabel),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
