// نموذج طلب دراسة حالة مع مختص – لولي الأمر أو المعلم
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ConsultationRequestSheet extends StatefulWidget {
  final List children; // قائمة الأطفال المتاحة للمستخدم
  const ConsultationRequestSheet({super.key, required this.children});

  @override
  State<ConsultationRequestSheet> createState() =>
      _ConsultationRequestSheetState();
}

class _ConsultationRequestSheetState extends State<ConsultationRequestSheet> {
  int? _childId;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (_childId == null) {
      setState(() => _error = 'يرجى اختيار الطفل');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = 'عنوان الحالة مطلوب');
      return;
    }
    if (_descCtrl.text.trim().isEmpty) {
      setState(() => _error = 'وصف الحالة مطلوب');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.requestConsultation(
        childId: _childId!, 
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلب الدراسة بنجاح')),
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
                  const Icon(Icons.psychology, color: AppColors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'طلب دراسة حالة مع مختص',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'الطفل',
                  prefixIcon: Icon(Icons.child_care),
                ),
                items: widget.children
                    .map((child) => DropdownMenuItem<int>(
                          value: int.parse(
                              child['id'].toString()), // تحويل النوع إلى int
                          child: Text(child['name'] ?? ''),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _childId = val),
                // إذا كان لديك قيمة مبدئية، ضعها هنا:
                initialValue: _childId, // أو value: _childId حسب إصدار Flutter
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الحالة',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'مثال: صعوبة في التركيز',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'وصف الحالة',
                  alignLabelWithHint: true,
                  hintText: 'اكتب تفاصيل الحالة التي تريد دراستها...',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                  ),
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('إرسال الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
