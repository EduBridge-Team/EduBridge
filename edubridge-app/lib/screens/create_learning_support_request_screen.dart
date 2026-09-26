// lib/screens/create_learning_support_request_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
part 'create_learning_support_request_view.dart';

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
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  String? _selectedReason;
  String _urgency = 'medium';
  bool _saving = false;
  String? _error;

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
            content: Text('تم إرسال الطلب للمختص — سيصلك إشعار بالموعد'),
            backgroundColor: AppColors.green,
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
  Widget build(BuildContext context) => buildView(context);
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