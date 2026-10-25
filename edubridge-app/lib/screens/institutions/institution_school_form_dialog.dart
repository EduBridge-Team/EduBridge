import 'package:flutter/material.dart';

/// Collects validated school fields; persistence belongs to the caller.
class InstitutionSchoolFormDialog extends StatefulWidget {
  const InstitutionSchoolFormDialog({super.key, this.school});

  final Map<String, dynamic>? school;

  static Future<Map<String, String>?> show(
    BuildContext context, {
    Map<String, dynamic>? school,
  }) => showDialog<Map<String, String>>(
    context: context,
    builder: (_) => InstitutionSchoolFormDialog(school: school),
  );

  @override
  State<InstitutionSchoolFormDialog> createState() =>
      _InstitutionSchoolFormDialogState();
}

class _InstitutionSchoolFormDialogState
    extends State<InstitutionSchoolFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: '${widget.school?['name'] ?? ''}',
  );
  final _slug = TextEditingController();
  late final _address = TextEditingController(
    text: '${widget.school?['address'] ?? ''}',
  );
  late final _phone = TextEditingController(
    text: '${widget.school?['phone'] ?? ''}',
  );

  bool get _editing => widget.school != null;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _label(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, <String, String>{
      'name': _name.text.trim(),
      if (_editing) ...{
        'address': _address.text.trim(),
        'phone': _phone.text.trim(),
      } else
        'slug': _slug.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      _editing
          ? _label('تعديل بيانات المدرسة', 'Edit school details')
          : _label('إضافة مدرسة', 'Add school'),
    ),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              maxLength: _editing ? 150 : null,
              decoration: InputDecoration(
                labelText: _label('اسم المدرسة', 'School name'),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? _label(
                      _editing ? 'اسم المدرسة مطلوب' : 'الاسم مطلوب',
                      'School name is required',
                    )
                  : null,
            ),
            if (_editing) ...[
              TextFormField(
                controller: _address,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: _label('العنوان', 'Address'),
                ),
              ),
              TextFormField(
                controller: _phone,
                maxLength: 30,
                decoration: InputDecoration(
                  labelText: _label('الهاتف', 'Phone'),
                ),
              ),
            ] else
              TextFormField(
                controller: _slug,
                decoration: InputDecoration(
                  labelText: _label(
                    'معرف المدرسة بالإنجليزية',
                    'School ID in English',
                  ),
                ),
                validator: (value) =>
                    RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(value ?? '')
                    ? null
                    : _label(
                        'استخدم حروفًا صغيرة وأرقامًا وشرطة فقط',
                        'Use lowercase letters, numbers and hyphens only',
                      ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(_label('إلغاء', 'Cancel')),
      ),
      FilledButton(
        onPressed: _submit,
        child: Text(_editing ? _label('حفظ', 'Save') : _label('إضافة', 'Add')),
      ),
    ],
  );
}
