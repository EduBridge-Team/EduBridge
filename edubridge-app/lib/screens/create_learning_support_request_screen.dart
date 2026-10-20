// lib/screens/create_learning_support_request_screen.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/learning_support_presentation.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/locale_form_validation.dart';
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
    extends State<CreateLearningSupportRequestScreen>
    with LocaleFormValidation<CreateLearningSupportRequestScreen> {
  @override
  GlobalKey<FormState> get validationFormKey => _formKey;
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();

  String? _selectedReason;
  String _urgency = 'medium';
  bool _saving = false;
  LearningSupportError? _error;

  static const _reasons = LearningSupportPresentation.reasons;

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!validateLocalizedForm()) return;
    if (_selectedReason == null) {
      setState(() => _error = LearningSupportError.reasonRequired);
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
        final messenger = ScaffoldMessenger.of(context);
        final message = context.l10n.supportRequestSent;
        Navigator.pop(context, true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.green,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        setState(() => _error = LearningSupportError.createFailed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = LearningSupportError.createFailed;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
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
