// lib/screens/add_certificate_sheet.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';

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
        const SnackBar(
          content: Text('تم إضافة الشهادة بنجاح'),
          backgroundColor: AppColors.green,
        ),
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
    final bottom = safeModalBottom(context);

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
                  const Icon(AppIcons.certificate,
                      color: AppColors.orange, size: 26),
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
                    icon: const Icon(AppIcons.close),
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
                  prefixIcon: Icon(AppIcons.edit),
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
                    Row(
                      children: [
                        const Icon(AppIcons.attach,
                            size: 20, color: AppColors.greenDeep),
                        const SizedBox(width: 6),
                        Text(
                          'ملف الشهادة (اختياري صورة أو PDF)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: c.onTint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_file == null)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(AppIcons.upload),
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
                          Icon(AppIcons.check, color: c.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _file!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: c.onTint,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            icon: Icon(AppIcons.close, color: c.onTint),
                            onPressed: () => setState(() => _file = null),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(AppIcons.error,
                          color: AppColors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(color: AppColors.red)),
                      ),
                    ],
                  ),
                ),
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
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(AppIcons.save),
                      onPressed: _saving ? null : _save,
                      label: Text(_saving ? 'جارِ الحفظ...' : 'حفظ الشهادة'),
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