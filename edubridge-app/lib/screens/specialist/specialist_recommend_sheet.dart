// lib/screens/specialist/specialist_recommend_sheet.dart
part of 'specialist_screen.dart';

class _RecommendLearningSupportSheet extends StatefulWidget {
  final Map child;
  const _RecommendLearningSupportSheet({required this.child});

  @override
  State<_RecommendLearningSupportSheet> createState() =>
      _RecommendLearningSupportSheetState();
}

class _RecommendLearningSupportSheetState
    extends State<_RecommendLearningSupportSheet> {
  final _descCtrl = TextEditingController();
  String? _reason;
  String _urgency = 'medium';
  bool _saving = false;
  String? _error;

  static const _reasons = [
    'صعوبة في فهم الدروس',
    'الحاجة إلى تكييف أسلوب التعلم',
    'صعوبة في التركيز أثناء الأنشطة التعليمية',
    'الحاجة إلى متابعة الواجبات',
    'صعوبة في التواصل داخل البيئة التعليمية',
    'الحاجة إلى خطة تعلم فردية',
    'الحاجة إلى متابعة تقدم أكاديمي',
    'أخرى',
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reason == null) {
      setState(() => _error = 'اختر سبب التوصية');
      return;
    }
    if (_descCtrl.text.trim().length < 15) {
      setState(() => _error = 'اكتب شرحاً (15 حرفاً على الأقل)');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiService.authPost('/learning-support/recommendations', {
        'child_id': widget.child['id'],
        'reason': _reason,
        'description': _descCtrl.text.trim(),
        'urgency': _urgency,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال التوصية لولي الأمر'),
          backgroundColor: AppColors.brandTealDeep,
        ),
      );
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
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                  const Icon(AppIcons.specialist, color: AppColors.brandTealDeep, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اقتراح دعم تعليمي — ${widget.child['name']}',
                      style: TextStyle(
                        fontSize: 17,
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: const InputDecoration(
                  labelText: 'سبب التوصية *',
                  prefixIcon: Icon(AppIcons.warning),
                ),
                items: _reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'شرح مفصّل *',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(AppIcons.edit),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _urgencyChip('منخفضة', 'low', AppColors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _urgencyChip('متوسطة', 'medium', AppColors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _urgencyChip('عاجلة', 'high', AppColors.red)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.red)),
              ],
              const SizedBox(height: 16),
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
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandTealDeep,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(AppIcons.send),
                      label: Text(_saving ? '...' : 'إرسال لولي الأمر',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _urgencyChip(String label, String value, Color color) {
    final selected = _urgency == value;
    return GestureDetector(
      onTap: () => setState(() => _urgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? color : Colors.grey.shade600,
            )),
      ),
    );
  }
}