import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/school_director.dart';
import '../../services/schools/director_api_client.dart';
import '../../services/schools/school_director_appointment_repository.dart';
import '../../theme.dart';
import 'director_failure_message.dart';

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
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  List<DirectorSchool> _schools = const [];
  DirectorSchool? _school;
  PersonalSchoolDirector? _director;
  DirectorFailure? _failure;
  bool _loading = true, _saving = false, _saved = false, _needsReload = false;
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
    _email.dispose();
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
      _saved = false;
      _director = null;
      _email.clear();
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
        _needsReload = false;
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

  Future<void> _appoint() async {
    final school = _school;
    if (_saving ||
        _loading ||
        _needsReload ||
        school == null ||
        !(_form.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(_tr('تعيين مدير المدرسة', 'Appoint school director')),
        content: Text(
          _tr(
            'سيصبح $email مديرًا لمدرسة ${school.name} وتنتهي صلاحية المدير الحالي إن وُجد.',
            '$email will direct ${school.name}. Any current director appointment will end.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_tr('إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_tr('تأكيد التعيين', 'Confirm appointment')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _saving = true;
      _saved = false;
      _failure = null;
    });
    try {
      final id = await _gateway.appoint(school, email);
      // Read the authoritative account instead of constructing one locally.
      final director = await _gateway.current(school);
      if (director == null ||
          director.id != id ||
          director.email.toLowerCase() != email.toLowerCase()) {
        throw const DirectorApiException(DirectorFailure.uncertain);
      }
      if (!mounted) return;
      setState(() {
        _director = director;
        _saved = true;
        _email.clear();
      });
    } on DirectorApiException catch (e) {
      if (mounted)
        setState(() {
          _failure = e.failure;
          _needsReload = true;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _failure = DirectorFailure.uncertain;
          _needsReload = true;
        });
    } finally {
      if (mounted) setState(() => _saving = false);
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
                        'المدير يستخدم حسابه الشخصي ببريد موثّق. أدخل بريد حساب موجود لتعيينه أو استبدال المدير الحالي.',
                        'The director uses a verified personal account. Enter an existing account email to appoint or replace the current director.',
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
                    if (_saved)
                      Semantics(
                        liveRegion: true,
                        child: Text(context.l10n.directorSaved),
                      ),
                    if (_school != null)
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _email,
                              enabled: !_loading &&
                                  !_saving &&
                                  !_needsReload &&
                                  _failure == null,
                              keyboardType: TextInputType.emailAddress,
                              textDirection: TextDirection.ltr,
                              decoration: InputDecoration(
                                labelText: _tr(
                                  'البريد الشخصي للمدير',
                                  'Director personal email',
                                ),
                              ),
                              validator: (value) =>
                                  RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch((value ?? '').trim())
                                      ? null
                                      : _tr(
                                          'أدخل بريدًا إلكترونيًا صالحًا.',
                                          'Enter a valid email address.',
                                        ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _loading ||
                                      _saving ||
                                      _needsReload ||
                                      _failure != null
                                  ? null
                                  : _appoint,
                              child:
                                  Text(_tr('تعيين المدير', 'Appoint director')),
                            ),
                          ],
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
