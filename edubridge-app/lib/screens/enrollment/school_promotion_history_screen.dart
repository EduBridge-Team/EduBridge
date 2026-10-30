import 'package:flutter/material.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_promotion_operation_repository.dart';
import '../../theme.dart';

/// Read-only, school-scoped historical receipts, never creates enrollments.
class SchoolPromotionHistoryScreen extends StatefulWidget {
  const SchoolPromotionHistoryScreen({super.key, required this.schoolId,
    required this.yearId, this.gateway});
  final int schoolId, yearId;
  final SchoolPromotionOperationGateway? gateway;

  @override
  State<SchoolPromotionHistoryScreen> createState() => _SchoolPromotionHistoryScreenState();
}

class _SchoolPromotionHistoryScreenState extends State<SchoolPromotionHistoryScreen>\n    with WidgetsBindingObserver {
  List<SchoolPromotionReceipt>? _operations;
  EnrollmentFailure? _failure;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(covariant SchoolPromotionHistoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schoolId != widget.schoolId || oldWidget.yearId != widget.yearId ||
        oldWidget.gateway != widget.gateway) _load();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() { _operations = null; _failure = null; });
    try {
      final operations = await (widget.gateway ?? SchoolPromotionOperationRepository())
        .history(yearId: widget.yearId, schoolId: widget.schoolId);
      if (!mounted || request != _request) return;
      setState(() => _operations = operations);
    } on EnrollmentApiException catch (error) {
      if (!mounted || request != _request) return;
      setState(() => _failure = error.failure);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() => _failure = EnrollmentFailure.network);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_request;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String tr(String ar, String english) => en ? english : ar;
    return Scaffold(
      appBar: BrandAppBar(leading: const BackButton(),
        title: Text(tr('سجل الترفيع السنوي', 'Annual promotion history')),
        actions: [IconButton(tooltip: tr('تحديث', 'Refresh'),
          onPressed: _operations == null && _failure == null ? null : _load,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_operations == null && _failure == null)
            const LinearProgressIndicator(),
          if (_failure != null) ...[
            Text(switch (_failure!) {
              EnrollmentFailure.unavailable => tr('خدمة سجل الترفيع غير متاحة من الخادم بعد.',
                'Promotion history API is not available yet.'),
              EnrollmentFailure.session => tr('انتهت جلسة المدرسة. سجل الدخول مجددًا.',
                'School session expired. Please sign in again.'),
              EnrollmentFailure.forbidden => tr('غير مصرح لك بالاطلاع على هذا السجل.',
                'You do not have permission to view this history.'),
              EnrollmentFailure.invalidResponse => tr('استجابة السجل ناقصة أو لا تخص السنة والمدرسة المحددتين.',
                'History response is incomplete or does not match this school and year.'),
              _ => tr('تعذر التحقق من السجل. أعد المحاولة.',
                'Unable to verify promotion history. Retry.'),
            }),
            TextButton.icon(key: const ValueKey('promotion-history-retry'),
              onPressed: _load, icon: const Icon(Icons.refresh),
              label: Text(tr('إعادة المحاولة', 'Retry'))),
          ],
          if (_operations?.isEmpty == true)
            Text(tr('لا يوجد سجل ترفيع لهذه السنة.', 'No promotion history for this year.')),
          for (final receipt in _operations ?? <SchoolPromotionReceipt>[])
            Card(child: ListTile(
              title: Text('${tr('عملية', 'Operation')}: ${receipt.operationId}'),
              subtitle: Text(
                '${tr('الحالة', 'Status')}: ${switch (receipt.status) {
                  'completed' => tr('مكتملة', 'Completed'),
                  'pending' => tr('قيد التنفيذ', 'Pending'),
                  _ => tr('فشلت', 'Failed'),
                }}\n'
                '${tr('ناجح', 'Promoted')}: ${receipt.promoted} • '
                '${tr('معيد', 'Repeating')}: ${receipt.repeating} • '
                '${tr('منقول', 'Transferred')}: ${receipt.transferred}'),
              trailing: Icon(receipt.completed ? Icons.verified_outlined :
                Icons.info_outline),
            )),
        ]),
      ))),
    );
  }
}
