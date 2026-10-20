// lib/screens/learning_support_requests/learning_support_requests_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../utils/learning_support_presentation.dart';
import '../../app_icons.dart';
import '../../model/learning_support_request_model.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../specialist/specialist_screen.dart';
import '../case_discussion/case_discussion_screen.dart';
import '../chats_screen.dart';

part 'learning_support_request_cards.dart';
part 'schedule_learning_support_sheet.dart';
part 'schedule_learning_support_sheet_view.dart';
part 'learning_support_requests_s17.dart';

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
  late final Future<String?> _viewerRole = ApiService.getRole();
  LearningSupportError? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else if (_error != null) {
      setState(() => _error = null);
    }
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
        _error = LearningSupportError.requestsLoad;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _viewerRole,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == 'specialist') {
          return _buildSpecialistS17(context);
        }
        return _buildDefaultScreen();
      },
    );
  }

  Widget _buildDefaultScreen() {
    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.supportRequestsTitle),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
          Text(LearningSupportPresentation.error(_error!, context.l10n),
              style: const TextStyle(color: AppColors.red, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(AppIcons.refresh),
            label: Text(context.l10n.retryAction),
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
            context.l10n.supportRequestsEmpty,
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
          _sectionHeader(context.l10n.underReview, pending.length, AppColors.brandBlueLight),
          ...pending.map((r) => LearningSupportRequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (scheduled.isNotEmpty) ...[
          _sectionHeader(context.l10n.supportScheduledSessions, scheduled.length, AppColors.brandTeal),
          ...scheduled.map((r) => LearningSupportRequestCard(
                request: r,
                onTap: () => _openScheduleSheet(r),
              )),
          const SizedBox(height: 16),
        ],
        if (done.isNotEmpty) ...[
          _sectionHeader(context.l10n.supportFinished, done.length, AppColors.brandGreen),
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
          Expanded(child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          )),
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
    if (result == true && mounted) _load();
  }
}
