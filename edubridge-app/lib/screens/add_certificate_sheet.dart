import '../l10n/l10n.dart';

// lib/screens/add_certificate_sheet.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/api_service.dart';
import '../theme.dart';
import 'certificates/certificate_submission_form.dart';
import 'certificates/specialist_certificate_dialog.dart';

class AddCertificateSheet extends StatefulWidget {
  final VoidCallback onSaved;

  /// Specialist-only Figma S18 centered modal. Other roles keep their sheet.
  final bool figmaS18;

  const AddCertificateSheet({
    super.key,
    required this.onSaved,
    this.figmaS18 = false,
  });

  @override
  State<AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<AddCertificateSheet> {
  final _titleCtrl = TextEditingController();
  File? _file;
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final path = result?.files.single.path;
    if (path != null && mounted) {
      setState(() {
        _file = File(path);
        _error = null;
      });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _error = SharedUiMessage.certificateTitleRequired);
      return;
    }
    if (_file == null) {
      setState(() => _error = SharedUiMessage.certificateFileRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ApiService.submitCertificate(
        title: _titleCtrl.text.trim(),
        file: _file!,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      widget.onSaved();
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.certificateSubmitted),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _file?.path.split('/').last;
    if (widget.figmaS18) {
      return SpecialistCertificateDialog(
        titleController: _titleCtrl,
        fileName: fileName,
        saving: _saving,
        error: _error,
        onPickFile: _pickFile,
        onRemoveFile: () => setState(() => _file = null),
        onSave: _save,
      );
    }
    return CertificateSubmissionForm(
      titleController: _titleCtrl,
      fileName: fileName,
      saving: _saving,
      error: _error,
      onPickFile: _pickFile,
      onRemoveFile: () => setState(() => _file = null),
      onSave: _save,
    );
  }
}
