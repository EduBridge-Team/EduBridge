// screens/child/care_team_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../model/care_team_model.dart';

class CareTeamScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const CareTeamScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<CareTeamScreen> createState() => _CareTeamScreenState();
}

class _CareTeamScreenState extends State<CareTeamScreen> {
  CareTeam? _team;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getCareTeam(widget.childId);
      if (data != null) {
        _team = CareTeam.fromJson(data);
      }
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: '👥 فريق ${widget.childName}'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _team == null
                ? const Center(child: Text('لا يوجد فريق'))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final t = _team!;
    final c = JisrColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.headerGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              const Icon(Icons.groups, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text(
                '${t.members.length} أعضاء في الفريق',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${t.teacherCount} معلم • ${t.specialists.length} مختص',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (t.specialists.isNotEmpty) ...[
          const Text(
            '🧠 المختصون',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...t.specialists.map((s) => _memberCard(s, c)),
          const SizedBox(height: 16),
        ],
        if (t.teachers.isNotEmpty) ...[
          const Text(
            '👨‍🏫 المعلمون',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...t.teachers.map((t) => _memberCard(t, c)),
        ],
      ],
    );
  }

  Widget _memberCard(CareTeamMember m, JisrColors c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              m.role == 'teacher' ? AppColors.green : AppColors.pink,
          child: Text(
            m.name.isNotEmpty ? m.name.characters.first : '؟',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          m.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          m.role == 'teacher'
              ? 'معلم${m.subject != null ? ' — ${m.subject}' : ''}'
              : 'مختص${m.specialty != null ? ' — ${m.specialty!.label}' : ''}',
        ),
        trailing: m.specialty != null
            ? Text(m.specialty!.emoji, style: const TextStyle(fontSize: 24))
            : null,
      ),
    );
  }
}