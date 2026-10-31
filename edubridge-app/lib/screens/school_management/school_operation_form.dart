import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolOperationForm extends StatefulWidget {
  const SchoolOperationForm({super.key, required this.definition, required this.references, required this.repository, required this.onSaved});
  final Map<String, dynamic> definition, references;
  final SchoolManagementRepository repository;
  final VoidCallback onSaved;
  @override
  State<SchoolOperationForm> createState() => _SchoolOperationFormState();
}
class _SchoolOperationFormState extends State<SchoolOperationForm> {
  final _form = GlobalKey<FormState>();
  final _values = <String, dynamic>{};
  bool _busy = false;
  EnrollmentFailure? _failure;
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final body = <String, dynamic>{};
    for (final field in widget.definition['fields'] as List) {
      final key = field['key'] as String, type = field['type'] as String;
      final value = _values[key];
      if (type == 'checkbox') { body[key] = value == true; continue; }
      if (value == null || '$value'.trim().isEmpty) {
        if (field['optional'] != true) { setState(() => _failure = EnrollmentFailure.validation); return; }
        continue;
      }
      if (type == 'number' || type == 'select' && field['reference'] != 'closure_statuses') {
        final number = int.tryParse('$value');
        if (number == null || number < 1) { setState(() => _failure = EnrollmentFailure.validation); return; }
        body[key] = number;
      } else { body[key] = '$value'.trim(); }
    }
    if (widget.definition['destructive'] == true) {
      final en = Localizations.localeOf(context).languageCode == 'en';
      final approved = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: Text(en ? 'Confirm this action?' : 'تأكيد هذا الإجراء؟'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(en ? 'Cancel' : 'إلغاء')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(en ? 'Confirm' : 'تأكيد'))],
      ));
      if (!mounted || approved != true) return;
    }
    setState(() { _busy = true; _failure = null; });
    try {
      await widget.repository.mutate('/school/operations/${widget.definition['action']}', widget.definition['method'] as String? ?? 'POST', body);
      if (mounted) widget.onSaved();
    } on EnrollmentApiException catch (error) { if (mounted) setState(() => _failure = error.failure); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    return Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final field in widget.definition['fields'] as List) Padding(padding: const EdgeInsets.only(bottom: 12), child: Builder(builder: (context) {
        final key = field['key'] as String, type = field['type'] as String;
        final label = field[en ? 'en' : 'ar'] as String;
        if (type == 'checkbox') return CheckboxListTile(title: Text(label), value: _values[key] == true, onChanged: _busy ? null : (value) => setState(() => _values[key] = value == true));
        if (type == 'select') {
          final options = (widget.references[field['reference']] as List? ?? []).whereType<Map>().toList();
          return DropdownButtonFormField<String>(isExpanded: true, initialValue: _values[key] as String?, decoration: InputDecoration(labelText: label),
            items: [if (field['optional'] == true) DropdownMenuItem(value: '', child: Text(t('بدون', 'None'))), for (final row in options)
              DropdownMenuItem(value: '${row['id']}', child: Text([row['label'] ?? row['child_name'] ?? row['teacher_name'] ?? row['name'] ?? row['title'] ?? row['subject_name'], row['section_name'], row['academic_year_name']].where((value) => value != null).join(' — '), overflow: TextOverflow.ellipsis))],
            validator: (value) => field['optional'] != true && (value ?? '').isEmpty ? t('اختر قيمة', 'Choose a value') : null,
            onChanged: _busy ? null : (value) => setState(() => _values[key] = value));
        }
        return TextFormField(key: ValueKey('${widget.definition['action']}-$key-${type == 'date' ? _values[key] : ''}'), initialValue: _values[key] as String?, enabled: !_busy,
          minLines: type == 'textarea' ? 3 : 1, maxLines: type == 'textarea' ? 8 : 1,
          keyboardType: type == 'number' ? TextInputType.number : type == 'textarea' ? TextInputType.multiline : TextInputType.text,
          decoration: InputDecoration(labelText: label, hintText: type == 'time' ? 'HH:mm' : type == 'date' ? 'YYYY-MM-DD' : null),
          readOnly: type == 'date', onTap: type == 'date' ? () async {
            final selected = await showDatePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100), initialDate: DateTime.tryParse('${_values[key]}') ?? DateTime.now());
            if (mounted && selected != null) setState(() => _values[key] = selected.toIso8601String().substring(0,10));
          } : null,
          validator: (value) => field['optional'] != true && (value ?? '').trim().isEmpty ? t('هذا الحقل مطلوب', 'This field is required') : null,
          onChanged: (value) => _values[key] = value);
      })),
      if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!)),
      FilledButton(onPressed: _busy ? null : _save, child: Text(_busy ? t('جارِ الحفظ…', 'Saving…') : t('حفظ', 'Save'))),
    ]));
  }
}
