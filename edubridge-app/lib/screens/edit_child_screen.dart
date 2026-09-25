// lib/screens/edit_child_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Scaffold(
      appBar: JisrAppBar(title: 'تعديل بيانات الطفل'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.currentUserRole == 'parent')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.info,
                        color: AppColors.orangeDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك تعديل البيانات الأساسية فقط. لا يمكنك تغيير المعلّم أو الأخصائي.',
                        style: TextStyle(
                            color: c.onTint,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'اسم الطفل'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'العمر'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: 'ملاحظات عامة (اختياري)'),
            ),

            if (_isAdmin) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'إدارة المتابعة (للأدمن)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.heading),
              ),
              const SizedBox(height: 12),

              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'المعلم المسؤول'),
                  items: _teachers
                      .map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text(t['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newTeacherId = v,
                ),

              const SizedBox(height: 12),

              if (_loadingSpecialists)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'المختص المسؤول'),
                  items: _specialists
                      .map((s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newSpecialistId = v,
                ),
            ],

            if (_isSpecialist) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'تغيير المعلم (للمختص)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.heading),
              ),
              const SizedBox(height: 8),
              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المعلم الجديد'),
                  items: _teachers
                      .map((t) => DropdownMenuItem(
                            value: t['id'].toString(),
                            child: Text(t['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => _newTeacherId = v,
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'أسباب التغيير',
                  hintText: 'اكتب سبب تغيير المعلم هنا...',
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.error,
                        color: AppColors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(AppIcons.save),
              label: Text(_loading ? 'جارِ الحفظ...' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}