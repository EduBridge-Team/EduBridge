// lib/screens/specialist/specialist_suggest_sheet.dart
part of 'specialist_screen.dart';

class _SuggestSpecialistSheet extends StatefulWidget {
  final Map child;
  final List specialists;
  final String specialty;

  const _SuggestSpecialistSheet({
    required this.child,
    required this.specialists,
    required this.specialty,
  });

  @override
  State<_SuggestSpecialistSheet> createState() =>
      _SuggestSpecialistSheetState();
}

class _SuggestSpecialistSheetState extends State<_SuggestSpecialistSheet> {
  int? _selectedId;
  final _reasonCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  String get _label =>
      widget.specialty == 'learning_support' ? 'مختص دعم تعليمي' : 'مختص تعليمي';

  Color get _color =>
      widget.specialty == 'learning_support' ? AppColors.brandTealDeep : AppColors.brandBlue;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedId == null) {
      setState(() => _error = 'اختر مختصاً');
      return;
    }
    if (_reasonCtrl.text.trim().length < 10) {
      setState(() => _error = 'اكتب سبب التوصية (10 أحرف على الأقل)');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await ApiService.suggestSpecialistToChild(
      childId: widget.child['id'],
      specialistId: _selectedId!,
      specialty: widget.specialty,
      reason: _reasonCtrl.text.trim(),
    );

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _error = err;
        _saving = false;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم إرسال التوصية لـ$_label'),
        backgroundColor: AppColors.brandTealDeep,
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    final filtered = widget.specialists.where((s) {
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec.isEmpty) return true;
      return spec == widget.specialty ||
          spec.contains(widget.specialty == 'learning_support' ? 'نفس' : 'تعليم');
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  Icon(AppIcons.specialist, color: _color, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('اقتراح $_label',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        )),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(AppIcons.info, color: _color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيُرسَل إشعار للمختص المقترح لمتابعة ${widget.child['name']}.',
                        style: TextStyle(fontSize: 12, color: c.onTint, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Text('لا يوجد مختصون متاحون',
                      style: TextStyle(color: c.muted), textAlign: TextAlign.center),
                )
              else
                RadioGroup<int>(
                  groupValue: _selectedId,
                  onChanged: (v) => setState(() => _selectedId = v),
                  child: Column(
                    children: filtered.map<Widget>((s) {
                      final id = s['id'] as int;
                      return RadioListTile<int>(
                        value: id,
                        activeColor: _color,
                        title: Text(s['name']?.toString() ?? ''),
                        subtitle: Text(s['email']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonCtrl,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'سبب التوصية *',
                  alignLabelWithHint: true,
                  hintText: 'لماذا ترشح هذا المختص؟',
                  prefixIcon: const Icon(AppIcons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.red)),
                ),
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
                        backgroundColor: _color,
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
                      label: Text(_saving ? '...' : 'إرسال التوصية',
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
}