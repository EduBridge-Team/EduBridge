import 'school_management/school_director_management_screen.dart';
import 'package:flutter/material.dart';

import '../services/institution_school_repository.dart';
import '../theme.dart';
import '../l10n/l10n.dart';
import '../services/institution_academic_repository.dart';
import 'institution_academics/institution_academic_screen.dart';

/// Shows all school fields returned for the authorized institution.
class InstitutionSchoolRecordScreen extends StatefulWidget {
  const InstitutionSchoolRecordScreen({
    super.key,
    required this.title,
    required this.organizationSlug,
    required this.schoolId,
    this.academicGateway,
  });
  final String title;
  final String organizationSlug;
  final int schoolId;
  final InstitutionAcademicGateway? academicGateway;

  @override
  State<InstitutionSchoolRecordScreen> createState() =>
      _InstitutionSchoolRecordScreenState();
}

class _InstitutionSchoolRecordScreenState
    extends State<InstitutionSchoolRecordScreen> {
  late Future<Map<String, dynamic>> _future;

  Future<Map<String, dynamic>> _load() => InstitutionSchoolRepository()
      .loadSchool(widget.organizationSlug, widget.schoolId);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(
      leading: const BackButton(),
      title: Text(widget.title, softWrap: true, overflow: TextOverflow.visible),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => setState(() => _future = _load()),
        ),
      ],
    ),
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
            OutlinedButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SchoolDirectorManagementScreen(schoolId: widget.schoolId, schoolName: widget.title))), icon: const Icon(Icons.manage_accounts_outlined), label: Text(Localizations.localeOf(context).languageCode == 'en' ? 'Director and invitations' : 'المدير والدعوات')),
            OutlinedButton.icon(
              key: const ValueKey('institution-open-academic'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => InstitutionAcademicScreen(
                    organizationSlug: widget.organizationSlug,
                    schoolId: widget.schoolId,
                    gateway: widget.academicGateway,
                  ),
                ),
              ),
              icon: const Icon(Icons.school_outlined),
              label: Text(context.l10n.institutionAcademicTitle),
            ),
            for (final field in <String, String>{
              'name': 'اسم المدرسة',
              'slug': 'معرف المدرسة',
              'address': 'العنوان',
              'phone': 'الهاتف',
              'email': 'البريد الإلكتروني',
            }.entries)
              if (school[field.key] != null &&
                  '${school[field.key]}'.trim().isNotEmpty)
                ListTile(
                  title: Text(
                    Localizations.localeOf(context).languageCode == 'en'
                        ? <String, String>{
                            'name': 'School name',
                            'slug': 'School ID',
                            'address': 'Address',
                            'phone': 'Phone',
                            'email': 'Email',
                          }[field.key]!
                        : field.value,
                  ),
                  subtitle: Text('${school[field.key]}'),
                ),
          ],
        );
      },
    ),
  );
}
