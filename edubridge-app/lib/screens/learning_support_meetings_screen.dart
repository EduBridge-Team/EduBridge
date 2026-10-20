// lib/screens/learning_support_meetings_screen.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../utils/learning_support_presentation.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../model/learning_support_meeting_model.dart';

part 'learning_support_meetings_widgets.dart';
part 'learning_support_session_card.dart';

class LearningSupportMeetingsScreen extends StatefulWidget {
  final int? childId;
  final String? childName;

  const LearningSupportMeetingsScreen({
    super.key,
    this.childId,
    this.childName,
  });

  @override
  State<LearningSupportMeetingsScreen> createState() =>
      _LearningSupportMeetingsScreenState();
}

class _LearningSupportMeetingsScreenState
    extends State<LearningSupportMeetingsScreen> {
  List<LearningSupportMeeting> _sessions = [];
  bool _loading = true;
  LearningSupportError? _error;
  String _filter = 'all';

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
      final list = await ApiService.getLearningSupportMeetings(
          childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _sessions = list
            .map((e) =>
                LearningSupportMeeting.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = LearningSupportError.meetingsLoad;
        _loading = false;
      });
    }
  }

  List<LearningSupportMeeting> get _filtered {
    switch (_filter) {
      case 'scheduled':
        return _sessions
            .where((s) => s.status == LearningSupportMeetingStatus.scheduled)
            .toList();
      case 'completed':
        return _sessions
            .where((s) => s.status == LearningSupportMeetingStatus.completed)
            .toList();
      default:
        return _sessions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(
        title: widget.childName != null
            ? context.l10n.supportChildMeetings(widget.childName!)
            : context.l10n.supportMeetingsTitle,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: context.l10n.caseRefreshAction,
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: JisrColors.of(context).card,
            child: Row(
              children: [
                _FilterChip(
                  label: context.l10n.all,
                  count: _sessions.length,
                  selected: _filter == 'all',
                  color: AppColors.brandBlue,
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: context.l10n.supportScheduled,
                  count: _sessions
                      .where((s) =>
                          s.status == LearningSupportMeetingStatus.scheduled)
                      .length,
                  selected: _filter == 'scheduled',
                  color: AppColors.orange,
                  onTap: () => setState(() => _filter = 'scheduled'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: context.l10n.supportFinished,
                  count: _sessions
                      .where((s) =>
                          s.status == LearningSupportMeetingStatus.completed)
                      .length,
                  selected: _filter == 'completed',
                  color: AppColors.green,
                  onTap: () => setState(() => _filter = 'completed'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }
}
