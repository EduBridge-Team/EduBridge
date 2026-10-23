import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Institution-scoped operations. The API validates active organization
/// membership for every request; a slug never grants access by itself.
class InstitutionOperationsScreen extends StatefulWidget {
  const InstitutionOperationsScreen({super.key});

  @override
  State<InstitutionOperationsScreen> createState() =>
      _InstitutionOperationsScreenState();
}

class _InstitutionOperationsScreenState extends State<InstitutionOperationsScreen> {
  final _slug = TextEditingController();
  final _schoolQuery = TextEditingController();
  String _schoolSearch = '';
  String? _organization;
  String? _error;
  bool _loading = false;
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _schools = const [];

  @override
  void initState() {
    super.initState();
    _restoreSlug();
  }

  Future<void> _restoreSlug() async {
    final userId = await ApiService.getUserId();
    if (userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString('institution_slug_$userId');
    if (!mounted || previous == null || previous.isEmpty) return;
    _slug.text = previous;
    await _connect();
  }

  @override
  void dispose() {
    _slug.dispose();
    _schoolQuery.dispose();
    super.dispose();
  }

  String _path(String endpoint) =>
      '/institutions/${Uri.encodeComponent(_organization!)}$endpoint';

  Future<Map<String, dynamic>> _get(String endpoint) async {
    final response = await ApiService.authGet(_path(endpoint));
    final data = ApiService.decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? data['message'] ??
          'تعذّر تحميل البيانات (HTTP ${response.statusCode})');
    }
    return data;
  }

  List<Map<String, dynamic>> _items(dynamic data) {
    if (data is! List) return [];
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _connect() async {
    final slug = _slug.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9][a-z0-9-]{1,79}$').hasMatch(slug)) {
      setState(() => _error = 'أدخل معرف المؤسسة الصحيح، مثل demo-institution');
      return;
    }
    setState(() {
      _organization = slug;
      _loading = true;
      _error = null;
      _report = null;
      _schools = const [];
    });
    try {
      final results = await Future.wait([
        _get('/management-report'),
        _get('/schools'),
      ]);
      final userId = await ApiService.getUserId();
      if (userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('institution_slug_$userId', slug);
      }
      if (!mounted) return;
      setState(() {
        _report = results[0];
        _schools = _items(results[1]['schools']);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _organization = null;
        _error = 'لم يُسمح بالوصول لهذه المؤسسة أو تعذّر الاتصال: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createSchool() async {
    final name = TextEditingController();
    final slug = TextEditingController();
    final form = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مدرسة'),
        content: Form(
          key: form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'اسم المدرسة'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null),
            TextFormField(controller: slug, decoration: const InputDecoration(labelText: 'معرف المدرسة بالإنجليزية'),
              validator: (v) => RegExp(r'^[a-z0-9][a-z0-9-]*$').hasMatch(v ?? '')
                  ? null : 'استخدم حروفًا صغيرة وأرقامًا وشرطة فقط'),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () {
            if (form.currentState!.validate()) {
              Navigator.pop(dialogContext, true);
            }
          }, child: const Text('إضافة')),
        ],
      ),
    );
    if (submitted != true || !mounted) {
      name.dispose();
      slug.dispose();
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await ApiService.authPost(_path('/schools'), {
        'name': name.text.trim(), 'slug': slug.text.trim(),
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final data = ApiService.decodeMap(response.body);
        throw Exception(data['error'] ?? data['message'] ?? 'تعذّر إضافة المدرسة');
      }
      final schools = await _get('/schools');
      final report = await _get('/management-report');
      if (mounted) {
        setState(() {
          _schools = _items(schools['schools']);
          _report = report;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      name.dispose();
      slug.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editSchool(Map<String, dynamic> school) async {
    final schoolId = school['id'];
    if (schoolId is! int) return;
    final name = TextEditingController(text: '${school['name'] ?? ''}');
    final address = TextEditingController(text: '${school['address'] ?? ''}');
    final phone = TextEditingController(text: '${school['phone'] ?? ''}');
    final key = GlobalKey<FormState>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تعديل بيانات المدرسة'),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: name,
                maxLength: 150,
                decoration: const InputDecoration(labelText: 'اسم المدرسة'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'اسم المدرسة مطلوب' : null,
              ),
              TextFormField(
                controller: address,
                maxLength: 255,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextFormField(
                controller: phone,
                maxLength: 30,
                decoration: const InputDecoration(labelText: 'الهاتف'),
              ),
            ]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    final changes = {
      'name': name.text.trim(),
      'address': address.text.trim(),
      'phone': phone.text.trim(),
    };
    name.dispose();
    address.dispose();
    phone.dispose();
    if (confirm != true || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiService.authPatch(
        _path('/schools/$schoolId'), changes,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final data = ApiService.decodeMap(response.body);
        throw Exception(data['error'] ?? data['message'] ??
            'تعذر حفظ المدرسة (HTTP ${response.statusCode})');
      }
      final schools = await _get('/schools');
      if (mounted) setState(() => _schools = _items(schools['schools']));
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _schoolDetails(Map<String, dynamic> school) {
    final id = school['id'];
    if (id is! int) return;
    Navigator.push(context, MaterialPageRoute<void>(
      builder: (_) => _InstitutionRecordScreen(
        title: '${school['name'] ?? ''}', path: _path('/schools/$id')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final summary = _report?['summary'];
    final counts = summary is Map ? summary : const {};
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(118),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.appBarGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              child: Row(
                children: [
                  IconButton(
                    tooltip: english ? 'Back to home' : 'العودة إلى الرئيسية',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 27),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(english ? 'School Management' : 'إدارة المدارس',
                      style: TextStyle(color: Colors.white,
                        fontSize: 23, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(english ? 'Institution ID' : 'معرف المؤسسة', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(controller: _slug, enabled: !_loading,
          decoration: InputDecoration(border: const OutlineInputBorder(),
            hintText: english ? 'e.g. demo-institution' : 'مثال: demo-institution')),
        const SizedBox(height: 8),
        FilledButton(onPressed: _loading ? null : _connect,
          child: Text(english ? 'Load institution data' : 'تحميل بيانات المؤسسة')),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_loading) const LinearProgressIndicator(),
        if (_report != null) ...[
          const SizedBox(height: 16),
          Text(english ? 'Live statistics' : 'إحصائيات فعلية', style: Theme.of(context).textTheme.titleLarge),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final metric in {
              (english ? 'Schools' : 'المدارس'): 'schools',
            }.entries)
              Chip(label: Text('${metric.key}: ${counts[metric.value] ?? 0}')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(english ? 'Schools' : 'المدارس', style: Theme.of(context).textTheme.titleLarge)),
            TextButton.icon(onPressed: _loading ? null : _createSchool,
              icon: const Icon(Icons.add), label: Text(english ? 'Add school' : 'إضافة مدرسة')),
          ]),
          TextField(
            controller: _schoolQuery,
            onChanged: (value) => setState(() => _schoolSearch = value.trim().toLowerCase()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: english ? 'Search schools by name' : 'ابحث عن مدرسة بالاسم',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_schoolSearch.isEmpty)
            Text(english ? 'Enter a school name to view its information.' : 'أدخل اسم المدرسة لعرض معلوماتها.')
          else if (_schools.isEmpty)
            Text(english ? 'No schools are linked to this institution.' : 'لا توجد مدارس مرتبطة بالمؤسسة.')
          else if (!_schools.any((school) =>
              '${school['name'] ?? ''}'.toLowerCase().contains(_schoolSearch)))
            Text(english ? 'No matching school found.' : 'لم يتم العثور على مدرسة مطابقة.')
          else
            for (final school in _schools.where((school) =>
                '${school['name'] ?? ''}'.toLowerCase().contains(_schoolSearch)))
              Card(child: ListTile(
                leading: const Icon(Icons.school),
                title: Text('${school['name'] ?? ''}'),
                subtitle: Text(english ? 'View this school information' : 'عرض معلومات هذه المدرسة'),
                onTap: () => _schoolDetails(school),
                trailing: IconButton(
                  tooltip: english ? 'Edit school' : 'تعديل المدرسة',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _loading ? null : () => _editSchool(school),
                ),
              )),
          const SizedBox(height: 16),
          Text('الإدارة والمتابعة', style: Theme.of(context).textTheme.titleLarge),
          const ListTile(
            leading: Icon(Icons.manage_accounts_outlined),
            title: Text('إدارة مدراء المدارس'),
            subtitle: Text('إنشاء حسابات مدراء المدارس يحتاج صلاحية API غير متاحة حاليًا للمؤسسة'),
          ),
        ],
      ]),
    );
  }
}

/// Shows all school fields returned for the authorized institution.
class _InstitutionRecordScreen extends StatefulWidget {
  const _InstitutionRecordScreen({required this.title, required this.path});
  final String title;
  final String path;

  @override
  State<_InstitutionRecordScreen> createState() => _InstitutionRecordScreenState();
}

class _InstitutionRecordScreenState extends State<_InstitutionRecordScreen> {
  late Future<Map<String, dynamic>> _future;

  Future<Map<String, dynamic>> _load() async {
    final response = await ApiService.authGet(widget.path);
    final data = ApiService.decodeMap(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['error'] ?? data['message'] ?? 'تعذّر تحميل بيانات المدرسة');
    }
    return data;
  }

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title),
      actions: [IconButton(icon: const Icon(Icons.refresh),
        onPressed: () => setState(() => _future = _load()))]),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        final school = snapshot.data?['school'];
        if (school is! Map) {
          return const Center(child: Text('لا توجد بيانات للمدرسة'));
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final field in <String, String>{
              'name': 'اسم المدرسة',
              'slug': 'معرف المدرسة',
              'address': 'العنوان',
              'phone': 'الهاتف',
              'email': 'البريد الإلكتروني',
            }.entries)
              if (school[field.key] != null && '${school[field.key]}'.trim().isNotEmpty)
                ListTile(
                  title: Text(Localizations.localeOf(context).languageCode == 'en'
                      ? <String, String>{
                          'name': 'School name', 'slug': 'School ID',
                          'address': 'Address', 'phone': 'Phone',
                          'email': 'Email',
                        }[field.key]! : field.value),
                  subtitle: Text('${school[field.key]}'),
                ),
          ],
        );
      },
    ),
  );
}

