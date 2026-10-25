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
  Object? _error;

  String get _label =>
      widget.specialty == 'learning_support' ? context.l10n.learningSupportSpecialist : context.l10n.educationalSpecialist;

  Color get _color =>
      widget.specialty == 'learning_support' ? AppColors.brandTealDeep : AppColors.brandBlue;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedId == null) {
      setState(() => _error = SharedUiMessage.chooseSpecialist);
      return;
    }
    if (_reasonCtrl.text.trim().length < 10) {
      setState(() => _error = SharedUiMessage.recommendationReasonMinimum);
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
        content: Text(context.l10n.specialistRecommendationSent(_label)),
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

    return Dialog(
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
          child: SingleChildScrollView(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: Text(context.l10n.recommendSupportSpecialist,
                      style: TextStyle(
                        color: ink, fontSize: 20, fontWeight: FontWeight.w800))),
                    SizedBox(width: 10),
                    Icon(Icons.lightbulb_outline_rounded,
                      color: blue, size: 23),
                  ],
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    if (filtered.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(context.l10n.noAvailableSpecialists),
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
                              Padding(
                                padding: const EdgeInsets.only(bottom: 9),
                                child: Material(
                                  color: pale,
                                  borderRadius: BorderRadius.circular(19),
                                  clipBehavior: Clip.antiAlias,
                                  child: RadioListTile<int>(
                                  key: ValueKey('s22_specialist_${person['id']}'),
                                  value: person['id'] as int,
                                  activeColor: blue,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                  dense: true,
                                  title: Text(
                                    (person['name'] ?? '').toString(),
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                      color: ink, fontSize: 15)),
                                  ),
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

                      textAlign: TextAlign.start,
                      decoration: InputDecoration(
                        hintText: context.l10n.requiredFieldLabel(context.l10n.recommendationReason),
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
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(context.sharedMessage(_error), textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: AppColors.red, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 34),
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
                          child: Text(context.l10n.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 34),
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
                              : Text(context.l10n.sendRecommendation,
                                  style: TextStyle(fontSize: 12)),
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
                    child: Text(context.l10n.suggestSpecialistTitle(_label),
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
                        context.l10n.specialistFollowUpNotification((widget.child['name'] ?? '').toString()),
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
                  child: Text(context.l10n.noAvailableSpecialists,
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
                  labelText: context.l10n.requiredFieldLabel(context.l10n.recommendationReason),
                  alignLabelWithHint: true,
                  hintText: context.l10n.whyRecommendSpecialist,
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
                  child: Text(context.sharedMessage(_error), style: const TextStyle(color: AppColors.red)),
                ),
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
                      label: Text(_saving ? '...' : context.l10n.sendRecommendation,
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
/// Open the existing S22 specialist recommendation from a child's own file.
/// This deliberately reuses the established API-backed dialog and validation,
/// rather than adding an unrelated dashboard quick action.
Future<bool> showChildSpecialistSuggestion(
  BuildContext context, {
  required Map<String, dynamic> child,
}) async {
  if (!await ApiService.isVerified()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.verifyIdentityFirst)),
      );
    }
    return false;
  }

  try {
    final specialists = await ApiService.getUsers(role: 'specialist');
    if (!context.mounted) return false;
    final selected = await showDialog<bool>(
      context: context,
      builder: (_) => _SuggestSpecialistSheet(
        child: child,
        specialists: specialists,
        specialty: 'learning_support',
        figmaS22: true,
      ),
    );
    return selected == true;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.specialistsLoadFailed)),
      );
    }
    return false;
  }
}
