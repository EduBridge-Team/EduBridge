import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/schools/academic_catalog.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'academic_controller.dart';
import 'academic_choice_field.dart';
import 'academic_form_values.dart';
import '../../services/enrollment/enrollment_api_client.dart';

String academicTitle(BuildContext context, AcademicKind kind) => switch (kind) {
  AcademicKind.year => context.l10n.academicAddYear,
  AcademicKind.grade => context.l10n.academicAddGrade,
  AcademicKind.section => context.l10n.academicAddSection,
};

class AcademicCreateScreen extends StatefulWidget {
  const AcademicCreateScreen({
    super.key,
    required this.controller,
    required this.kind,
  });
  final AcademicController controller;
  final AcademicKind kind;
  @override
  State<AcademicCreateScreen> createState() => _AcademicCreateScreenState();
}

class _AcademicCreateScreenState extends State<AcademicCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _capacity = TextEditingController(text: '30');
  DateTime? _start, _end;
  int? _year, _grade, _schoolId;
  bool _current = false, _attempted = false;

  @override
  void initState() {
    super.initState();
    _schoolId = widget.controller.snapshot?.school.id;
    widget.controller.addListener(_syncCatalog);
  }

  @override
  void didUpdateWidget(covariant AcademicCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncCatalog);
      widget.controller.addListener(_syncCatalog);
      _syncCatalog();
    }
  }

  // Runs before AnimatedBuilder reads the updated catalog.
  void _syncCatalog() {
    final data = widget.controller.snapshot;
    if (data == null) return;
    _schoolId ??= data.school.id;
    if (!data.years.any((item) => item.id == _year)) _year = null;
    if (!data.grades.any((item) => item.id == _grade)) _grade = null;
  }

  bool get _canWrite =>
      widget.controller.canWrite &&
      widget.controller.snapshot?.school.id == _schoolId;

  void _selectYear(int value) {
    if (_canWrite &&
        widget.controller.snapshot!.years.any((item) => item.id == value)) {
      setState(() => _year = value);
    }
  }

  void _selectGrade(int value) {
    if (_canWrite &&
        widget.controller.snapshot!.grades.any((item) => item.id == value)) {
      setState(() => _grade = value);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncCatalog);
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _chooseDate(bool start) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (mounted && date != null) {
      setState(() {
        if (start) {
          _start = date;
        } else {
          _end = date;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_canWrite) return;
    setState(() => _attempted = true);
    if (!_form.currentState!.validate()) return;
    final draft = AcademicDraft(
      kind: widget.kind,
      name: _name.text,
      start: _start,
      end: _end,
      current: _current,
      yearId: _year,
      gradeId: _grade,
      capacity: parseAcademicCapacity(_capacity.text),
    );
    if (!draft.valid) return;
    FocusScope.of(context).unfocus();
    final saved = await widget.controller.create(draft);
    if (mounted && saved) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final l10n = context.l10n;
      final controller = widget.controller;
      final data = controller.snapshot;
      final year = widget.kind == AcademicKind.year;
      final schoolChanged = data != null && data.school.id != _schoolId;
      return PopScope(
        canPop: !controller.busy,
        child: Scaffold(
          appBar: BrandAppBar(
            leading: BackButton(
              onPressed: () {
                if (!controller.busy) Navigator.of(context).maybePop();
              },
            ),
            title: Text(academicTitle(context, widget.kind)),
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
                          key: const ValueKey('academic-name'),
                          controller: _name,
                          enabled: _canWrite,
                          maxLength: year ? 40 : 80,
                          decoration: InputDecoration(
                            labelText: l10n.academicName,
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.academicRequired
                              : null,
                        ),
                        if (year) ...[
                          OutlinedButton(
                            key: const ValueKey('academic-start'),
                            onPressed: !_canWrite
                                ? null
                                : () => _chooseDate(true),
                            child: Text(
                              '${l10n.academicStart}: ${_start == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(_start!)}',
                            ),
                          ),
                          OutlinedButton(
                            key: const ValueKey('academic-end'),
                            onPressed: !_canWrite
                                ? null
                                : () => _chooseDate(false),
                            child: Text(
                              '${l10n.academicEnd}: ${_end == null ? '—' : MaterialLocalizations.of(context).formatMediumDate(_end!)}',
                            ),
                          ),
                          if (_attempted &&
                              (_start == null ||
                                  _end == null ||
                                  !_end!.isAfter(_start!)))
                            Text(l10n.academicDateInvalid),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _current,
                            onChanged: !_canWrite
                                ? null
                                : (value) => setState(() => _current = value!),
                            title: Text(l10n.academicCurrent),
                            subtitle: Text(l10n.academicCurrentNotice),
                          ),
                        ],
                        if (widget.kind == AcademicKind.section &&
                            data != null) ...[
                          AcademicChoiceField(
                            key: const ValueKey('academic-year'),
                            label: l10n.academicYears,
                            options: {
                              for (final item in data.years) item.id: item.name,
                            },
                            value: _year,
                            requiredMessage: l10n.academicRequired,
                            onChanged: _canWrite ? _selectYear : null,
                          ),
                          AcademicChoiceField(
                            key: const ValueKey('academic-grade'),
                            label: l10n.academicGrades,
                            options: {
                              for (final item in data.grades)
                                item.id: item.name,
                            },
                            value: _grade,
                            requiredMessage: l10n.academicRequired,
                            onChanged: _canWrite ? _selectGrade : null,
                          ),
                          TextFormField(
                            key: const ValueKey('academic-capacity'),
                            controller: _capacity,
                            enabled: _canWrite,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.academicCapacity,
                            ),
                            validator: (v) {
                              final n = parseAcademicCapacity(v ?? '');
                              return n == null || n < 1 || n > 500
                                  ? l10n.academicCapacityInvalid
                                  : null;
                            },
                          ),
                        ],
                        if (schoolChanged)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              enrollmentFailureMessage(
                                l10n,
                                EnrollmentFailure.forbidden,
                              ),
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
                        const SizedBox(height: 16),
                        FilledButton(
                          key: const ValueKey('academic-save'),
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
