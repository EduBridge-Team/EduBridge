import 'package:flutter/material.dart';

import '../services/institution_school_repository.dart';
import 'institutions/institution_school_form_dialog.dart';
import '../theme.dart';
import 'institution_school_record_screen.dart';

/// Institution-scoped operations. The API validates active organization
/// membership for every request; a slug never grants access by itself.
class InstitutionOperationsScreen extends StatefulWidget {
  const InstitutionOperationsScreen({super.key});

  @override
  State<InstitutionOperationsScreen> createState() =>
      _InstitutionOperationsScreenState();
}

class _InstitutionOperationsScreenState
    extends State<InstitutionOperationsScreen> {
  final _repository = InstitutionSchoolRepository();
  final _schoolQuery = TextEditingController();
  String _schoolSearch = '';
  String? _organization;
  String? _error;
  bool _loading = false;
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _schools = const [];

  bool _connected = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_connected) {
      _connected = true;
      _connect();
    }
  }

  @override
  void dispose() {
    _schoolQuery.dispose();
    super.dispose();
  }

  String englishLabel(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  Future<void> _connect() async {
    setState(() {
      _organization = null;
      _loading = true;
      _error = null;
      _report = null;
      _schools = const [];
    });
    try {
      final slug = await _repository.resolveOrganization(
        failureMessage: englishLabel(
          'تعذّر تحديد المؤسسة المرتبطة بالحساب',
          'Could not resolve the institution for this account',
        ),
      );
      if (!mounted) return;
      _organization = slug;
      final results = await Future.wait([
        _repository.loadReport(slug),
        _repository.loadSchools(slug),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as Map<String, dynamic>;
        _schools = results[1] as List<Map<String, dynamic>>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _organization = null;
        _error = englishLabel(
          'لم يُسمح بالوصول لهذه المؤسسة أو تعذّر الاتصال: $error',
          'Access was denied or the institution could not be loaded: $error',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createSchool() async {
    final fields = await InstitutionSchoolFormDialog.show(context);
    if (fields == null || !mounted) return;
    final slug = _organization!;
    setState(() => _loading = true);
    try {
      await _repository.createSchool(slug, fields);
      final schools = await _repository.loadSchools(slug);
      final report = await _repository.loadReport(slug);
      if (mounted) {
        setState(() {
          _schools = schools;
          _report = report;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editSchool(Map<String, dynamic> school) async {
    final schoolId = school['id'];
    if (schoolId is! int) return;
    final fields = await InstitutionSchoolFormDialog.show(
      context,
      school: school,
    );
    if (fields == null || !mounted) return;
    final slug = _organization!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repository.updateSchool(slug, schoolId, fields);
      final schools = await _repository.loadSchools(slug);
      if (mounted) setState(() => _schools = schools);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _schoolDetails(Map<String, dynamic> school) {
    final id = school['id'];
    if (id is! int) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InstitutionSchoolRecordScreen(
          title: '${school['name'] ?? ''}',
          organizationSlug: _organization!,
          schoolId: id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(english ? 'School Management' : 'إدارة المدارس'),
        actions: [
          IconButton(
            tooltip:
                english ? 'Refresh institution data' : 'تحديث بيانات المؤسسة',
            onPressed: _loading ? null : _connect,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
          if (_report != null) ...[
            TextField(
              controller: _schoolQuery,
              onChanged: (value) =>
                  setState(() => _schoolSearch = value.trim().toLowerCase()),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText:
                    english ? 'Search schools by name' : 'ابحث عن مدرسة بالاسم',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: _loading ? null : _createSchool,
                icon: const Icon(Icons.add),
                label: Text(english ? 'Add school' : 'إضافة مدرسة'),
              ),
            ),
            if (_schools.isEmpty)
              Text(
                english
                    ? 'No schools are linked to this institution.'
                    : 'لا توجد مدارس مرتبطة بالمؤسسة.',
              )
            else if (!_schools.any(
              (school) => '${school['name'] ?? ''}'.toLowerCase().contains(
                    _schoolSearch,
                  ),
            ))
              Text(
                english
                    ? 'No matching school found.'
                    : 'لم يتم العثور على مدرسة مطابقة.',
              )
            else
              for (final school in _schools.where(
                (school) => '${school['name'] ?? ''}'.toLowerCase().contains(
                      _schoolSearch,
                    ),
              ))
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.school),
                    title: Text('${school['name'] ?? ''}'),
                    subtitle: Text(
                      english
                          ? 'View this school information'
                          : 'عرض معلومات هذه المدرسة',
                    ),
                    onTap: () => _schoolDetails(school),
                    trailing: IconButton(
                      tooltip: english ? 'Edit school' : 'تعديل المدرسة',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: _loading ? null : () => _editSchool(school),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
