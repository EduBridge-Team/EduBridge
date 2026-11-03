import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/schools/independent_specialist_employment_repository.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolSpecialistEmploymentScreen extends StatelessWidget {
  const SchoolSpecialistEmploymentScreen({super.key, required this.schoolId, this.gateway});
  final int schoolId;
  final IndependentSpecialistEmploymentGateway? gateway;
  @override
  Widget build(BuildContext context) =>
      _EmploymentBoard(schoolId: schoolId, gateway: gateway);
}

class SpecialistEmploymentOffersScreen extends StatelessWidget {
  const SpecialistEmploymentOffersScreen({super.key, this.gateway});
  final IndependentSpecialistEmploymentGateway? gateway;
  @override
  Widget build(BuildContext context) => _EmploymentBoard(gateway: gateway);
}

/// Null schoolId means the signed-in specialist reviews their own offers.
/// A schoolId means the active independent-school director manages employment.
class _EmploymentBoard extends StatefulWidget {
  const _EmploymentBoard({this.schoolId, this.gateway});
  final int? schoolId;
  final IndependentSpecialistEmploymentGateway? gateway;
  @override
  State<_EmploymentBoard> createState() => _EmploymentBoardState();
}

class _EmploymentBoardState extends State<_EmploymentBoard> with WidgetsBindingObserver {
  late IndependentSpecialistEmploymentGateway _gateway;
  List<IndependentSpecialistEmployment>? _records;
  EnrollmentFailure? _error;
  bool _loading = false, _busy = false;
  int _version = 0;
  bool get isDirector => widget.schoolId != null;

  String _t(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  @override
  void initState() {
    super.initState();
    _gateway = widget.gateway ?? IndependentSpecialistEmploymentRepository();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }
  @override
  void didUpdateWidget(covariant _EmploymentBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolId != widget.schoolId || oldWidget.gateway != widget.gateway) {
      _gateway = widget.gateway ?? IndependentSpecialistEmploymentRepository();
      _load();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }
  @override
  void dispose() {
    ++_version;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_version;
    setState(() { _loading = true; _records = null; _error = null; });
    try {
      final rows = isDirector
          ? await _gateway.directorRoster(widget.schoolId!)
          : await _gateway.myOffers();
      if (mounted && version == _version) setState(() => _records = rows);
    } on EnrollmentApiException catch (e) {
      if (mounted && version == _version) setState(() => _error = e.failure);
    } catch (_) {
      if (mounted && version == _version) setState(() => _error = EnrollmentFailure.network);
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  Future<bool> _confirm(String title, String description) async =>
      await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: Text(title), content: Text(description),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
            child: Text(_t('إلغاء', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
            child: Text(_t('تأكيد', 'Confirm'))),
        ],
      )) == true;

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) await _load();
    } on EnrollmentApiException catch (e) {
      if (mounted) setState(() { _records = null; _error = e.failure; });
    } catch (_) {
      if (mounted) setState(() { _records = null; _error = EnrollmentFailure.network; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: Text(_t('دعوة مختص للعمل في المدرسة', 'Offer specialist employment')),
      content: TextField(
        key: const ValueKey('specialist-employment-email'),
        controller: controller, keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(labelText: _t('البريد الإلكتروني للمختص', 'Specialist email')),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog),
          child: Text(_t('إلغاء', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(dialog, controller.text.trim()),
          child: Text(_t('إرسال العرض', 'Send offer'))),
      ],
    ));
    // Do not retain the entered address after the dialog closes.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (email != null && email.isNotEmpty && mounted) {
      await _mutate(() => _gateway.invite(widget.schoolId!, email));
    }
  }

  Future<void> _end(IndependentSpecialistEmployment record) async {
    final yes = await _confirm(
      _t('إنهاء الارتباط الوظيفي', 'End employment'),
      _t('سيُلغى التكليف النشط مع حفظ السجلات السابقة. هل تريد المتابعة؟',
        'Active school assignments will end, while prior records are preserved. Continue?'),
    );
    if (yes && mounted) {
      await _mutate(() => _gateway.end(widget.schoolId!, record.id));
    }
  }

  Future<void> _accept(IndependentSpecialistEmployment record) async {
    final yes = await _confirm(
      _t('قبول الانضمام للمدرسة', 'Accept school employment'),
      record.schoolName,
    );
    if (yes && mounted) await _mutate(() => _gateway.accept(record.id));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: BrandAppBar(
      leading: const BackButton(),
      title: Text(isDirector
          ? _t('موظفو المدرسة المختصون', 'School specialist employees')
          : _t('طلبات الانضمام للمدارس', 'School employment offers')),
      actions: [
        IconButton(
          tooltip: context.l10n.enrollmentReload,
          onPressed: _loading || _busy ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 840),
      child: RefreshIndicator(onRefresh: _load, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(isDirector
              ? _t('أرسل عرض عمل إلى حساب مختص موثّق. بعد قبوله يمكن تكليفه بالمدرسة.',
                  'Invite a verified specialist. Assignment becomes possible only after acceptance.')
              : _t('اقبل عرض العمل أولًا ليتمكن مدير المدرسة من تكليفك.',
                  'Accept the offer before the school director can assign you.')),
          const SizedBox(height: 12),
          if (isDirector)
            FilledButton.icon(
              key: const ValueKey('specialist-employment-invite'),
              onPressed: _loading || _busy ? null : _invite,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(_t('إضافة مختص إلى الكادر', 'Offer employment')),
            ),
          if (_loading || _busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(enrollmentFailureMessage(context.l10n, _error!)),
          if (_records?.isEmpty == true)
            Text(_t('لا توجد عروض أو علاقات وظيفية حاليًا.', 'No current employment offers.')),
          if (_records != null)
            for (final record in _records!) Card(
              key: ValueKey('specialist-employment-${record.id}'),
              child: ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: Text(isDirector ? record.specialistName : record.schoolName),
                subtitle: Text(isDirector ? record.email : (record.accepted
                  ? _t('تم القبول', 'Accepted')
                  : _t('بانتظار قبولك', 'Pending acceptance'))),
                trailing: _busy || record.ended
                  ? null
                  : isDirector
                    ? TextButton(
                      key: ValueKey('specialist-employment-end-${record.id}'),
                      onPressed: () => _end(record),
                      child: Text(_t('إنهاء', 'End')),
                    )
                    : record.accepted
                      ? const Icon(Icons.check_circle_outline)
                      : FilledButton(
                        key: ValueKey('specialist-employment-accept-${record.id}'),
                        onPressed: () => _accept(record),
                        child: Text(_t('قبول', 'Accept')),
                      ),
              ),
            ),
        ],
      )),
    ))),
  );
}
