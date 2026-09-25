// lib/screens/learning_support_meetings_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../model/learning_support_meeting_model.dart';

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
  String? _error;
  String _filter = 'all';

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
        _error = 'تعذّر تحميل الجلسات';
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
            ? 'اجتماعات ${widget.childName}'
            : 'اجتماعات الدعم التعليمي',
        actions: [
          IconButton(
            icon: const Icon(AppIcons.refresh),
            tooltip: 'تحديث',
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
                  label: 'الكل',
                  count: _sessions.length,
                  selected: _filter == 'all',
                  color: AppColors.brandBlue,
                  onTap: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'مجدولة',
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
                  label: 'منتهية',
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
              onRefresh: _load,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 12),
            Text(_error!,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final sessions = _filtered;
    if (sessions.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      itemBuilder: (context, i) => _SessionCard(session: sessions[i]),
    );
  }

  Widget _buildEmpty() {
    final c = JisrColors.of(context);
    String message;
    switch (_filter) {
      case 'scheduled':
        message = 'لا توجد جلسات مجدولة';
        break;
      case 'completed':
        message = 'لا توجد جلسات منتهية';
        break;
      default:
        message = 'لا توجد جلسات بعد';
    }

    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(AppIcons.event, size: 80, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: c.muted,
            ),
          ),
        ),
        if (_filter == 'all') ...[
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'ستظهر الجلسات هنا عند موافقة المختص على طلبات الدعم التعليمي',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: c.muted, height: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final LearningSupportMeeting session;

  const _SessionCard({required this.session});

  String get _typeLabel {
    switch (session.type) {
      case LearningSupportMeetingType.learningPlanning:
        return 'اجتماع تخطيط تعليمي';
      case LearningSupportMeetingType.followUp:
        return 'متابعة';
      case LearningSupportMeetingType.teamReview:
        return 'مراجعة فريق الدعم';
      case LearningSupportMeetingType.parentReview:
        return 'متابعة مع ولي الأمر';
      case LearningSupportMeetingType.groupSupport:
        return 'دعم تعليمي جماعي';
    }
  }

  IconData get _typeIcon {
    switch (session.type) {
      case LearningSupportMeetingType.learningPlanning:
        return AppIcons.plan;
      case LearningSupportMeetingType.followUp:
        return AppIcons.refresh;
      case LearningSupportMeetingType.teamReview:
        return AppIcons.warning;
      case LearningSupportMeetingType.parentReview:
        return AppIcons.parent;
      case LearningSupportMeetingType.groupSupport:
        return AppIcons.users;
    }
  }

  String get _statusLabel {
    switch (session.status) {
      case LearningSupportMeetingStatus.scheduled:
        return 'مجدولة';
      case LearningSupportMeetingStatus.completed:
        return 'مكتملة';
      case LearningSupportMeetingStatus.cancelled:
        return 'ملغية';
      case LearningSupportMeetingStatus.noShow:
        return 'لم يحضر';
    }
  }

  Color get _statusColor {
    switch (session.status) {
      case LearningSupportMeetingStatus.scheduled:
        return AppColors.orange;
      case LearningSupportMeetingStatus.completed:
        return AppColors.green;
      case LearningSupportMeetingStatus.cancelled:
      case LearningSupportMeetingStatus.noShow:
        return AppColors.red;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year} — $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(_typeIcon, color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      if (session.childName.isNotEmpty)
                        Text(
                          'الطفل: ${session.childName}',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 12),

            _infoRow(AppIcons.calendar, 'الموعد',
                _formatDate(session.scheduledAt), c),
            const SizedBox(height: 6),
            _infoRow(AppIcons.clock, 'المدة',
                '${session.durationMinutes} دقيقة', c),

            if (session.specialistName.isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.specialist, 'المختص',
                  session.specialistName, c),
            ],

            if (session.completedAt != null) ...[
              const SizedBox(height: 6),
              _infoRow(AppIcons.check, 'اكتملت',
                  _formatDate(session.completedAt!), c),
            ],

            if (session.goals != null && session.goals!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _section('الأهداف', session.goals!, c),
            ],

            if (session.notes != null && session.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section('ملاحظات', session.notes!, c),
            ],

            if (session.recommendations != null &&
                session.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _section('التوصيات', session.recommendations!, c),
            ],

            if (session.moodRating != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.sentiment_satisfied,
                      size: 18, color: c.muted),
                  const SizedBox(width: 6),
                  Text(
                    'المشاركة التعليمية: ',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: c.muted,
                    ),
                  ),
                  ...List.generate(5, (i) {
                    return Icon(
                      i < session.moodRating!
                          ? AppIcons.starFilled
                          : AppIcons.star,
                      size: 18,
                      color: AppColors.yellow,
                    );
                  }),
                ],
              ),
            ],

            if (session.tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: session.tags
                    .map((t) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.tintTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$t',
                            style: TextStyle(
                              fontSize: 11,
                              color: c.onTint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, JisrColors c) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.muted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: c.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: c.body,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, String content, JisrColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.tintTeal.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: c.onTint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: c.onTint,
            ),
          ),
        ],
      ),
    );
  }
}