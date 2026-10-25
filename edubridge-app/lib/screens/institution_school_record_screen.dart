import 'package:flutter/material.dart';

import '../services/institution_school_repository.dart';
import '../theme.dart';

/// Shows all school fields returned for the authorized institution.
class InstitutionSchoolRecordScreen extends StatefulWidget {
  const InstitutionSchoolRecordScreen({
    super.key,
    required this.title,
    required this.organizationSlug,
    required this.schoolId,
  });
  final String title;
  final String organizationSlug;
  final int schoolId;

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
      title: Text(widget.title),
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
