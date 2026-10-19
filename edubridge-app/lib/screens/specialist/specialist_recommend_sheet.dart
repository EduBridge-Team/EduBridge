// lib/screens/specialist/specialist_recommend_sheet.dart
part of 'specialist_screen.dart';

class _RecommendLearningSupportSheet extends StatefulWidget {
  final Map child;
  const _RecommendLearningSupportSheet({required this.child, this.figmaS23 = false});
  final bool figmaS23;

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
  Object? _error;

  Map<String, String> get _reasons => {
    'صعوبة في فهم الدروس': context.l10n.reasonUnderstandingLessons,
    'الحاجة إلى تكييف أسلوب التعلم': context.l10n.reasonLearningAdaptation,
    'صعوبة في التركيز أثناء الأنشطة التعليمية': context.l10n.reasonLearningFocus,
    'الحاجة إلى متابعة الواجبات': context.l10n.reasonHomeworkFollowUp,
    'صعوبة في التواصل داخل البيئة التعليمية': context.l10n.reasonLearningCommunication,
    'الحاجة إلى خطة تعلم فردية': context.l10n.reasonIndividualPlan,
    'الحاجة إلى متابعة تقدم أكاديمي': context.l10n.reasonAcademicFollowUp,
    'أخرى': context.l10n.otherDisability,
  };

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reason == null) {
      setState(() => _error = SharedUiMessage.chooseRecommendationReason);
      return;
    }
    if (_descCtrl.text.trim().length < 15) {
      setState(() => _error = SharedUiMessage.recommendationDescriptionMinimum);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ApiService.authPost('/learning-support/recommendations', {
        'child_id': widget.child['id'],
        'reason': _reason,
        'description': _descCtrl.text.trim(),
        'urgency': _urgency,
      });
      if (!mounted) return;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        setState(() {
          _error = SharedUiMessage.recommendationSendFailed;
          _saving = false;
        });
        return;
      }
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.recommendationSentToParent),
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

  Widget _buildS23() {
    const blue = Color(0xFF196BC7);
    const ink = Color(0xFF102F4C);
    final childName = (widget.child['name'] ?? '').toString();
    InputDecoration fieldDecoration(String hint, {bool multiline = false}) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF728AA0), fontSize: 14),
        prefixIcon: multiline ? null : const Icon(Icons.edit_outlined, color: blue, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD6E6F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      );
    }

    return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight: MediaQuery.sizeOf(context).height * 0.84,
          ),
          child: SingleChildScrollView(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.supportRecommendationFor(childName),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800, color: ink),
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Icon(Icons.lightbulb_outline_rounded, size: 23, color: blue),
                  ],
                ),
                const SizedBox(height: 17),
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      key: const ValueKey('s23_reason'),
                      initialValue: _reason,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: blue),
                      hint: Text(context.l10n.requiredFieldLabel(context.l10n.recommendationReason),
                          style: TextStyle(color: Color(0xFF728AA0), fontSize: 14)),
                      decoration: fieldDecoration('', multiline: false),
                      items: _reasons.entries.map((reason) => DropdownMenuItem(
                        value: reason.key,
                        child: Text(reason.value, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: _saving ? null : (value) => setState(() => _reason = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('s23_description'),
                      controller: _descCtrl,
                      enabled: !_saving,
                      minLines: 4,
                      maxLines: 4,
                      maxLength: 500,

                      textAlign: TextAlign.start,
                      decoration: fieldDecoration(context.l10n.requiredFieldLabel(context.l10n.detailedExplanation), multiline: true)
                          .copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _s23Urgency(context.l10n.normalUrgency, 'low')),
                        const SizedBox(width: 6),
                        Expanded(child: _s23Urgency(context.l10n.mediumUrgency, 'medium')),
                        const SizedBox(width: 6),
                        Expanded(child: _s23Urgency(context.l10n.urgentUrgency, 'high')),
                      ],
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 9),
                  Text(context.sharedMessage(_error), textAlign: TextAlign.start,
                    style: const TextStyle(color: AppColors.red, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 35),
                        child: OutlinedButton(
                          key: const ValueKey('s23_cancel'),
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFE6F1FD),
                            foregroundColor: blue,
                            side: const BorderSide(color: blue),
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 35),
                        child: FilledButton(
                          key: const ValueKey('s23_send'),
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: const StadiumBorder(),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 17, width: 17,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                              : Text(context.l10n.sendToParent,
                                  style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ),
    );
  }

  Widget _s23Urgency(String label, String value) {
    const blue = Color(0xFF196BC7);
    final selected = _urgency == value;
    return OutlinedButton(
      key: ValueKey('s23_urgency_$value'),
      onPressed: _saving ? null : () => setState(() => _urgency = value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? blue : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF526B84),
        side: BorderSide(color: selected ? blue : const Color(0xFFD6E6F2)),
        shape: const StadiumBorder(),
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 43),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.figmaS23) return _buildS23();
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
                  const Icon(AppIcons.specialist, color: AppColors.brandBlueLight, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.supportRecommendationFor((widget.child['name'] ?? '').toString()),
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
                isExpanded: true,
                initialValue: _reason,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.recommendationReason),
                  prefixIcon: Icon(AppIcons.warning),
                ),
                items: _reasons.entries
                    .map((r) => DropdownMenuItem(value: r.key, child: Text(r.value)))
                    .toList(),
                onChanged: (v) => setState(() => _reason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: context.l10n.requiredFieldLabel(context.l10n.detailedExplanation),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(AppIcons.edit),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _urgencyChip(context.l10n.lowUrgency, 'low', AppColors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _urgencyChip(context.l10n.mediumUrgency, 'medium', AppColors.orange)),
                  const SizedBox(width: 8),
                  Expanded(child: _urgencyChip(context.l10n.urgentUrgency, 'high', AppColors.red)),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(context.sharedMessage(_error), style: const TextStyle(color: AppColors.red)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlueLight,
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
                      label: Text(_saving ? '...' : context.l10n.sendToParent,
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