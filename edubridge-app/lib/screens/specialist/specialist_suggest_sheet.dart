// lib/screens/specialist/specialist_suggest_sheet.dart
part of 'specialist_screen.dart';

class _SuggestSpecialistSheet extends StatefulWidget {
  final Map child;
  final List specialists;
  final String specialty;

  final bool figmaS22;

  const _SuggestSpecialistSheet({
    this.figmaS22 = false,
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

  Widget _buildS22() {
    const blue = Color(0xFF196BC7);
    const ink = Color(0xFF102F4C);
    const pale = Color(0xFFF0F5FA);
    final filtered = widget.specialists.where((s) {
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      return spec.isEmpty || spec == widget.specialty ||
          spec.contains(widget.specialty == 'learning_support' ? 'نفس' : 'تعليم');
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('اقتراح مختص دعم تعليمي',
                      style: TextStyle(
                        color: ink, fontSize: 20, fontWeight: FontWeight.w800)),
                    SizedBox(width: 10),
                    Icon(Icons.lightbulb_outline_rounded,
                      color: blue, size: 23),
                  ],
                ),
                const SizedBox(height: 15),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('لا يوجد مختصون متاحون'),
                          )
                        else
                          RadioGroup<int>(
                            groupValue: _selectedId,
                            onChanged: (v) {
                              if (_saving) return;
                              setState(() => _selectedId = v);
                            },
                            child: Column(
                              children: [
                                for (final person in filtered) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 9),
                                    decoration: BoxDecoration(
                                      color: pale,
                                      borderRadius: BorderRadius.circular(19),
                                    ),
                                    child: RadioListTile<int>(
                                      key: ValueKey('s22_specialist_${person['id']}'),
                                      value: person['id'] as int,
                                      activeColor: blue,
                                      controlAffinity:
                                          ListTileControlAffinity.trailing,
                                      dense: true,
                                      title: Text(
                                        (person['name'] ?? '').toString(),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: ink, fontSize: 15)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 3),
                        TextField(
                          key: const ValueKey('s22_reason'),
                          controller: _reasonCtrl,
                          enabled: !_saving,
                          maxLength: 300,
                          minLines: 3,
                          maxLines: 3,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'سبب التوصية *',
                            hintStyle: const TextStyle(
                              color: Color(0xFF728AA0), fontSize: 14),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFD6E6F2))),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                color: Color(0xFFD6E6F2))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.red, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: _saving ? null :
                              () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE6F1FD),
                            foregroundColor: blue,
                            side: const BorderSide(color: blue),
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 17, height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                              : const Text('إرسال التوصية',
                                  maxLines: 1,
                                  style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.figmaS22) return _buildS22();
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