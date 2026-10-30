import 'package:flutter/material.dart';

import '../../model/schools/academic_catalog.dart';
import '../../services/schools/academic_repository.dart';
import '../../theme.dart';
import '../academics/academic_controller.dart';
import '../enrollment/enrollment_labels.dart';

/// School-account entry to the manual annual promotion workflow.
/// Deliberately read-only until a school-scoped, authorized roster and
/// preview/approve contract supports all three director decisions.
class SchoolAnnualPromotionScreen extends StatefulWidget {
  const SchoolAnnualPromotionScreen({super.key, this.gateway});
  final AcademicGateway? gateway;

  @override
  State<SchoolAnnualPromotionScreen> createState() => _SchoolAnnualPromotionScreenState();
}

class _SchoolAnnualPromotionScreenState extends State<SchoolAnnualPromotionScreen>
    with WidgetsBindingObserver {
  late AcademicController _state;
  int? _sourceYear, _targetYear;

  void _initialize() {
    _sourceYear = null;
    _targetYear = null;
    _state = AcademicController(widget.gateway ?? AcademicRepository())..reload();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didUpdateWidget(covariant SchoolAnnualPromotionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) {
      _state.dispose();
      _initialize();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sourceYear = null;
      _targetYear = null;
      _state.reload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _state,
    builder: (context, _) {
      final english = Localizations.localeOf(context).languageCode == 'en';
      String label(String ar, String en) => english ? en : ar;
      final catalog = _state.snapshot;
      final years = catalog?.years ?? <AcademicYear>[];
      // A resumed/changed catalog must not preserve invalid selections.
      if (!years.any((year) => year.id == _sourceYear)) _sourceYear = null;
      if (!years.any((year) => year.id == _targetYear)) _targetYear = null;
      return Scaffold(
        appBar: BrandAppBar(
          leading: const BackButton(),
          title: Text(label('الترفيع السنوي', 'Annual promotion')),
          actions: [IconButton(
            tooltip: label('تحديث', 'Refresh'),
            onPressed: _state.loading || _state.busy ? null : () {
              setState(() { _sourceYear = null; _targetYear = null; });
              _state.reload();
            },
            icon: const Icon(Icons.refresh),
          )],
        ),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (_state.loading) const LinearProgressIndicator(),
            if (_state.error != null)
              Text(enrollmentFailureMessage(context.l10n, _state.error!)),
            if (catalog != null) ...[
              Text(catalog.school.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(label('مدير المدرسة يحدد السنوات ويُراجع كل طالب قبل الاعتماد.',
                  'The school director selects years and reviews each student before approval.')),
              DropdownButtonFormField<int>(
                key: const ValueKey('promotion-source-year'),
                initialValue: _sourceYear,
                decoration: InputDecoration(labelText: label('السنة الحالية', 'Current year')),
                items: [for (final year in years)
                  DropdownMenuItem(value: year.id, child: Text(year.name))],
                onChanged: (id) => setState(() {
                  _sourceYear = id;
                  _targetYear = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('promotion-target-year-${_sourceYear ?? 0}'),
                initialValue: _targetYear,
                decoration: InputDecoration(labelText: label('السنة الجديدة', 'New year')),
                items: [for (final year in years.where((year) =>
                    _sourceYear != null && year.start.isAfter(
                      years.singleWhere((source) => source.id == _sourceYear).start)))
                  DropdownMenuItem(value: year.id, child: Text(year.name))],
                onChanged: _sourceYear == null ? null : (id) => setState(() => _targetYear = id),
              ),
              const SizedBox(height: 16),
              Text(label('الخطوات التالية: مراجعة الطلاب، تحديد ناجح أو معيد أو منقول، معاينة النتائج، ثم الاعتماد.',
                'Next: review students, select promoted/repeating/transferred, preview, then approve.')),
              const SizedBox(height: 8),
              Text(label('الاعتماد معطّل حتى يوفر الخادم قائمة طلاب المدرسة وصلاحية الاعتماد لجميع الحالات. لن يُنقل أي طالب من هذه الشاشة.',
                'Approval is disabled until the server provides a school-scoped roster and authorization for all decisions. This screen does not move students.')),
              FilledButton(
                key: const ValueKey('promotion-approve'),
                onPressed: null,
                child: Text(label('اعتماد الترفيع', 'Approve promotion')),
              ),
            ],
          ]),
        ))),
      );
    },
  );
}
