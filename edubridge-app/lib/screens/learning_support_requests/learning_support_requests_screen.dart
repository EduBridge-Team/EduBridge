// lib/screens/learning_support_requests/learning_support_requests_screen.dart
import 'package:flutter/material.dart';
import '../../app_icons.dart';
import '../../model/learning_support_request_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';

part 'learning_support_request_cards.dart';
part 'schedule_learning_support_sheet.dart';

class LearningSupportRequestsScreen extends StatefulWidget {
  const LearningSupportRequestsScreen({super.key});

  @override
  State<LearningSupportRequestsScreen> createState() =>
      _LearningSupportRequestsScreenState();
}

class _LearningSupportRequestsScreenState
    extends State<LearningSupportRequestsScreen> {
  List<LearningSupportRequest> _requests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await ApiService.getLearningSupportRequests();
      if (!mounted) return;
      setState(() {
        _requests = raw
            .map((e) =>
                LearningSupportRequest.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الطلبات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: 'طلبات الدعم التعليمي'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _requests.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(_error!,
              style: const TextStyle(color: AppColors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: const Text('إعادة المحاولة'),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox_outlined, size: 80, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'لا توجد طلبات حالياً',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: c.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final pending = _requests.where((r) => r.isPending).toList();
    final scheduled = _requests.where((r) => r.isScheduled).toList();
    final done = _requests
        .where((r) =>
            r.status == LearningSupportRequestStatus.completed ||
            r.status == LearningSupportRequestStatus.cancelled)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader('قيد المراجعة', pending.length, AppColors.orange),
          ...pending.map((r) => LearningSupportRequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (scheduled.isNotEmpty) ...[
          _sectionHeader('جلسات مجدولة', scheduled.length, AppColors.brandTeal),
          ...scheduled.map((r) => LearningSupportRequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (done.isNotEmpty) ...[
          _sectionHeader('منتهية', done.length, AppColors.green),
          ...done.map((r) =>
              LearningSupportRequestCard(request: r, onTap: null)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openScheduleSheet(LearningSupportRequest request) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScheduleLearningSupportSheet(request: request),
    );
    if (result == true) _load();
  }
}