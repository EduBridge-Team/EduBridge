import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';

class EditChildScreen extends StatefulWidget {
  final Map child;
  final String currentUserRole; // 'admin', 'specialist', 'teacher', 'parent'
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
  
  // للمختص فقط
  TextEditingController? _reasonController;

  // للأدمن والمختص
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
    _nameController = TextEditingController(text: widget.child['name']?.toString() ?? '');
    _ageController = TextEditingController(text: widget.child['age']?.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.child['description']?.toString() ?? '');

    if (_isAdmin) {
      // الأدمن يحتاج قائمة المعلمين والمختصين
      _loadTeachers();
      _loadSpecialists();
    } else if (_isSpecialist) {
      // المختص يحتاج قائمة المعلمين فقط، وسبب التغيير
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
        if (data is List) list = data;
        else if (data is Map) list = data['users'] ?? data['data'] ?? [];
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
        if (data is List) list = data;
        else if (data is Map) list = data['users'] ?? data['data'] ?? [];
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
        // الأدمن يرسل المعلم والمختص
        if (_newTeacherId != null) body['teacher_id'] = _newTeacherId;
        if (_newSpecialistId != null) body['specialist_id'] = _newSpecialistId;
      } else if (_isSpecialist) {
        // المختص يرسل المعلم مع ذكر السبب
        if (_newTeacherId != null) {
          body['teacher_id'] = _newTeacherId;
          body['reason'] = _reasonController?.text.trim();
        }
      }

      final res = await ApiService.authPut('/children/${widget.child['id']}', body);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
        );
      } else {
        setState(() {
          _error = data['error']?.toString() ?? 'تعذّر حفظ التعديلات';
        });
      }
    } catch (_) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
      });
    } finally {
      setState(() {
        _loading = false;
      });
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
            // تنبيه لولي الأمر
            if (widget.currentUserRole == 'parent')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tintOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.orangeDeep),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك تعديل البيانات الأساسية فقط. لا يمكنك تغيير المعلّم أو الأخصائي.',
                        style: TextStyle(color: AppColors.orangeDeep, fontWeight: FontWeight.bold),
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
              decoration: const InputDecoration(labelText: 'ملاحظات عامة (اختياري)'),
            ),

            // 📌 للأدمن: تغيير المعلم والمختص
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'إدارة المتابعة (للأدمن)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.heading),
              ),
              const SizedBox(height: 12),

              // قائمة المعلمين
              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المعلم المسؤول'),
                  items: _teachers.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['name']?.toString() ?? ''),
                  )).toList(),
                  onChanged: (v) => _newTeacherId = v,
                ),
              
              const SizedBox(height: 12),

              // قائمة المختصين
              if (_loadingSpecialists)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المختص المسؤول'),
                  items: _specialists.map((s) => DropdownMenuItem(
                    value: s['id'].toString(),
                    child: Text(s['name']?.toString() ?? ''),
                  )).toList(),
                  onChanged: (v) => _newSpecialistId = v,
                ),
            ],

            // 📌 للمختص: تغيير المعلم مع ذكر الأسباب
            if (_isSpecialist) ...[
              const SizedBox(height: 20),
              Divider(color: c.line),
              const SizedBox(height: 16),
              Text(
                'تغيير المعلم (للمختص)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: c.heading),
              ),
              const SizedBox(height: 8),
              if (_loadingTeachers)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'المعلم الجديد'),
                  items: _teachers.map((t) => DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['name']?.toString() ?? ''),
                  )).toList(),
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
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_loading ? 'جارِ الحفظ...' : 'حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}