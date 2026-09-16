// screens/homework/create_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../utils/safe_bottom.dart';

class CreateHomeworkScreen extends StatefulWidget {
  final List children;

  const CreateHomeworkScreen({super.key, required this.children});

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final Set<int> _selectedChildIds = {};
  final List<File> _attachments = [];
  bool _saving = false;
  String? _error;

  final _picker = ImagePicker();

  Future<void> _pickAttachment() async {
    final file = await _picker.pickMedia();
    if (file != null) {
      setState(() => _attachments.add(File(file.path)));
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChildIds.isEmpty) {
      setState(() => _error = 'اختر طالباً واحداً على الأقل');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ApiService.createHomework(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        subject: _subjectCtrl.text.trim().isEmpty
            ? null
            : _subjectCtrl.text.trim(),
        assignedChildIds: _selectedChildIds.toList(),
        attachments: _attachments.isEmpty ? null : _attachments,
      );

      if (!mounted) return;
      if (result != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إنشاء الواجب بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: '📝 واجب جديد'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + safeModalBottom(context),
          ),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان الواجب *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'الوصف *',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'الوصف مطلوب' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'المادة (اختياري)',
                prefixIcon: Icon(Icons.book),
                hintText: 'مثال: رياضيات',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDueDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'موعد التسليم',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'تعيين لطلاب (${_selectedChildIds.length} محدد):',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.children.map((child) {
              final id = child['id'] as int;
              final name = child['name']?.toString() ?? '';
              final selected = _selectedChildIds.contains(id);
              return CheckboxListTile(
                value: selected,
                title: Text(name),
                subtitle: Text(child['disability_type']?.toString() ?? ''),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedChildIds.add(id);
                    } else {
                      _selectedChildIds.remove(id);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('إضافة مرفق'),
                    onPressed: _pickAttachment,
                  ),
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._attachments.asMap().entries.map((e) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(e.value.path.split('/').last),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () =>
                          setState(() => _attachments.removeAt(e.key)),
                    ),
                  )),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'جارِ الحفظ...' : 'حفظ الواجب'),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}