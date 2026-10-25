import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/curriculum_draft.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../theme.dart';
import '../academics/academic_form_values.dart';
import '../enrollment/enrollment_labels.dart';
import 'curriculum_controller.dart';
import 'curriculum_term_fields.dart';

class CurriculumCreateScreen extends StatefulWidget {
  const CurriculumCreateScreen({
    super.key,
    required this.controller,
    required this.kind,
  });
  final CurriculumController controller;
  final CurriculumKind kind;
  @override
  State<CurriculumCreateScreen> createState() => _CurriculumCreateScreenState();
}

class _CurriculumCreateScreenState extends State<CurriculumCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _code = TextEditingController();
  final _position = TextEditingController(text: '1');
  int? _school, _year;
  DateTime? _start, _end;
  bool _active = true, _attempted = false;
  bool get _canWrite =>
      widget.controller.canWrite &&
      widget.controller.snapshot?.school.id == _school;
  @override
  void initState() {
    super.initState();
    _school = widget.controller.snapshot?.school.id;
    widget.controller.addListener(_syncCatalog);
  }

  void _syncCatalog() {
    final data = widget.controller.snapshot;
    if (data == null) return;
    _school ??= data.school.id;
    final years = data.years.where((year) => year.id == _year);
    if (years.isEmpty) {
      _year = null;
      _start = _end = null;
    } else if ((_start != null && _start!.isBefore(years.single.start)) ||
        (_end != null && _end!.isAfter(years.single.end))) {
      _start = _end = null;
    }
  }

  @override
  void didUpdateWidget(covariant CurriculumCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCatalog);
      widget.controller.addListener(_syncCatalog);
      _syncCatalog();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncCatalog);
    _name.dispose();
    _code.dispose();
    _position.dispose();
    super.dispose();
  }

  void _selectYear(int value) {
    if (!_canWrite ||
        !widget.controller.snapshot!.years.any((year) => year.id == value))
      return;
    setState(() {
      _year = value;
      _start = _end = null;
    });
  }

  Future<void> _date(bool start) async {
    final years = widget.controller.snapshot?.years.where(
      (year) => year.id == _year,
    );
    if (!_canWrite || years == null || years.isEmpty) return;
    final year = years.single;
    final date = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? year.start,
      firstDate: year.start,
      lastDate: year.end,
    );
    if (mounted && _canWrite && _year == year.id && date != null) {
      setState(() {
        if (start) {
          _start = date;
        } else {
          _end = date;
        }
      });
    }
  }

  CurriculumDraft get _draft => CurriculumDraft(
    kind: widget.kind,
    name: _name.text,
    code: _code.text,
    active: _active,
    yearId: _year,
    position: parseAcademicInteger(_position.text),
    start: _start,
    end: _end,
  );
  Future<void> _save() async {
    if (!_canWrite) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate() ||
        !_draft.validFor(widget.controller.snapshot!))
      return;
    FocusScope.of(context).unfocus();
    final saved = await widget.controller.create(_draft);
    if (mounted && saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final l10n = context.l10n;
      final controller = widget.controller;
      final data = controller.snapshot;
      final term = widget.kind == CurriculumKind.term;
      final schoolChanged = data != null && data.school.id != _school;
      return PopScope(
        canPop: !controller.busy,
        child: Scaffold(
          appBar: BrandAppBar(
            leading: BackButton(
              onPressed: () {
                if (!controller.busy) Navigator.of(context).maybePop();
              },
            ),
            title: Text(
              term ? l10n.curriculumAddTerm : l10n.curriculumAddSubject,
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          key: const ValueKey('curriculum-name'),
                          controller: _name,
                          enabled: _canWrite,
                          maxLength: term ? 60 : 120,
                          decoration: InputDecoration(
                            labelText: l10n.academicName,
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? l10n.academicRequired
                              : null,
                        ),
                        if (term && data != null)
                          CurriculumTermFields(
                            years: data.years,
                            yearId: _year,
                            position: _position,
                            start: _start,
                            end: _end,
                            onYear: _canWrite ? _selectYear : null,
                            onDate: _canWrite ? _date : null,
                          ),
                        if (!term) ...[
                          TextFormField(
                            key: const ValueKey('curriculum-code'),
                            controller: _code,
                            enabled: _canWrite,
                            maxLength: 40,
                            decoration: InputDecoration(
                              labelText: l10n.curriculumCode,
                            ),
                          ),
                          CheckboxListTile(
                            key: const ValueKey('curriculum-active'),
                            contentPadding: EdgeInsets.zero,
                            value: _active,
                            title: Text(l10n.curriculumActive),
                            onChanged: _canWrite
                                ? (value) => setState(() => _active = value!)
                                : null,
                          ),
                        ],
                        if (_attempted &&
                            term &&
                            data != null &&
                            !_draft.validFor(data))
                          Semantics(
                            liveRegion: true,
                            child: Text(l10n.curriculumTermInvalid),
                          ),
                        if (schoolChanged)
                          Text(
                            enrollmentFailureMessage(
                              l10n,
                              EnrollmentFailure.forbidden,
                            ),
                          ),
                        if (_attempted && controller.error != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              enrollmentFailureMessage(l10n, controller.error!),
                            ),
                          ),
                        if (controller.busy) const LinearProgressIndicator(),
                        if (_attempted &&
                            !controller.canWrite &&
                            !controller.busy)
                          TextButton(
                            onPressed: controller.reload,
                            child: Text(l10n.enrollmentReload),
                          ),
                        FilledButton(
                          key: const ValueKey('curriculum-save'),
                          onPressed: _canWrite ? _save : null,
                          child: Text(l10n.academicSave),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
