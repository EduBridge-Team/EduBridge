import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_director.dart';
import '../../services/schools/director_api_client.dart';
import '../../services/schools/school_director_appointment_repository.dart';
import '../../theme.dart';
import 'director_failure_message.dart';
import '../school_management/school_director_management_screen.dart';

class SchoolDirectorAppointmentScreen extends StatefulWidget {
  const SchoolDirectorAppointmentScreen({super.key, this.gateway});
  final SchoolDirectorAppointmentGateway? gateway;

  @override
  State<SchoolDirectorAppointmentScreen> createState() =>
      _SchoolDirectorAppointmentScreenState();
}

class _SchoolDirectorAppointmentScreenState
    extends State<SchoolDirectorAppointmentScreen> with WidgetsBindingObserver {
  late final _gateway = widget.gateway ?? SchoolDirectorAppointmentRepository();
  List<DirectorSchool> _schools = const [];
  DirectorSchool? _school;
  PersonalSchoolDirector? _director;
  DirectorFailure? _failure;
  bool _loading = true, _saving = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_saving) _load();
  }

  String _tr(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'ar' ? ar : en;

  Future<void> _load({DirectorSchool? selected}) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failure = null;
      _director = null;
    });
    try {
      final schools = await _gateway.schools();
      final matches = schools.where((s) => s.id == (selected ?? _school)?.id);
      final school = matches.isNotEmpty
          ? matches.single
          : schools.isEmpty
              ? null
              : schools.first;
      final director = school == null ? null : await _gateway.current(school);
      if (!mounted || generation != _generation) return;
      setState(() {
        _schools = schools;
        _school = school;
        _director = director;
      });
    } on DirectorApiException catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _failure = e.failure);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failure = DirectorFailure.server);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: Scaffold(
          appBar: BrandAppBar(
            leading: const BackButton(),
            title: Text(context.l10n.directorTitle),
            actions: [
              IconButton(
                tooltip: context.l10n.directorReload,
                onPressed: _loading || _saving ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_loading || _saving) const LinearProgressIndicator(),
                    Text(
                      _tr(
                        'يجب إنشاء حساب مدير مستقل باستخدام بريد جديد غير مستخدم في EduBridge. أرسل دعوة من شاشة إدارة المديرين.',
                        'A director requires a dedicated account with a new, unused email. Send an invitation from the director management page.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_schools.isNotEmpty)
                      DropdownButtonFormField<int>(
                        key: ValueKey('appointment-school-${_school?.id}'),
                        initialValue: _school?.id,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.directorChooseSchool,
                        ),
                        items: [
                          for (final school in _schools)
                            DropdownMenuItem(
                              value: school.id,
                              child: Text(school.name),
                            ),
                        ],
                        onChanged: _loading || _saving
                            ? null
                            : (id) {
                                if (id != null)
                                  _load(
                                    selected: _schools.singleWhere(
                                      (s) => s.id == id,
                                    ),
                                  );
                              },
                      ),
                    if (_failure != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          directorFailureMessage(context.l10n, _failure!),
                        ),
                      ),
                      TextButton(
                        onPressed: _loading || _saving ? null : _load,
                        child: Text(context.l10n.directorReload),
                      ),
                    ],
                    if (!_loading && _failure == null) ...[
                      const SizedBox(height: 16),
                      if (_school == null)
                        Text(_tr(
                            'لا توجد مدارس متاحة.', 'No schools available.'))
                      else if (_director == null)
                        Text(_tr(
                            'لم يُعيّن مدير بعد.', 'No director appointed.'))
                      else
                        SelectableText(
                            '${_director!.name}\n${_director!.email}'),
                    ],
                    if (_school != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FilledButton(
                          onPressed: _loading ? null : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SchoolDirectorManagementScreen(
                                schoolId: _school!.id,
                                schoolName: _school!.name,
                              ),
                            ),
                          ),
                          child: Text(_tr('إدارة دعوات المدير', 'Manage director invitations')),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
