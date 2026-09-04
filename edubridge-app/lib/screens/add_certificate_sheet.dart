// نموذج إضافة شهادة (إثبات أهلية) – للمعلم/المختص
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme.dart';

class AddCertificateSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const AddCertificateSheet({super.key, required this.onSaved});

  @override
  State<AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<AddCertificateSheet> {
  final _titleCtrl = TextEditingController();
  File? _file;
  bool _saving = false;
  String? _error;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    // نستخدم pickMedia لالتقاط أي ملف (صورة أو PDF)
    final XFile? file = await _picker.pickMedia();
    if (file != null) {
      setState(() => _file = File(file.path));
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الشهادة مطلوب');
      return;
    }
    if (_file == null) {
      setState(() => _error = 'ملف الشهادة مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.submitCertificate(
        title: _titleCtrl.text.trim(),
        file: _file!,
      );
      if (!mounted) return;
      widget.onSaved();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الشهادة بنجاح')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium, color: AppColors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إضافة شهادة (إثبات أهلية)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الشهادة',
                  hintText: 'مثال: بكالوريوس تربية خاصة',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملف الشهادة (اختياري صورة أو PDF)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: c.onTint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_file == null)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('اختر ملف الشهادة'),
                          onPressed: _pickFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: c.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _file!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.onTint, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: c.onTint),
                            onPressed: () => setState(() => _file = null),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                      ),
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'جارِ الحفظ...' : 'حفظ الشهادة'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}