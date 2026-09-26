// lib/screens/create_homework_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/safe_bottom.dart';
part 'create_homework_view.dart';

class CreateHomeworkScreen extends StatefulWidget {
  final List children;

  const CreateHomeworkScreen({super.key, required this.children});

  @override
  State<CreateHomeworkScreen> createState() => _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends State<CreateHomeworkScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  final Set<int> _selectedChildIds = {};
  final List<File> _attachments = [];
  bool _saving = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final file = await _picker.pickMedia();
    if (file != null) {
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
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedChildIds.isEmpty) {
      setState(() => _error = 'اختر طالباً واحداً على الأقل');
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
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء الواجب بنجاح'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}