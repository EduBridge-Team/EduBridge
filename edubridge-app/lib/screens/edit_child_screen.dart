// lib/screens/edit_child_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
part 'edit_child_view.dart';

class EditChildScreen extends StatefulWidget {
  final Map child;
  final String currentUserRole;
  final Map currentUser;

  const EditChildScreen({
    super.key,
    required this.child,
    required this.currentUserRole,
    required this.currentUser,
  });

  @override
  State<EditChildScreen> createState() => _EditChildScreenState();
}

class _EditChildScreenState extends State<EditChildScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _descriptionController;

  TextEditingController? _reasonController;

  String? _newTeacherId;
  String? _newSpecialistId;

  List<Map<String, dynamic>> _teachers = [];
  List<Map<String, dynamic>> _specialists = [];
  bool _loadingTeachers = false;
  bool _loadingSpecialists = false;

  bool _loading = false;
  String? _error;

  bool get _isAdmin => widget.currentUserRole == 'admin';
  bool get _isSpecialist => widget.currentUserRole == 'specialist';

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.child['name']?.toString() ?? '');
    _ageController =
        TextEditingController(text: widget.child['age']?.toString() ?? '');
    _descriptionController = TextEditingController(
        text: widget.child['description']?.toString() ?? '');

    if (_isAdmin) {
      _loadTeachers();
      _loadSpecialists();
    } else if (_isSpecialist) {
      _reasonController = TextEditingController();
      _loadTeachers();
    }
  }

  Future<void> _loadTeachers() async {
    setState(() => _loadingTeachers = true);
    try {
      final res = await ApiService.authGet('/users?role=teacher');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        List list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['users'] ?? data['data'] ?? [];
        }
        setState(() => _teachers = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {} finally {
      setState(() => _loadingTeachers = false);
    }
  }

  Future<void> _loadSpecialists() async {
    setState(() => _loadingSpecialists = true);
    try {
      final res = await ApiService.authGet('/users?role=specialist');
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        List list = [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = data['users'] ?? data['data'] ?? [];
        }
        setState(() => _specialists = list.cast<Map<String, dynamic>>());
      }
    } catch (_) {} finally {
      setState(() => _loadingSpecialists = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _descriptionController.dispose();
    _reasonController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> body = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'description': _descriptionController.text.trim(),
      };

      if (_isAdmin) {
        if (_newTeacherId != null) body['teacher_id'] = _newTeacherId;
        if (_newSpecialistId != null) body['specialist_id'] = _newSpecialistId;
      } else if (_isSpecialist) {
        if (_newTeacherId != null) {
          body['teacher_id'] = _newTeacherId;
          body['reason'] = _reasonController?.text.trim();
        }
      }

      final res =
          await ApiService.authPut('/children/${widget.child['id']}', body);
      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (res.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر حفظ التعديلات';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'تعذّر الاتصال بالسيرفر';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}