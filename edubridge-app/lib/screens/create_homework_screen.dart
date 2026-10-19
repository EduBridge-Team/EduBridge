// lib/screens/create_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../utils/locale_form_validation.dart';
import '../widgets/disability/disability_display.dart';
import '../utils/safe_bottom.dart';
part 'create_homework_view.dart';

class CreateHomeworkScreen extends StatefulWidget {
  final List children;
  final int? initialChildId;
  final String? initialTitle;
  final String? initialDescription;
  final String? initialSubject;
  final DateTime? initialDueDate;

  const CreateHomeworkScreen({
    super.key,
    required this.children,
    this.initialChildId,
    this.initialTitle,
    this.initialDescription,
    this.initialSubject,
    this.initialDueDate,
  });

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> with LocaleFormValidation<CreateHomeworkScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();

  @override
  GlobalKey<FormState> get validationFormKey => _formKey;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final Set<int> _selectedChildIds = {};
  final List<File> _attachments = [];
  bool _saving = false;
  Object? _error;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.initialTitle?.trim() ?? '';
    _descCtrl.text = widget.initialDescription?.trim() ?? '';
    _subjectCtrl.text = widget.initialSubject?.trim() ?? '';
    _dueDate = widget.initialDueDate ?? DateTime.now().add(const Duration(days: 7));
    if (widget.initialChildId != null) {
      _selectedChildIds.add(widget.initialChildId!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final file = await _picker.pickMedia();
    if (file != null && mounted) {
      setState(() => _attachments.add(File(file.path)));
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    if (!validateLocalizedForm()) return;
    if (_selectedChildIds.isEmpty) {
      setState(() => _error = SharedUiMessage.homeworkChooseStudent);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ApiService.createHomework(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        subject: _subjectCtrl.text.trim().isEmpty
            ? null
            : _subjectCtrl.text.trim(),
        assignedChildIds: _selectedChildIds.toList(),
        attachments: _attachments.isEmpty ? null : _attachments,
      );

      if (!mounted) return;
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.homeworkPublished),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = SharedUiMessage.homeworkPublishFailed;
          _saving = false;
        });
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
