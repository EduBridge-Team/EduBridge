import 'dart:math';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/transfers/school_transfer.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/transfers/school_transfer_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolTransfersScreen extends StatefulWidget {
  const SchoolTransfersScreen({super.key, required this.gateway});
  final SchoolTransferGateway gateway;
  @override
  State<SchoolTransfersScreen> createState() => _SchoolTransfersScreenState();
}

class _SchoolTransfersScreenState extends State<SchoolTransfersScreen>
    with WidgetsBindingObserver {
  final _reason = TextEditingController();
  final _form = GlobalKey<FormState>();
  SchoolTransferDirectory? _data;
  int? _enrollment, _destination;
  final _sections = <int, int>{};
  bool _busy = false, _confirming = false;
  final _created = <int>{};
  final _blocked = <int>{};
  EnrollmentFailure? _failure;
  String? _message;
  int _generation = 0;
  String t(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant SchoolTransfersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) {
      _generation++;
      _data = null;
      _message = null;
      _failure = null;
      _enrollment = null;
      _destination = null;
      _sections.clear();
      _reason.clear();
      _blocked.clear();
      _created.clear();
      _busy = false;
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_busy && !_confirming) _load();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_busy) return;
    final generation = ++_generation;
    final gateway = widget.gateway;
    setState(() {
      _busy = true;
      _data = null;
      _failure = null;
      _enrollment = null;
      _destination = null;
      _sections.clear();
    });
    try {
      final data = await gateway.load();
      if (mounted && generation == _generation) setState(() => _data = data);
    } on EnrollmentApiException catch (e) {
      if (mounted && generation == _generation)
        setState(() => _failure = e.failure);
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _failure = EnrollmentFailure.invalidResponse);
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _write(
      {IncomingSchoolTransfer? request, bool accept = false}) async {
    if (_busy ||
        _confirming ||
        _data == null ||
        (request == null
            ? _created.contains(_enrollment)
            : _blocked.contains(request.id))) return;
    if (request == null && !(_form.currentState?.validate() ?? false)) return;
    final section = request == null ? null : _sections[request.id];
    if (accept && section == null) return;
    final enrollment = _enrollment,
        destination = _destination,
        reason = _reason.text.trim();
    final generation = _generation, gateway = widget.gateway;
    setState(() => _confirming = true);
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              scrollable: true,
              title: Text(request == null
                  ? t('تأكيد طلب النقل', 'Confirm transfer request')
                  : accept
                      ? t('قبول النقل والقيد', 'Accept transfer and enroll')
                      : t('رفض النقل', 'Reject transfer')),
              content: Text(request == null
                  ? t('يتطلب الطلب موافقة ولي الأمر ثم قبول المدرسة المستقبلة. يبقى القيد الحالي نشطًا حتى اكتمال النقل.',
                      'The guardian and destination school must approve. The current enrollment stays active until completion.')
                  : t('طالب #${request.childId} — طلب #${request.id}. سيتم تسجيل قرار المدرسة.',
                      'Student #${request.childId} — request #${request.id}. The school decision will be recorded.')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: Text(t('إلغاء', 'Cancel'))),
                FilledButton(
                    key: const ValueKey('transfer-confirm'),
                    onPressed: () => Navigator.pop(dialog, true),
                    child: Text(t('تأكيد', 'Confirm')))
              ],
            ));
    if (!mounted) return;
    setState(() => _confirming = false);
    if (confirmed != true ||
        generation != _generation ||
        gateway != widget.gateway) return;
    setState(() {
      _busy = true;
      _failure = null;
      _message = null;
    });
    try {
      if (request == null) {
        final id = await gateway.create(enrollment!, destination!, reason);
        if (!mounted || generation != _generation) return;
        _created.add(enrollment);
        _reason.clear();
        _message = t(
            'تم إنشاء الطلب #$id بانتظار موافقة ولي الأمر. لم يكتمل النقل بعد.',
            'Request #$id created; awaiting guardian consent. Transfer is not complete.');
      } else {
        final random = Random.secure();
        final key = List.generate(16,
                (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
            .join();
        await gateway.decide(request,
            accept: accept, section: section, key: key);
        if (!mounted || generation != _generation) return;
        _blocked.add(request.id);
        _message = accept
            ? t('اكتمل النقل والقيد لدى المدرسة.',
                'Transfer and destination enrollment completed.')
            : t('تم رفض طلب النقل.', 'Transfer request rejected.');
      }
    } on EnrollmentApiException catch (e) {
      if (!mounted || generation != _generation) return;
      _failure = e.failure;
      if (e.failure == EnrollmentFailure.uncertain) {
        if (request == null) {
          _created.add(enrollment!);
        } else {
          _blocked.add(request.id);
        }
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _failure = EnrollmentFailure.uncertain;
      if (request == null) {
        _created.add(enrollment!);
      } else {
        _blocked.add(request.id);
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
    if (mounted && generation == _generation && _failure == null) await _load();
  }

  Widget _choice(String key, String label, List<TransferChoice> rows,
          int? value, ValueChanged<int> changed) =>
      KeyedSubtree(
          key: ValueKey(key),
          child: AcademicChoiceField(
              label: label,
              options: {for (final row in rows) row.id: row.label},
              value: value,
              requiredMessage: t('اختر قيمة صالحة', 'Choose a valid option'),
              onChanged: _busy || _confirming ? null : changed));
  @override
  Widget build(BuildContext context) {
    final data = _data, disabled = _busy || _confirming;
    return PopScope(
        canPop: !disabled,
        child: Scaffold(
          appBar: BrandAppBar(
              leading: const BackButton(),
              title: Text(t('النقل بين المدارس', 'School transfers')),
              actions: [
                IconButton(
                    onPressed: disabled ? null : _load,
                    tooltip: t('تحديث', 'Refresh'),
                    icon: const Icon(Icons.refresh))
              ]),
          body: SafeArea(
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            if (_busy) const LinearProgressIndicator(),
                            if (_failure != null)
                              Text(enrollmentFailureMessage(
                                  context.l10n, _failure!)),
                            if (_message != null)
                              Semantics(
                                  liveRegion: true, child: Text(_message!)),
                            if (_created.isNotEmpty || _blocked.isNotEmpty)
                              Text(t(
                                  'لا تكرر الطلب المحفوظ أو غير المؤكد. راجع حالة النقل لدى ولي الأمر والمدرسة قبل إنشاء طلب جديد.',
                                  'Do not repeat a saved or uncertain request. Check its status with the guardian and school before creating another.')),
                            if (data != null) ...[
                              Text(
                                  t('طلب نقل طالب', 'Request student transfer'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              if (data.enrollments.isEmpty ||
                                  data.schools.isEmpty)
                                Text(t(
                                    'لا تتوفر تسجيلات نشطة أو مدارس مستقبلة.',
                                    'No active enrollments or destination schools are available.')),
                              Form(
                                  key: _form,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _choice(
                                            'transfer-enrollment',
                                            t('الطالب والقيد',
                                                'Student enrollment'),
                                            data.enrollments
                                                .where((row) =>
                                                    !_created.contains(row.id))
                                                .toList(),
                                            _enrollment,
                                            (id) => setState(
                                                () => _enrollment = id)),
                                        _choice(
                                            'transfer-destination',
                                            t('المدرسة المستقبلة',
                                                'Destination school'),
                                            data.schools,
                                            _destination,
                                            (id) => setState(
                                                () => _destination = id)),
                                        TextFormField(
                                            controller: _reason,
                                            enabled: !disabled,
                                            maxLength: 500,
                                            maxLines: null,
                                            decoration: InputDecoration(
                                                labelText: t('السبب (اختياري)',
                                                    'Reason (optional)'))),
                                        FilledButton(
                                            key: const ValueKey(
                                                'transfer-create'),
                                            onPressed: disabled ||
                                                    data.enrollments.isEmpty ||
                                                    data.schools.isEmpty
                                                ? null
                                                : () => _write(),
                                            child: Text(t('مراجعة طلب النقل',
                                                'Review transfer request'))),
                                      ])),
                              const Divider(),
                              Text(
                                  t('طلبات واردة بعد موافقة ولي الأمر',
                                      'Incoming requests with guardian consent'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(t(
                                  'تعرض الخدمة حتى 100 طلب وارد. حدّث القائمة بعد معالجة الطلبات.',
                                  'The service returns up to 100 incoming requests. Refresh after processing.')),
                              if (data.incoming.isEmpty)
                                Text(t('لا توجد طلبات واردة.',
                                    'No incoming requests.')),
                              for (final row in data.incoming)
                                Card(
                                    child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(t(
                                                  'طلب #${row.id} — طالب #${row.childId} — مدرسة المصدر #${row.sourceSchoolId}',
                                                  'Request #${row.id} — student #${row.childId} — source school #${row.sourceSchoolId}')),
                                              if (!_blocked
                                                  .contains(row.id)) ...[
                                                _choice(
                                                    'transfer-section-${row.id}',
                                                    t('شعبة القيد الجديدة',
                                                        'Destination section'),
                                                    data.sections,
                                                    _sections[row.id],
                                                    (id) => setState(() =>
                                                        _sections[row.id] =
                                                            id)),
                                                FilledButton(
                                                    key: ValueKey(
                                                        'transfer-accept-${row.id}'),
                                                    onPressed: disabled ||
                                                            _sections[row.id] ==
                                                                null
                                                        ? null
                                                        : () => _write(
                                                            request: row,
                                                            accept: true),
                                                    child: Text(t('قبول وقيد',
                                                        'Accept and enroll'))),
                                                OutlinedButton(
                                                    key: ValueKey(
                                                        'transfer-reject-${row.id}'),
                                                    onPressed: disabled
                                                        ? null
                                                        : () => _write(
                                                            request: row),
                                                    child: Text(
                                                        t('رفض', 'Reject'))),
                                              ],
                                            ]))),
                            ],
                          ])))),
        ));
  }
}
