// lib/screens/create_learning_support_request_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class CreateLearningSupportRequestScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CreateLearningSupportRequestScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CreateLearningSupportRequestScreen> createState() =>
      _CreateLearningSupportRequestScreenState();
}

class _CreateLearningSupportRequestScreenState
    extends State<CreateLearningSupportRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  String? _selectedReason;
  String _urgency = 'medium';
  bool _saving = false;
  String? _error;

  // ✅ الأسباب الجاهزة
  static const _reasons = [
    'صعوبة في فهم الدروس',
    'تراجع في التقدم الدراسي',
    'صعوبة في التركيز أثناء التعلم',
    'الحاجة إلى تكييف طريقة عرض المحتوى',
    'صعوبة في التواصل داخل البيئة التعليمية',
    'الحاجة إلى خطة متابعة فردية',
    'صعوبة في إنجاز الواجبات',
    'الحاجة إلى دعم في مهارات الدراسة',
    'التنسيق بين الأسرة والفريق التعليمي',
    'أخرى',
  ];

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedReason == null) {
      setState(() => _error = 'اختر السبب الرئيسي');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ApiService.createLearningSupportRequest(
        childId: widget.childId,
        reason: _selectedReason!,
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        urgency: _urgency,
      );

      if (!mounted) return;
      if (result != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم إرسال الطلب للمختص — سيصلك إشعار بالموعد'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
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
      appBar: JisrAppBar(title: '📘 طلب دعم تعليمي'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── رأس توضيحي ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.tintTeal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      color: AppColors.tealDeep, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'طلب دعم تعليمي',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: c.heading,
                          ),
                        ),
                        Text(
                          'سيصل طلبك لمختص الدعم التعليمي المتابع لـ ${widget.childName}',
                          style: TextStyle(fontSize: 13, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── السبب الرئيسي ───
            Text(
              'السبب الرئيسي *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.line, width: 2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  hint: const Text('اختر السبب...'),
                  items: _reasons
                      .map((r) =>
                          DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ─── الشرح ───
            Text(
              'اشرح نوع الدعم التعليمي المطلوب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText:
                    'اشرح الصعوبة التعليمية، متى تظهر، وما الذي يساعد الطفل أثناء التعلم...',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.description),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'الرجاء كتابة شرح موجز';
                }
                if (v.trim().length < 20) {
                  return 'الشرح قصير — اكتب 20 حرفاً على الأقل';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ─── درجة الأهمية ───
            Text(
              'أولوية المتابعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: c.heading,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _UrgencyChip(
                    label: '🟢 مرنة',
                    selected: _urgency == 'low',
                    color: AppColors.green,
                    onTap: () => setState(() => _urgency = 'low'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UrgencyChip(
                    label: '🟡 عادية',
                    selected: _urgency == 'medium',
                    color: AppColors.orange,
                    onTap: () => setState(() => _urgency = 'medium'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _UrgencyChip(
                    label: '🟠 مرتفعة',
                    selected: _urgency == 'high',
                    color: AppColors.red,
                    onTap: () => setState(() => _urgency = 'high'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── ملاحظة ───
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.tintYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.orangeDeep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيقوم المختص بمراجعة الطلب وتحديد الموعد المناسب، ثم سيصلك إشعار برابط الاجتماع.',
                      style: TextStyle(fontSize: 13, color: c.onTint),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _saving ? 'جارِ الإرسال...' : 'إرسال طلب الدعم',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _UrgencyChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: selected ? color : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}