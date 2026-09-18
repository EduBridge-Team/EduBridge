// screens/therapy/therapy_sessions_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../model/therapy_model.dart';

class TherapySessionsScreen extends StatefulWidget {
  final int? childId;

  const TherapySessionsScreen({super.key, this.childId});

  @override
  State<TherapySessionsScreen> createState() => _TherapySessionsScreenState();
}

class _TherapySessionsScreenState extends State<TherapySessionsScreen> {
  List<TherapySession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.getTherapySessions(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _sessions = list
            .map((e) => TherapySession.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSession() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateSessionSheet(childId: widget.childId),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: '🧠 جلسات العلاج النفسي'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        icon: const Icon(Icons.add),
        label: const Text('جلسة جديدة'),
        backgroundColor: AppColors.teal,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? const Center(child: Text('لا توجد جلسات'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sessions.length,
                  itemBuilder: (context, i) =>
                      _SessionCard(session: _sessions[i]),
                ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TherapySession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    Color statusColor;
    switch (session.status) {
      case TherapySessionStatus.completed:
        statusColor = AppColors.green;
        break;
      case TherapySessionStatus.cancelled:
      case TherapySessionStatus.noShow:
        statusColor = AppColors.red;
        break;
      default:
        statusColor = AppColors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  session.type.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    session.status.name,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${session.scheduledAt.day}/${session.scheduledAt.month}/${session.scheduledAt.year} '
              '- ${session.durationMinutes} دقيقة',
            ),
            if (session.notes != null) ...[
              const SizedBox(height: 6),
              Text('ملاحظات: ${session.notes}'),
            ],
            if (session.recommendations != null) ...[
              const SizedBox(height: 6),
              Text(
                'توصيات: ${session.recommendations}',
                style: TextStyle(color: c.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateSessionSheet extends StatefulWidget {
  final int? childId;

  const _CreateSessionSheet({this.childId});

  @override
  State<_CreateSessionSheet> createState() => _CreateSessionSheetState();
}

class _CreateSessionSheetState extends State<_CreateSessionSheet> {
  TherapySessionType _type = TherapySessionType.followUp;
  DateTime _scheduled = DateTime.now().add(const Duration(days: 1));
  int _duration = 45;
  final _goalsCtrl = TextEditingController();
  final _childIdCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _goalsCtrl.dispose();
    _childIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final childId =
        widget.childId ?? int.tryParse(_childIdCtrl.text.trim()) ?? 0;
    if (childId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الطفل مطلوب')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiService.createTherapySession(
        childId: childId,
        type: _type.name,
        scheduledAt: _scheduled,
        durationMinutes: _duration,
        goals:
            _goalsCtrl.text.trim().isEmpty ? null : _goalsCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🧠 جلسة علاج نفسي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.childId == null)
              TextField(
                controller: _childIdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم الطفل',
                  prefixIcon: Icon(Icons.child_care),
                ),
              ),
            // ✅ إصلاح: initialValue بدل value
            DropdownButtonFormField<TherapySessionType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'نوع الجلسة'),
              items: TherapySessionType.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goalsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'أهداف الجلسة',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '...' : 'حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}